# Armar la app en Xcode (paso a paso)

El núcleo ya funciona (paquete `RemoteKit`). Falta envolverlo en una app iOS y
correrla en tu iPhone. Esto se hace en Xcode (yo no puedo firmar/instalar por ti).

## 1. Activar Xcode (una vez)
En la terminal:
```
sudo xcode-select -s /Applications/Xcode.app
```
(Para volver a las Command Line Tools en tus otros proyectos: `sudo xcode-select -s /Library/Developer/CommandLineTools`.)

## 1b. Instalar la plataforma iOS en Xcode (una vez, ~8 GB)
Xcode trae cada plataforma por separado. Sin la de iOS no se puede compilar para iPhone
(error "iOS 18.2 is not installed"). Instálala con **Xcode → Settings → Components → iOS 18.2 → Get**
o en la terminal: `xcodebuild -downloadPlatform iOS`.

## 2. Crear el proyecto
1. Xcode → **File → New → Project…** → en la fila de pestañas de arriba elige **iOS** (no
   macOS ni Multiplatform) → **App**. Si eliges macOS, sale una app de Mac (con
   `SDKROOT = macosx` y App Sandbox), el iPhone no aparece como destino y truena con
   "No such module 'RemoteKit'".
2. Product Name: `HisenseRemote`. Interface: **SwiftUI**. Language: **Swift**.
3. Guárdalo donde quieras (p. ej. dentro de `hisense-remote-ios/`).

## 3. El código de la app
El proyecto ya existe en `HisenseRemote/` y su código vive en `HisenseRemote/HisenseRemote/`
(`HisenseRemoteApp.swift`, `ContentView.swift`, `RemoteViewModel.swift`). Esa carpeta es la
fuente única: Xcode 16 incluye automáticamente todo lo que haya dentro.

## 4. Agregar el paquete RemoteKit (trae SwiftNIO/NIOSSL)
- **File → Add Package Dependencies… → Add Local…** y elige la carpeta raíz del repo
  `hisense-remote-ios/` (la que tiene `Package.swift`).
- Agrega el producto **`RemoteKit`** al target de la app. Xcode descargará swift-nio y swift-nio-ssl solo.

## 5. Meter el certificado al bundle
- Copia `secrets/client.p12` **dentro de `HisenseRemote/HisenseRemote/`** (junto a los `.swift`).
  Si queda un nivel arriba, Xcode no lo mete en la app y la TV rechaza la conexión.
- Debe llamarse **`client.p12`** (el código lo busca así). `*.p12` está en `.gitignore`.

## 6. Permiso de red local
En el target → pestaña **Info** (Custom iOS Target Properties), agrega una fila:
- Key: `Privacy - Local Network Usage Description` (`NSLocalNetworkUsageDescription`)
- Value: `Para encontrar y controlar tu TV en la red local.`
Sin esto, iOS no deja escanear ni conectar.

## 7. Firmar y correr
1. Target → **Signing & Capabilities** → marca *Automatically manage signing* y elige tu **Team** (tu Apple ID gratis; si no aparece, agrégalo en Xcode → Settings → Accounts).
2. Conecta tu iPhone por cable, selecciónalo como destino y dale **Run** (▶).
3. La primera vez, en el iPhone: **Ajustes → General → VPN y gestión de dispositivos** → confía en tu perfil de desarrollador.
4. Al abrir, concede el permiso de **Red local** cuando lo pida.

## 8. Usarla
- La app escanea, encuentra la TV y, la primera vez, te pide el **PIN** que muestra la TV
  (ten cerrada la app oficial RemoteNOW). Después guarda el token y entra directo al control.
- D-pad, volumen en vivo, encender, fuentes y apps.

## Notas
- La app empareja por su cuenta (su propio clientId), independiente del CLI; es un PIN una sola vez.
- Las apps con Apple ID gratis caducan a los ~7 días; se renueva volviéndola a correr desde Xcode.
- `secrets/`, tokens y `*.token.json` están en `.gitignore`.
