# hisense-remote-ios — hoja de ruta

Control remoto nativo de iPhone (Swift) para smart TVs. **Primera entrega: solo Hisense — TERMINADA.**
La idea a futuro es un control universal (también Samsung y Sony), agregando cada marca como
"parche" sin rediseñar la app.

Última actualización: 2026-10-20 (compra in-app).

## Estado actual

**✅ Hisense funciona de punta a punta en el iPhone** (escaneo, PIN, D-pad, volumen en vivo,
fuentes, apps, encender). Repo con `README.md` y `LICENSE` (MIT).

**🚀 En camino a la App Store (2026-10-20).** Listo en el repo: ícono (`tools/make-icon.swift`),
`PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption = NO` (en `HisenseRemote/Info.plist`),
solo iPhone, `PRIVACY.md` y textos de la ficha en `appstore/LISTING.md`. Falta lo que necesita la
cuenta de pago (Developer Program, Archive, App Store Connect, capturas y video): ver `appstore/PUBLICAR.md`.

**💰 Versión completa (2026-10-20).** Cuenta de Apple Developer aprobada. Compra in-app no consumible
`com.mariosaucedo.HisenseRemote.full` ($29 MXN) hecha con StoreKit 2 y probada con `Products.storekit`.
Falta en App Store Connect: Paid Apps Agreement, crear la compra y mandarla junto con la 1.0.

Lo que ya está resuelto del protocolo (detalles en el código y en `../hisense-remote/`, la versión Node):
- MQTT 3.1.1 sobre TLS en el puerto `36669`, con **mutual TLS**: certificado de cliente de la app
  oficial (`client.p12`, subject `VidaaAppAndroidV01`). No va en el repo (`*.p12` en `.gitignore`).
- Credenciales **derivadas** en cada conexión (hora + MAC), en `HisenseKit/Crypto.swift`.
- Emparejamiento por PIN → token de larga duración (guardado en el teléfono).
- El comodín `#` está denegado: hay que suscribirse a topics exactos.
- **TLS:** el de Apple (Network.framework) falla el handshake de esta TV (`-9858`). Se resolvió con
  **SwiftNIO + NIOSSL** (BoringSSL): conexión 100% confiable.

## ⏸️ Pendiente ahora (2026-10-20): recompilar con el SDK de iOS 26

App Store Connect rechazó el build 1: *"This app was built with the iOS 18.2 SDK. All iOS and iPadOS
apps must be built with the iOS 26 SDK or later"*. La Mac tiene macOS 15.0.1 y Xcode 16.2, y ningún
Xcode 26 corre ahí. Plan completo en `appstore/PLAN-SDK26.md`.

1. **Tú:** Ajustes del Sistema ▸ Actualización de software ▸ **macOS Sequoia 15.8.1** (no la 27).
2. **Tú:** bajar **Xcode 26.3** (`.xip`) de https://developer.apple.com/download/all/ y dejarlo como
   `/Applications/Xcode-26.3.app` (convive con el 16.2). Abrirlo una vez para que instale la plataforma iOS.
3. **Claude:** compilar con `DEVELOPER_DIR=/Applications/Xcode-26.3.app/Contents/Developer`, corregir
   lo que rompa Swift 6.2 o las dependencias NIO, revisar el estilo Liquid Glass en el simulador,
   correr `StoreTests` y subir el build a **2**.
4. **Tú:** Run en el iPhone, **Archive ▸ Upload** del build 2 y mandar la 1.0 con la compra in-app.

## Estructura del repo

| Carpeta | Qué es |
|---|---|
| `HisenseKit/` | Núcleo, producto SwiftPM `RemoteKit`: `Crypto`, `MQTT` (framing a mano + transporte NIOSSL), `HisenseTV` (comandos y PIN), `Discovery` (escaneo del 36669). |
| `HisenseRemote/` | Proyecto Xcode de la app. **El código de la app vive en `HisenseRemote/HisenseRemote/`** (fuente única), junto a `client.p12`. `Store.swift` = compra in-app; `Products.storekit` (junto al .xcodeproj) = tienda simulada para pruebas. |
| `cli/` | `hisensectl` (`scan`, `ping`, `pair`, `cmd`) para probar el núcleo desde la Mac. |
| `appstore/` | Ficha de la tienda (`LISTING.md`) y guía para publicar (`PUBLICAR.md`). |
| `tools/` | `make-icon.swift`: genera los PNG del ícono. |
| `ios/SETUP.md` | Guía para crear/configurar el proyecto Xcode desde cero. |
| `secrets/` | Copia local del `.p12` (ignorada por git). |

## Cómo retomar

- **Compilar el núcleo/CLI:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build`
  (cuando esté instalado, usar `/Applications/Xcode-26.3.app/...`: para subir a la App Store se necesita Xcode 26+)
  (las Command Line Tools solas no bastan; así no hace falta cambiar `xcode-select`).
- **Probar la TV desde la terminal:** `.build/debug/hisensectl ping 192.168.100.5`.
  Si responde "conexión cerrada", primero revisa que la TV esté encendida (`ping 192.168.100.5`).
- **App en el iPhone:** abrir `HisenseRemote/HisenseRemote.xcodeproj`, firmar con tu Apple ID y Run.
  Con Apple ID gratis caduca a los ~7 días: se renueva dándole Run otra vez.
- **Verificar que la app compila sin el iPhone:**
  `xcodebuild -project HisenseRemote/HisenseRemote.xcodeproj -scheme HisenseRemote -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`

## Versión completa (compra in-app)

- App gratis y sin anuncios. La compra única "Versión completa" ($29 MXN) desbloquea funciones extra.
- **Hoy incluye:** la sección **Apps**.
- **Regla para lo nuevo:** toda función de pago se condiciona con `store.isFull` (el `Store` está en el
  entorno de SwiftUI) y se agrega a la lista `features` de `UpgradeView` en `ContentView.swift`, para
  que aparezca en la hoja de compra. Nunca le quites a la versión gratis algo que ya tenía.
- **Ideas para la versión completa:** teclado para buscar en la tele, varias teles guardadas, widget /
  Centro de control, atajos de Siri, Apple Watch, botones favoritos de apps.
- Al sacar funciones nuevas: subir `MARKETING_VERSION` (1.1, 1.2…) y el build.

## Siguiente: preparar el patrón de drivers (aún NO hecho)

Hoy la app usa `HisenseTV` directamente, las teclas están en `Keys.map` (nombres de Hisense) y
`Discovery.scan` devuelve solo IPs. Antes de agregar la segunda marca hay que:
1. Crear `TVRemote` (protocol): `connect`, `pair`, `sendKey(RemoteKey)`, `setVolume`, `power`,
   `launchApp`, eventos de estado.
2. Crear `RemoteKey` (enum neutral de teclas) y que cada driver lo traduzca a su código.
3. Envolver `HisenseTV` como `VidaaDriver: TVRemote`.
4. Crear `DiscoveredTV` (marca, ip, modelo, nombre) y que el descubrimiento la devuelva.
5. Cambiar `RemoteViewModel` para que hable con `TVRemote` y no con `HisenseTV`.

## Futuro (otras marcas, cuando se decida)
- **Samsung (Tizen):** WebSocket `wss://<ip>:8002/api/v2/channels/samsung.remote.control`, token por
  popup "Permitir" en la TV, comandos `ms.remote.control`. Referencia pública: `samsungtvws`.
- **Sony (Bravia):** API HTTP `/sony/IRCC` (teclas) + `/sony/system` (registro por PIN o clave PSK).
  El modelo exacto no se conoce todavía; se detecta con `getSystemInformation`.
- **Emuladores** `samsung-emu` / `sony-emu` para desarrollar sin las TVs físicas (están lejos);
  la validación final siempre es con la TV real.
- **Descubrimiento universal** por SSDP que identifique la marca.

## Notas
- El driver Hisense usa el certificado de cliente de Hisense; para la App Store se cuenta con
  permiso para usarlo (Apple puede pedir el comprobante en la revisión).
- Fuera de git: `*.p12`, `secrets/`, `*.token.json`, `.build/`, `xcuserdata/`.
- Al probar, conexiones de una en una (no en ráfaga) para no dejar la TV en estado raro.
- El aviso de Xcode `nw_connection_copy_connected_remote_endpoint … unconnected` es ruido del escaneo.
