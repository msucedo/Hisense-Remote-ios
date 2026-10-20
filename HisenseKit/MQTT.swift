// Cliente MQTT 3.1.1 escrito a mano. El framing (MQTTCodec/MQTTParser) es el
// mismo port de hisense-remote/mqtt.js, ya probado. El transporte usa SwiftNIO
// + NIOSSL (BoringSSL), que acepta el TLS viejito de la TV igual que OpenSSL;
// el TLS de Apple (Network.framework) fallaba el handshake con esta TV.

import Foundation
import NIO
import NIOSSL

// MARK: - Codificación de paquetes

enum MQTTType: UInt8 {
    case connect = 1, connack = 2, publish = 3, suback = 9, pingreq = 12, disconnect = 14, subscribe = 8
}

struct MQTTPacket {
    let type: UInt8
    let flags: UInt8
    var topic: String = ""
    var payload: String = ""
    var connackCode: UInt8 = 0
}

enum MQTTCodec {
    // "Remaining length": 7 bits por byte, el bit alto indica continuación.
    static func encodeLength(_ n: Int) -> [UInt8] {
        var out = [UInt8](); var x = n
        repeat {
            var byte = UInt8(x % 128); x /= 128
            if x > 0 { byte |= 0x80 }
            out.append(byte)
        } while x > 0
        return out
    }

    static func str(_ s: String) -> [UInt8] {
        let b = Array(s.utf8)
        return [UInt8(b.count >> 8), UInt8(b.count & 0xff)] + b
    }

    static func packet(_ type: MQTTType, _ flags: UInt8, _ body: [UInt8]) -> [UInt8] {
        [(type.rawValue << 4) | flags] + encodeLength(body.count) + body
    }

    static func connect(clientId: String, username: String, password: String, keepalive: UInt16 = 45) -> [UInt8] {
        var flags: UInt8 = 0x02          // sesión limpia
        flags |= 0x80 | 0x40             // usuario + contraseña presentes
        let ka: [UInt8] = [UInt8(keepalive >> 8), UInt8(keepalive & 0xff)]
        var body = str("MQTT") + [4] + [flags] + ka  // MQTT 3.1.1 (nivel 4)
        body += str(clientId) + str(username) + str(password)
        return packet(.connect, 0, body)
    }

    static func publish(_ topic: String, _ payload: String) -> [UInt8] {
        packet(.publish, 0, str(topic) + Array(payload.utf8))
    }

    static func subscribe(id: UInt16, topics: [String]) -> [UInt8] {
        var body: [UInt8] = [UInt8(id >> 8), UInt8(id & 0xff)]
        for t in topics { body += str(t) + [0] }   // QoS 0
        return packet(.subscribe, 0x02, body)
    }

    static func ping() -> [UInt8] { packet(.pingreq, 0, []) }
    static func disconnect() -> [UInt8] { packet(.disconnect, 0, []) }
}

// Acumula bytes y va extrayendo paquetes completos (TCP no respeta bordes).
final class MQTTParser {
    private var buf = [UInt8]()

    func push(_ chunk: [UInt8]) -> [MQTTPacket] {
        buf.append(contentsOf: chunk)
        var packets = [MQTTPacket]()
        while true {
            guard buf.count >= 2 else { break }
            var len = 0, mult = 1, i = 1
            var byte: UInt8 = 0
            repeat {
                if i >= buf.count { return packets }     // falta el largo
                byte = buf[i]; i += 1
                len += Int(byte & 0x7f) * mult; mult *= 128
            } while (byte & 0x80) != 0
            guard buf.count >= i + len else { break }     // falta el cuerpo
            let first = buf[0]
            let body = Array(buf[i ..< i + len])
            packets.append(decode(first: first, body: body))
            buf.removeFirst(i + len)
        }
        return packets
    }

    private func decode(first: UInt8, body: [UInt8]) -> MQTTPacket {
        let type = first >> 4
        var p = MQTTPacket(type: type, flags: first & 0x0f)
        if type == MQTTType.connack.rawValue, body.count >= 2 {
            p.connackCode = body[1]
        } else if type == MQTTType.publish.rawValue, body.count >= 2 {
            let qos = (first >> 1) & 3
            let tlen = Int(body[0]) << 8 | Int(body[1])
            let tEnd = 2 + tlen
            if tEnd <= body.count {
                p.topic = String(bytes: body[2 ..< tEnd], encoding: .utf8) ?? ""
                let pStart = tEnd + (qos > 0 ? 2 : 0)
                if pStart <= body.count {
                    p.payload = String(bytes: body[pStart ..< body.count], encoding: .utf8) ?? ""
                }
            }
        }
        return p
    }
}

// MARK: - Transporte (SwiftNIO + NIOSSL)

final class MQTTClient {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var channel: Channel?
    private let parser = MQTTParser()
    private var nextId: UInt16 = 1

    var onConnack: ((UInt8) -> Void)?
    var onMessage: ((String, String) -> Void)?
    var onClose: (() -> Void)?

    // Maneja los bytes entrantes: los pasa al parser y entrega paquetes.
    private final class InboundHandler: ChannelInboundHandler {
        typealias InboundIn = ByteBuffer
        let owner: MQTTClient
        init(_ owner: MQTTClient) { self.owner = owner }

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buf = unwrapInboundIn(data)
            guard let bytes = buf.readBytes(length: buf.readableBytes) else { return }
            for p in owner.parser.push(bytes) {
                if p.type == MQTTType.connack.rawValue { owner.onConnack?(p.connackCode) }
                else if p.type == MQTTType.publish.rawValue { owner.onMessage?(p.topic, p.payload) }
            }
        }
        func channelInactive(context: ChannelHandlerContext) { owner.onClose?() }
        func errorCaught(context: ChannelHandlerContext, error: Error) { context.close(promise: nil) }
    }

    func connect(host: String, port: UInt16, p12: Data, p12Password: String,
                 clientId: String, username: String, password: String, keepalive: UInt16 = 45) {
        do {
            // Certificado de cliente (cert + llave) desde el .p12.
            let bundle = try NIOSSLPKCS12Bundle(buffer: Array(p12), passphrase: Array(p12Password.utf8))
            var cfg = TLSConfiguration.makeClientConfiguration()
            cfg.certificateVerification = .none           // la TV usa cert autofirmado
            cfg.certificateChain = bundle.certificateChain.map { .certificate($0) }
            cfg.privateKey = .privateKey(bundle.privateKey)
            cfg.minimumTLSVersion = .tlsv12
            let sslContext = try NIOSSLContext(configuration: cfg)

            let bootstrap = ClientBootstrap(group: group)
                .connectTimeout(.seconds(5))   // si no conecta en 5 s, falla en vez de colgarse
                .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
                .channelInitializer { channel in
                    do {
                        // serverHostname = nil porque conectamos por IP.
                        let tls = try NIOSSLClientHandler(context: sslContext, serverHostname: nil)
                        return channel.pipeline.addHandlers([tls, InboundHandler(self)])
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                }

            bootstrap.connect(host: host, port: Int(port)).whenComplete { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let ch):
                    self.channel = ch
                    self.write(MQTTCodec.connect(clientId: clientId, username: username,
                                                 password: password, keepalive: keepalive))
                    self.schedulePing(on: ch, every: keepalive)
                case .failure:
                    self.onClose?()
                }
            }
        } catch {
            onClose?()
        }
    }

    private func schedulePing(on channel: Channel, every keepalive: UInt16) {
        channel.eventLoop.scheduleRepeatedTask(
            initialDelay: .seconds(Int64(keepalive) / 2),
            delay: .seconds(Int64(keepalive) / 2)
        ) { [weak self] _ in
            self?.write(MQTTCodec.ping())
        }
    }

    private func write(_ bytes: [UInt8]) {
        guard let ch = channel else { return }
        var buf = ch.allocator.buffer(capacity: bytes.count)
        buf.writeBytes(bytes)
        ch.writeAndFlush(buf, promise: nil)
    }

    func publish(_ topic: String, _ payload: String = "") { write(MQTTCodec.publish(topic, payload)) }
    func subscribe(_ topics: [String]) { write(MQTTCodec.subscribe(id: nextId, topics: topics)); nextId += 1 }
    func end() {
        write(MQTTCodec.disconnect())
        channel?.close(promise: nil)
        // Cierre asíncrono: syncShutdownGracefully() peta si se llama desde el
        // propio event loop (p.ej. dentro de un callback).
        group.shutdownGracefully { _ in }
    }
}
