// Capa de alto nivel sobre MQTTClient. Port de hisense-remote/tv.js.
//
// Traduce comandos ("sube el volumen", "abre YouTube") a mensajes MQTT y, al
// revés, clasifica lo que publica la TV en eventos para la interfaz.

import Foundation

// Estado persistente (MAC estable + token tras emparejar).
public struct TVState: Codable {
    public var mac: String
    public var accessToken: String?
    public var refreshToken: String?
}

public final class HisenseTV {
    public let host: String
    public let port: UInt16
    private let stateURL: URL
    public private(set) var state: TVState
    private let client = MQTTClient()
    public private(set) var clientId = ""
    public var isPaired: Bool { (state.accessToken?.isEmpty == false) }

    // Eventos
    public var onReady: (() -> Void)?
    public var onError: ((String) -> Void)?
    public var onAuthNeeded: (() -> Void)?
    public var onAuthResult: (([String: Any]) -> Void)?
    public var onAuthBusy: (() -> Void)?
    public var onPaired: (([String: Any]) -> Void)?
    public var onVolume: ((Any) -> Void)?
    public var onSources: (([[String: Any]]) -> Void)?
    public var onApps: (([[String: Any]]) -> Void)?
    public var onState: ((Any) -> Void)?
    public var onMessage: ((String, String) -> Void)?

    public init(host: String, port: UInt16 = 36669, stateURL: URL) {
        self.host = host
        self.port = port
        self.stateURL = stateURL
        if let data = try? Data(contentsOf: stateURL),
           let s = try? JSONDecoder().decode(TVState.self, from: data) {
            state = s
        } else {
            // MAC inventada pero estable (iOS no da la MAC real del WiFi).
            let mac = (0..<6).map { _ in String(format: "%02X", Int.random(in: 0...255)) }.joined(separator: ":")
            state = TVState(mac: mac, accessToken: nil, refreshToken: nil)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: stateURL) }
    }

    // Bases de topics para el clientId actual.
    private var ui: String { "/remoteapp/tv/ui_service/\(clientId)" }
    private var platform: String { "/remoteapp/tv/platform_service/\(clientId)" }
    private var remote: String { "/remoteapp/tv/remote_service/\(clientId)" }
    private var mobile: String { "/remoteapp/mobile/\(clientId)" }

    public func connect(p12: Data, p12Password: String) {
        let creds = VidaaCrypto.initialCredentials(mac: state.mac)
        clientId = creds.clientId
        let password = state.accessToken ?? creds.password

        client.onConnack = { [weak self] code in
            guard let self = self else { return }
            if code != 0 { self.onError?("CONNACK \(code) (no autorizado)"); return }
            self.subscribeExactTopics()
            self.onReady?()
        }
        client.onMessage = { [weak self] topic, payload in self?.handle(topic, payload) }
        client.onClose = { [weak self] in self?.onError?("conexión cerrada") }

        client.connect(host: host, port: port, p12: p12, p12Password: p12Password,
                       clientId: creds.clientId, username: creds.username, password: password)
    }

    // El comodín '#' está DENEGADO por este firmware: topics exactos.
    private func subscribeExactTopics() {
        let b = "/remoteapp/mobile/broadcast"
        client.subscribe([
            "\(mobile)/ui_service/data/authentication",
            "\(mobile)/ui_service/data/authenticationcode",
            "\(mobile)/ui_service/data/authenticationcodeclose",
            "\(mobile)/ui_service/data/authenticationcodetoast",
            "\(mobile)/ui_service/data/gettvstate",
            "\(mobile)/ui_service/data/state",
            "\(mobile)/ui_service/data/sourcelist",
            "\(mobile)/ui_service/data/applist",
            "\(mobile)/platform_service/data/tokenissuance",
            "\(mobile)/platform_service/data/getvolume",
            "\(b)/ui_service/state",
            "\(b)/ui_service/volume",
            "\(b)/platform_service/actions/volumechange",
        ])
    }

    private func handle(_ topic: String, _ payload: String) {
        let fn = topic.split(separator: "/").last.map(String.init) ?? ""
        onMessage?(topic, payload)
        let json = parseJSON(payload)
        switch fn {
        case "authentication": onAuthNeeded?()
        case "authenticationcode": onAuthResult?(json as? [String: Any] ?? [:])
        case "authenticationcodetoast": onAuthBusy?()
        case "tokenissuance": handleToken(json as? [String: Any] ?? [:])
        case "getvolume", "volumechange", "volume": onVolume?(json ?? payload)
        case "sourcelist": onSources?(json as? [[String: Any]] ?? [])
        case "applist": onApps?(json as? [[String: Any]] ?? [])
        case "state", "gettvstate": onState?(json ?? payload)
        default: break
        }
    }

    private func handleToken(_ data: [String: Any]) {
        state.accessToken = (data["accesstoken"] as? String) ?? ""
        state.refreshToken = (data["refreshtoken"] as? String) ?? ""
        save()
        onPaired?(data)
    }

    // MARK: - Acciones
    private func act(_ base: String, _ action: String, _ payload: String = "") {
        client.publish("\(base)/actions/\(action)", payload)
    }
    private func dataCall(_ base: String, _ fn: String, _ payload: String = "") {
        client.publish("\(base)/data/\(fn)", payload)
    }

    public func requestPairing() {
        act(ui, "vidaa_app_connect", "{\"app_version\":2,\"connect_result\":0,\"device_type\":\"Mobile App\"}")
        act(ui, "gettvstate")
    }
    public func sendPin(_ pin: Int) { act(ui, "authenticationcode", "{\"authNum\":\(pin)}") }
    public func requestToken() {
        dataCall(platform, "gettoken", "{\"refreshtoken\":\"\"}")
        act(ui, "authenticationcodeclose")
    }

    public func key(_ name: String) { act(remote, "sendkey", name) }
    public func setVolume(_ n: Int) { act(platform, "changevolume", String(max(0, min(100, n)))) }
    public func getVolume() { act(platform, "getvolume") }
    public func getState() { act(ui, "gettvstate") }
    public func sources() { act(ui, "sourcelist") }
    public func setSource(_ id: String) { act(ui, "changesource", "{\"sourceid\":\"\(id)\"}") }
    public func apps() { act(ui, "applist") }
    public func launch(_ appJSON: String) { act(ui, "launchapp", appJSON) }

    public func end() { client.end() }

    private func parseJSON(_ s: String) -> Any? {
        guard let d = s.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: d)
    }
}

// Teclas usadas por la interfaz.
public enum Keys {
    public static let map = [
        "power": "KEY_POWER", "home": "KEY_HOME", "back": "KEY_RETURNS", "exit": "KEY_EXIT",
        "up": "KEY_UP", "down": "KEY_DOWN", "left": "KEY_LEFT", "right": "KEY_RIGHT", "ok": "KEY_OK",
        "volup": "KEY_VOLUMEUP", "voldown": "KEY_VOLUMEDOWN", "mute": "KEY_MUTE",
        "menu": "KEY_MENU", "source": "KEY_SOURCES", "info": "KEY_INFO",
    ]
}
