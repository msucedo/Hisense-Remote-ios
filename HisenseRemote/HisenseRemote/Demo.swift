// Modo demo para sacar las capturas del App Preview en el simulador, sin tele.
// Solo existe en DEBUG: la versión que se sube a la App Store no lo trae.
//
//   xcrun simctl launch booted com.mariosaucedo.HisenseRemote -demoScreen remote -demoVolume 18 -demoFull
//
// Argumentos: -demoScreen scanning|pairing|remote, -demoVolume N, -demoPin 4821, -demoFull.
// Lo usa tools/capture-preview.sh.

#if DEBUG
import Foundation

extension RemoteViewModel {
    // Devuelve true si arrancó en modo demo (entonces no hay que llamar a start()).
    func startDemo(store: Store) -> Bool {
        let args = UserDefaults.standard   // los "-clave valor" de arranque llegan aquí
        guard let screen = args.string(forKey: "demoScreen") else { return false }

        sources = ["TV", "HDMI 1", "HDMI 2", "HDMI 3", "AV"]
            .map { SourceItem(sourceId: $0, name: $0) }
        apps = ["YouTube", "Netflix", "Prime Video", "Disney+", "Spotify", "Max"]
            .map { AppItem(name: $0, raw: [:]) }
        volume = args.object(forKey: "demoVolume") == nil ? 18 : args.integer(forKey: "demoVolume")
        store.isFull = args.bool(forKey: "demoFull")

        switch screen {
        case "pairing":
            self.screen = .pairing
            status = "Escribe el PIN que aparece en la TV"
            pin = args.string(forKey: "demoPin") ?? ""
        case "remote":
            self.screen = .remote
            status = "Conectada"
        default:
            self.screen = .scanning
            busy = true
            status = "Buscando tu TV…"
        }
        return true
    }
}
#endif
