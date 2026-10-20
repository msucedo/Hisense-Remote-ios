# Cómo publicar HisenseRemote en la App Store

Lo que ya está listo en el repo: ícono (claro, oscuro y tintado), manifiesto de privacidad
(`PrivacyInfo.xcprivacy`), cifrado declarado como exento, solo iPhone, política de privacidad
(`PRIVACY.md`) y todos los textos de la ficha (`appstore/LISTING.md`).

Lo que sigue lo haces tú, porque necesita tu cuenta de Apple.

## 1. Cuenta de desarrollador (una vez)

1. Entra a https://developer.apple.com/programs/enroll/ con tu Apple ID.
2. Inscríbete como **Individual** (99 USD al año). La aprobación puede tardar de horas a un par de días.
3. Cuando esté activa, en Xcode ▸ Settings ▸ Accounts debe aparecer tu Team como
   "Apple Development Program" (ya no "Personal Team").

## 2. Crear la app en App Store Connect

1. https://appstoreconnect.apple.com ▸ **Apps** ▸ **+** ▸ **Nueva app**.
2. Plataforma iOS, nombre `HisenseRemote`, idioma Español (México),
   bundle ID `com.mariosaucedo.HisenseRemote`, SKU `hisenseremote-ios-1`.
   - Si el bundle ID no aparece en la lista, regístralo antes en
     developer.apple.com ▸ Certificates, IDs & Profiles ▸ Identifiers ▸ +, o deja que Xcode lo cree en el paso 3.
3. Llena la ficha con `appstore/LISTING.md`: privacidad, categoría, clasificación por edad y precio.

## 3. Subir el build desde Xcode

1. Abre `HisenseRemote/HisenseRemote.xcodeproj`.
2. Target HisenseRemote ▸ **Signing & Capabilities** ▸ Team = tu cuenta de pago,
   con "Automatically manage signing" activado.
3. Revisa que `client.p12` esté en `HisenseRemote/HisenseRemote/`: sin él la app no conecta.
4. Destino arriba: **Any iOS Device (arm64)**.
5. **Product ▸ Archive**. Cuando termine, se abre el Organizer.
6. **Distribute App ▸ App Store Connect ▸ Upload**, y acepta lo que proponga.
7. En 10 a 30 minutos el build aparece en App Store Connect (pestaña TestFlight) como "Processing" y luego listo.

Para cada nueva versión, sube **Build** (`CURRENT_PROJECT_VERSION`) en uno (2, 3, …) y,
si cambia la versión pública, también **Version** (`MARKETING_VERSION`, 1.0 → 1.1).
Ambos están en el target ▸ General.

## 4. Probar antes (recomendado)

En la pestaña **TestFlight**, agrégate como probador interno e instala el build con la app
TestFlight en tu iPhone. Así pruebas exactamente lo que va a revisar Apple, ya firmado para producción.

## 5. Mandar a revisión

1. En la versión 1.0 de la ficha: sube las capturas, elige el build y pega las
   **notas para el revisor** con el enlace al video (ver `LISTING.md`).
2. **Agregar para revisión ▸ Enviar**.
3. La revisión suele tardar de 1 a 3 días. Si la rechazan, el motivo llega en "Resolution Center".
   Lo más probable que pregunten: cómo probarla sin una tele (por eso el video) y el permiso
   para usar la marca y el certificado de Hisense.

## Ajustes que se pueden cambiar

- **Nombre bajo el ícono:** `INFOPLIST_KEY_CFBundleDisplayName` en el target (hoy `HisenseRemote`).
- **iPad:** hoy es solo iPhone (`TARGETED_DEVICE_FAMILY = 1`). Para iPad hay que poner `1,2`
  y subir capturas de iPad de 13".
- **Ícono:** se regenera con
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift tools/make-icon.swift HisenseRemote/HisenseRemote/Assets.xcassets/AppIcon.appiconset`
