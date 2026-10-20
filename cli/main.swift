// CLI de Mac para probar HisenseKit contra la TV real (Fase A).
//
// Uso:
//   hisensectl scan
//   hisensectl pair <ip>
//   hisensectl cmd  <ip> key <up|ok|volup|...>
//   hisensectl cmd  <ip> volume <0-100>
//   hisensectl cmd  <ip> app <nombre>
//
// El certificado de cliente se lee de secrets/client.p12.

import Foundation
import RemoteKit

let P12_PATH = "secrets/client.p12"
let P12_PASS = "186e990688070325a1c4b0ce275d2388"
let STATE_URL = URL(fileURLWithPath: "cli.token.json")

func loadP12() -> Data {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: P12_PATH)) else {
        FileHandle.standardError.write("No pude leer \(P12_PATH)\n".data(using: .utf8)!)
        exit(1)
    }
    return data
}

let args = Array(CommandLine.arguments.dropFirst())
guard let cmd = args.first else {
    print("uso: scan | pair <ip> | cmd <ip> <key|volume|app> <valor>")
    exit(1)
}

switch cmd {
case "scan":
    print("Escaneando la red...")
    Discovery.scan { ips in
        if ips.isEmpty { print("No encontré ninguna TV.") }
        else { for ip in ips { print("TV VIDAA → \(ip)") } }
        exit(0)
    }
    RunLoop.main.run()

case "ping":
    guard args.count >= 2 else { print("uso: ping <ip>"); exit(1) }
    let tv = HisenseTV(host: args[1], stateURL: STATE_URL)
    tv.onError = { print("FALLO: \($0)"); exit(1) }
    tv.onReady = { print("CONNACK 0 ✓ (TLS + autorización OK)"); tv.end(); exit(0) }
    tv.connect(p12: loadP12(), p12Password: P12_PASS)
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { print("TIMEOUT (sin respuesta)"); exit(1) }
    RunLoop.main.run()

case "pair":
    guard args.count >= 2 else { print("uso: pair <ip>"); exit(1) }
    let tv = HisenseTV(host: args[1], stateURL: STATE_URL)
    tv.onError = { print("Error: \($0)"); exit(1) }
    tv.onAuthBusy = { print("Ocupado: cierra la app RemoteNOW/VIDAA."); exit(1) }
    tv.onPaired = { data in
        let days = (data["accesstoken_duration_day"] as? Int).map(String.init) ?? "?"
        print("\n¡Emparejado! Token guardado (válido ~\(days) días).")
        exit(0)
    }
    var asked = false
    func askPin() {
        if asked { return }; asked = true
        print("Escribe el PIN que ves en la TV: ", terminator: "")
        if let line = readLine()?.trimmingCharacters(in: .whitespaces), let pin = Int(line) {
            tv.sendPin(pin)
        } else { print("PIN inválido."); exit(1) }
    }
    tv.onAuthNeeded = { print("La TV está mostrando un PIN."); DispatchQueue.global().async { askPin() } }
    tv.onAuthResult = { r in
        if (r["result"] as? Int) == 1 { print("PIN aceptado. Pidiendo token..."); tv.requestToken() }
        else { print("PIN rechazado: \(r)"); exit(1) }
    }
    tv.onReady = { print("Conectado. Pidiendo código..."); tv.requestPairing() }
    tv.connect(p12: loadP12(), p12Password: P12_PASS)
    RunLoop.main.run()

case "cmd":
    guard args.count >= 3 else { print("uso: cmd <ip> <key|volume|app> <valor>"); exit(1) }
    let tv = HisenseTV(host: args[1], stateURL: STATE_URL)
    let action = args[2]
    let value = args.count >= 4 ? args[3] : ""
    tv.onError = { print("Error: \($0)"); exit(1) }
    tv.onVolume = { print("volumen: \($0)") }
    tv.onApps = { apps in
        // Lanzar por nombre con los datos reales de la TV.
        if let hit = apps.first(where: { (($0["name"] as? String) ?? "").lowercased().contains(value.lowercased()) }) {
            var clean = hit; clean["httpIcon"] = nil
            if let d = try? JSONSerialization.data(withJSONObject: clean),
               let s = String(data: d, encoding: .utf8) {
                tv.launch(s); print("Lanzando \(hit["name"] ?? "")...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { exit(0) }
            }
        } else { print("No encontré la app \"\(value)\""); exit(1) }
    }
    tv.onReady = {
        switch action {
        case "key": tv.key(Keys.map[value] ?? value)
        case "volume": tv.setVolume(Int(value) ?? 0)
        case "getvolume": tv.getVolume()
        case "app": tv.apps(); return                     // espera onApps
        default: print("acción desconocida"); exit(1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { exit(0) }
    }
    tv.connect(p12: loadP12(), p12Password: P12_PASS)
    RunLoop.main.run()

default:
    print("comando desconocido: \(cmd)")
    exit(1)
}
