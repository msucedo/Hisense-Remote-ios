# Armar la app en Xcode (paso a paso)

El núcleo ya funciona (paquete `RemoteKit`). Falta envolverlo en una app iOS y
correrla en tu iPhone. Esto se hace en Xcode (yo no puedo firmar/instalar por ti).

## 1. Activar Xcode (una vez)
En la terminal:
```
sudo xcode-select -s /Applications/Xcode.app
```
(Para volver a las Command Line Tools en tus otros proyectos: `sudo xcode-select -s /Library/Developer/CommandLineTools`.)

## 2. Crear el proyecto
1. Xcode → **File → New → Project… → iOS → App**.
2. Product Name: `HisenseRemote`. Interface: **SwiftUI**. Language: **Swift**.
3. Guárdalo donde quieras (p. ej. dentro de `hisense-remote-ios/`).

## 3. Meter el código de la app
En el proyecto nuevo, Xcode generó `HisenseRemoteApp.swift` y `ContentView.swift`.
- **Borra** esos dos generados (o reemplaza su contenido) y **agrega** los tres de la carpeta `ios/` de este repo:
  - `HisenseRemoteApp.swift`
  - `ContentView.swift`
  - `RemoteViewModel.swift`
  (Arrástralos al proyecto, marca *Copy items if needed* y que pertenezcan al target.)
- Debe quedar **un solo** `@main` (el de `HisenseRemoteApp.swift`).

## 4. Agregar el paquete RemoteKit (trae SwiftNIO/NIOSSL)
- **File → Add Package Dependencies… → Add Local…** y elige la carpeta raíz del repo
  `hisense-remote-ios/` (la que tiene `Package.swift`).
- Agrega el producto **`RemoteKit`** al target de la app. Xcode descargará swift-nio y swift-nio-ssl solo.

## 5. Meter el certificado al bundle
- Arrastra `secrets/client.p12` al proyecto. Marca *Copy items if needed* y el target de la app.
- Debe quedar con el nombre **`client.p12`** (el código lo busca así).

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
