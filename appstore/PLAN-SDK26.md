# HisenseRemote: recompilar con el SDK de iOS 26+ para poder subirla

> ✅ **Hecho (2026-10-20).** macOS 15.8.1 + Xcode 26.3 (quedó en `/Applications/Copia de Xcode.app`).
> Compila sin errores con Swift 6.2.4 y el SDK `iphoneos26.2`. Se corrigió un aviso de `Sendable` en
> `HisenseKit/MQTT.swift` (`pipeline.syncOperations`). No hizo falta subir NIO. `StoreTests` pasa en el
> simulador iOS 26.3 (hizo falta `HisenseRemote/Debug.entitlements` con `get-task-allow`: sin él, storekitd
> rechaza `SKTestSession` con "is not installed for development"). Build **2**, versión 1.0, mínimo iOS 18.2.
> Las pantallas en iOS 26 se ven bien. En el simulador 26.3 los emojis salen como "?" y en el 18.3 no: es del
> simulador, pero hay que confirmarlo en el iPhone. Falta lo tuyo: Archive ▸ Upload.

## Contexto
App Store Connect rechazó el build: se compiló con **Xcode 16.2 (SDK iOS 18.2)** y Apple ya exige el **SDK de iOS 26 o posterior** (Xcode 26+).

La Mac tiene macOS **15.0.1**, un M1 (Apple silicon) y 68 GB libres. Ningún Xcode 26 corre en macOS 15.0.1:
- Xcode 26.0–26.3: piden macOS Sequoia **15.6+**.
- Xcode 26.4.1 y Xcode 27: piden macOS **Tahoe 26.x** o más nuevo.

`softwareupdate` ofrece **macOS Sequoia 15.8.1** y **macOS 27.0.1**.

## Ruta recomendada: Sequoia 15.8.1 + Xcode 26.3 (el cambio mínimo)
Lo hace el usuario (requiere contraseña, reinicio y su Apple ID):
1. **Ajustes del Sistema ▸ General ▸ Actualización de software** → instalar **macOS Sequoia 15.8.1**, no la 27. Son unos 7 GB y un reinicio.
2. Bajar **Xcode 26.3** de https://developer.apple.com/download/all/ (buscar "Xcode 26.3", archivo `.xip`).
   - Descomprimirlo y moverlo a `/Applications/Xcode-26.3.app`. Así convive con Xcode 16.2; no hace falta reemplazarlo.
   - Abrirlo una vez para que instale sus componentes y la plataforma iOS 26.
3. Avisarme. Yo sigo con lo de abajo.

(Alternativa: macOS 27 + Xcode 27 desde la App Store. Es más grande y nueva; también sirve, porque Apple acepta el SDK 26 "o posterior".)

## Lo que hago yo después
1. Compilar con el nuevo Xcode sin tocar `xcode-select`:
   - `DEVELOPER_DIR=/Applications/Xcode-26.3.app/Contents/Developer xcodebuild … build`;
   - lo mismo para `swift build`, el paquete `RemoteKit` y el CLI.
2. Corregir lo que rompa el compilador nuevo (Swift 6.2, en modo de lenguaje Swift 5).
   - Si swift-nio 2.65 / swift-nio-ssl 2.26 dan errores con el nuevo toolchain, subir sus versiones en `Package.swift`/`Package.resolved` (actualización menor y compatible).
3. **Liquid Glass:** con el SDK 26, los controles del sistema (la hoja de compra, `.bordered`, ProgressView) toman el estilo nuevo.
   - Reviso las pantallas en el simulador con el modo demo del usuario (`Demo.swift`, `-demoScreen remote`) y la hoja ★.
   - Si algo se ve mal, ajusto el estilo. Solo si de plano no queda, uso la clave `UIDesignRequiresCompatibility` en `HisenseRemote/Info.plist`.
4. Correr `StoreTests` en el simulador de iOS 26.
5. Subir el **build a 2** (`CURRENT_PROJECT_VERSION`). La versión sigue en 1.0.
6. Docs:
   - README "Requisitos": Xcode 26+ (iOS 26 SDK), sin cambiar el mínimo de iOS 18.2;
   - ROADMAP "Cómo retomar": el `DEVELOPER_DIR` nuevo;
   - `appstore/PUBLICAR.md`: nota del requisito de SDK;
   - memoria.

La versión mínima de iOS se queda en **18.2**: tu iPhone y los usuarios con iOS 18 la siguen pudiendo instalar.

## Verificación
- `xcodebuild … -destination 'generic/platform=iOS' build` con Xcode 26.3 sin errores, y el `Info.plist` del `.app` con `DTSDKName = iphoneos26.x`.
- `StoreTests` pasa en el simulador.
- Capturas del simulador (control y hoja de compra) revisadas.
- Tú: Run en el iPhone (control + compra de prueba), luego **Archive ▸ Upload** del build 2, y en la versión 1.0 eliges el build 2 y lo mandas con la compra in-app.
