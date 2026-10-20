// Descubrimiento de TVs en la red local. Port de hisense-remote/discover.js:
// probar el puerto 36669 en toda la subred y quedarnos con quien abra.

import Foundation
import Network

public enum Discovery {
    // Subred IPv4 propia (en0 normalmente): devuelve ("192.168.100", "192.168.100.14").
    static func localSubnet() -> (base: String, selfIP: String)? {
        var ptr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ptr) == 0, let first = ptr else { return nil }
        defer { freeifaddrs(ptr) }
        var result: (String, String)?
        var cur: UnsafeMutablePointer<ifaddrs>? = first
        while let c = cur {
            let ifa = c.pointee
            let name = String(cString: ifa.ifa_name)
            if ifa.ifa_addr.pointee.sa_family == UInt8(AF_INET), name == "en0" {
                var addr = sockaddr_in()
                memcpy(&addr, ifa.ifa_addr, MemoryLayout<sockaddr_in>.size)
                let ip = String(cString: inet_ntoa(addr.sin_addr))
                let base = ip.split(separator: ".").prefix(3).joined(separator: ".")
                result = (base, ip)
                break
            }
            cur = ifa.ifa_next
        }
        return result
    }

    // Prueba una IP:puerto; llama a `done(true)` si abre dentro del timeout.
    private static func probe(_ ip: String, _ port: UInt16, timeout: TimeInterval,
                              queue: DispatchQueue, done: @escaping (Bool) -> Void) {
        let conn = NWConnection(host: NWEndpoint.Host(ip),
                                port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        var finished = false
        let finish: (Bool) -> Void = { ok in
            if finished { return }; finished = true
            conn.cancel(); done(ok)
        }
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready: finish(true)
            // .waiting = rechazado o bloqueado (p. ej. sin permiso de Red local en iOS).
            case .failed, .cancelled, .waiting: finish(false)
            default: break
            }
        }
        conn.start(queue: queue)
        queue.asyncAfter(deadline: .now() + timeout) { finish(false) }
    }

    // Escanea .1–.254 y devuelve las IPs que abren el 36669.
    public static func scan(port: UInt16 = 36669, timeout: TimeInterval = 0.6,
                            completion: @escaping ([String]) -> Void) {
        guard let subnet = localSubnet() else { completion([]); return }
        let queue = DispatchQueue(label: "scan", attributes: .concurrent)
        let group = DispatchGroup()
        let lock = NSLock()
        var found = [String]()
        for i in 1...254 {
            let ip = "\(subnet.base).\(i)"
            if ip == subnet.selfIP { continue }
            group.enter()
            probe(ip, port, timeout: timeout, queue: queue) { ok in
                if ok { lock.lock(); found.append(ip); lock.unlock() }
                group.leave()
            }
        }
        group.notify(queue: .main) { completion(found.sorted()) }
    }
}
