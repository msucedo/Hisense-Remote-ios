// Credenciales del firmware VIDAA moderno (2024+).
//
// Port de hisense-remote/crypto.js. El firmware nuevo no acepta un usuario/clave
// fijos: la app los calcula en cada conexión a partir de la hora y la MAC, con
// unos "salts" y una máscara incrustados en la app (constantes públicas que la
// comunidad reconstruyó). Aquí lo portamos a Swift.

import Foundation
import CryptoKit

enum VidaaCrypto {
    static let modernSalt = "h!i@s#$v%i^d&a*a"
    static let clientIdPattern = "38D65DC30F45109A369A86FCE866A85B"
    // Máscara de 64 bits para el XOR de la hora (UInt64, no Int: el valor cabe).
    static let xorTimestampMask: UInt64 = 6_239_759_785_777_146_216

    static func md5Upper(_ s: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(s.utf8))
        return digest.map { String(format: "%02X", $0) }.joined()
    }

    // Normaliza la MAC a "aa:bb:cc:dd:ee:ff" conservando mayúsculas/minúsculas
    // (el hash es sensible a eso). Sin MAC válida, inventa una aleatoria.
    static func cleanMac(_ mac: String?) -> String {
        if let mac = mac {
            let s = mac.replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ".", with: "")
                .trimmingCharacters(in: .whitespaces)
            if s.count == 12 {
                return stride(from: 0, to: 12, by: 2).map { i in
                    let start = s.index(s.startIndex, offsetBy: i)
                    let end = s.index(start, offsetBy: 2)
                    return String(s[start..<end])
                }.joined(separator: ":")
            }
        }
        return (0..<6).map { _ in String(format: "%02X", Int.random(in: 0...255)) }.joined(separator: ":")
    }

    struct Credentials {
        let clientId: String
        let username: String
        let password: String
    }

    // Perfil "modern". timestamp en segundos (por defecto, ahora).
    static func initialCredentials(mac: String?, timestamp: Int? = nil) -> Credentials {
        let ts = timestamp ?? Int(Date().timeIntervalSince1970)
        let cleanedMac = cleanMac(mac)
        let secondHash = md5Upper("\(clientIdPattern)$\(cleanedMac)")
        let clientId = "\(cleanedMac)$his$\(String(secondHash.prefix(6)))_vidaacommon_001"

        let crossSum = String(ts).compactMap { $0.wholeNumberValue }.reduce(0, +) % 10
        let username = "his$\(UInt64(ts) ^ xorTimestampMask)"
        let thirdHash = md5Upper("his\(crossSum)\(modernSalt)")
        let password = md5Upper("\(ts)$\(String(thirdHash.prefix(6)))")

        return Credentials(clientId: clientId, username: username, password: password)
    }
}
