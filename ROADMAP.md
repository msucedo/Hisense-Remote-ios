# hisense-remote-ios — hoja de ruta

Control remoto nativo de iPhone (Swift) para smart TVs. **Esta entrega: solo Hisense.**
La arquitectura queda lista para agregar otras marcas después como "parche", sin rediseñar.

## Estado
- **Protocolo Hisense: resuelto y verificado** (primero en Node, en `../hisense-remote/`).
  - MQTT sobre TLS en el puerto `36669`, mutual TLS con el certificado de cliente de la app
    (`secrets/client.p12`, subject `VidaaAppAndroidV01`).
  - Credenciales **derivadas** por conexión (hora + MAC), ver `HisenseKit/Crypto.swift`.
  - Emparejamiento por PIN → token de larga duración.
  - El comodín `#` en las suscripciones está denegado: hay que usar topics exactos.
- **Núcleo Swift portado y probado** hasta CONNACK 0 contra la TV real.
- **Pendiente técnico clave:** el TLS de Apple (Secure Transport / Network.framework) falla el
  handshake de esta TV de forma intermitente (`-9858`). Node (OpenSSL) sí conecta. **Solución:
  cambiar el transporte a SwiftNIO + NIOSSL** (se comporta como OpenSSL y acepta la TV).

## Arquitectura (patrón de drivers)
- `TVRemote` (protocol): `discover`, `connect`, `pair`, `sendKey(RemoteKey)`, `setVolume`,
  `power`, `launchApp`, `state`. Interfaz común = "ranura" para marcas futuras.
- `RemoteKey`: enum neutral de teclas que cada driver mapea a su código.
- `DiscoveredTV`: marca, ip, modelo, nombre.
- `VidaaDriver` (Hisense): único driver de esta entrega. Reúne `Crypto`, `MQTTCodec`/`MQTTParser`,
  `HisenseTV`, `Discovery`, con transporte NIOSSL.

## Ahora (solo Hisense, y lanzar)
1. ✅ **HECHO.** `Package.swift` (swift-nio / swift-nio-ssl); núcleo `RemoteKit` (`HisenseKit/`:
   `Crypto`, `MQTT` con transporte NIOSSL, `HisenseTV`, `Discovery`) + CLI `hisensectl`
   (`scan`/`ping`/`pair`/`cmd`). Verificado contra la TV real: scan OK, `ping` 6/6 CONNACK 0,
   emparejamiento por PIN y `cmd app YouTube` abren YouTube. El cert de cliente se carga con
   `NIOSSLPKCS12Bundle`, `certificateVerification = .none`.
   - Compilar/correr: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build`.
2. ⏳ **App iOS SwiftUI** — fuentes listas en `ios/` (`HisenseRemoteApp.swift`, `ContentView.swift`,
   `RemoteViewModel.swift`). La compila y firma el usuario en Xcode siguiendo `ios/SETUP.md`:
   crear proyecto, agregar esos archivos, agregar el paquete local `RemoteKit`, meter
   `client.p12` al bundle, poner `NSLocalNetworkUsageDescription`, firmar con Apple ID y correr.
   Escaneo 36669, control (D-pad, volumen en vivo, fuentes, apps, encender), flujo de PIN.

## Futuro (parches, NO ahora)
- `SamsungDriver`: WebSocket Tizen `wss://<ip>:8002/...`, token por popup "Permitir".
- `SonyDriver`: API HTTP Bravia `/sony/IRCC` + `/sony/system`, con PSK o registro por PIN.
- Emuladores `samsung-emu` / `sony-emu` para desarrollar sin las TVs físicas (están lejos).
- Descubrimiento universal por SSDP que clasifica la marca.

## Verificación
- **CLI (yo):** `swift build`; `hisensectl scan` encuentra la TV; CONNACK 0 repetible;
  `hisensectl pair <ip>` (teclear PIN) guarda token; `hisensectl cmd <ip> app YouTube` abre YouTube.
- **App (usuario):** `sudo xcode-select -s /Applications/Xcode.app`, abrir en Xcode, firmar con
  Apple ID, correr en el iPhone, conceder "Red local", escanear, emparejar y controlar.

## Notas
- Uso personal: el driver Hisense usa el certificado de Hisense (zona gris). Un universal
  **vendible** sería por infrarrojo (IR), no esto.
- `secrets/` (el `.p12`), tokens y `*.token.json` quedan fuera de git.
- Al probar, conexiones de una en una (no en ráfaga) para no dejar la TV en estado raro.
