// Modelo de vista: envuelve HisenseTV (del paquete RemoteKit) y publica el
// estado para la interfaz SwiftUI. Los callbacks de HisenseTV llegan desde hilos
// de red, así que todo lo que toca la UI se salta al hilo principal.

import Foundation
import SwiftUI
import RemoteKit

@MainActor
final class RemoteViewModel: ObservableObject {
    enum Screen { case scanning, pickTV, pairing, remote }

    @Published var screen: Screen = .scanning
    @Published var tvs: [String] = []
    @Published var status = "Buscando tu TV…"
    @Published var volume: Int?
    @Published var apps: [AppItem] = []
    @Published var sources: [SourceItem] = []
    @Published var pin = ""

    struct AppItem: Identifiable { let id = UUID(); let name: String; let raw: [String: Any] }
    struct SourceItem: Identifiable { let id = UUID(); let sourceId: String; let name: String }

    private var tv: HisenseTV?
    private let p12Password = "186e990688070325a1c4b0ce275d2388"

    private var p12: Data {
        guard let url = Bundle.main.url(forResource: "client", withExtension: "p12"),
              let data = try? Data(contentsOf: url) else { return Data() }
        return data
    }
    private var stateURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tv.json")
    }

    // MARK: - Flujo
    func scan() {
        screen = .scanning
        status = "Buscando tu TV…"
        Discovery.scan { [weak self] ips in
            Task { @MainActor in
                guard let self = self else { return }
                self.tvs = ips
                if ips.count == 1 { self.connect(ips[0]) }          // una sola: conecta directo
                else if ips.isEmpty { self.status = "No encontré ninguna TV. ¿Está encendida?" }
                else { self.screen = .pickTV; self.status = "Elige tu TV" }
            }
        }
    }

    func connect(_ ip: String) {
        status = "Conectando a \(ip)…"
        let tv = HisenseTV(host: ip, stateURL: stateURL)
        self.tv = tv

        tv.onError = { [weak self] msg in Task { @MainActor in self?.status = "Error: \(msg)" } }
        tv.onReady = { [weak self] in Task { @MainActor in self?.onConnected() } }
        tv.onAuthNeeded = { [weak self] in Task { @MainActor in self?.screen = .pairing
            self?.status = "Escribe el PIN que aparece en la TV" } }
        tv.onAuthBusy = { [weak self] in Task { @MainActor in
            self?.status = "La TV está ocupada: cierra la app RemoteNOW en tu celular" } }
        tv.onAuthResult = { [weak self] r in Task { @MainActor in
            if (r["result"] as? Int) == 1 { self?.status = "PIN aceptado"; self?.tv?.requestToken() }
            else { self?.status = "PIN incorrecto o expirado, intenta de nuevo"; self?.pin = "" } } }
        tv.onPaired = { [weak self] _ in Task { @MainActor in self?.onConnected() } }
        tv.onVolume = { [weak self] v in Task { @MainActor in self?.volume = Self.readVolume(v) } }
        tv.onApps = { [weak self] list in Task { @MainActor in
            self?.apps = list.compactMap { d in (d["name"] as? String).map { AppItem(name: $0, raw: d) } } } }
        tv.onSources = { [weak self] list in Task { @MainActor in
            self?.sources = list.compactMap { d in
                guard let id = d["sourceid"] as? String else { return nil }
                let name = (d["displayname"] as? String) ?? (d["sourcename"] as? String) ?? id
                return SourceItem(sourceId: id, name: name) } } }

        tv.connect(p12: p12, p12Password: p12Password)
    }

    private func onConnected() {
        if tv?.isPaired == true {
            screen = .remote
            status = "Conectada"
            refresh()
        } else {
            tv?.requestPairing()   // dispara el PIN en la TV (onAuthNeeded)
        }
    }

    func submitPin() {
        guard let n = Int(pin.trimmingCharacters(in: .whitespaces)) else { return }
        tv?.sendPin(n)
        status = "Validando PIN…"
    }

    func refresh() { tv?.getVolume(); tv?.apps(); tv?.sources() }

    // MARK: - Comandos
    func key(_ k: String) { tv?.key(Keys.map[k] ?? k) }
    func volUp() { tv?.key(Keys.map["volup"]!) }
    func volDown() { tv?.key(Keys.map["voldown"]!) }
    func launch(_ app: AppItem) {
        var clean = app.raw; clean["httpIcon"] = nil
        if let d = try? JSONSerialization.data(withJSONObject: clean),
           let s = String(data: d, encoding: .utf8) { tv?.launch(s) }
    }
    func setSource(_ s: SourceItem) { tv?.setSource(s.sourceId) }

    private static func readVolume(_ v: Any) -> Int? {
        if let n = v as? Int { return n }
        if let d = v as? [String: Any] { return (d["volume_value"] as? Int) ?? (d["volume"] as? Int) }
        return nil
    }
}
