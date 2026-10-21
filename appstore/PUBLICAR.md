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

## 1b. Para poder cobrar (una vez)

1. App Store Connect ▸ **Business** (antes "Agreements, Tax, and Banking"): acepta el
   **Paid Apps Agreement** y llena la cuenta bancaria y los datos fiscales (RFC / formulario W-8BEN).
   Hasta que diga **Active** no se puede vender la compra in-app. Puede tardar días: empiézalo pronto.
2. Inscríbete en el **App Store Small Business Program**
   (https://developer.apple.com/app-store/small-business-program/): Apple se queda con el 15% en vez del 30%.

## 2. Crear la app en App Store Connect

1. https://appstoreconnect.apple.com ▸ **Apps** ▸ **+** ▸ **Nueva app**.
2. Plataforma iOS, nombre `HisenseRemote`, idioma Español (México),
   bundle ID `com.mariosaucedo.HisenseRemote`, SKU `hisenseremote-ios-1`.
   - Si el bundle ID no aparece en la lista, regístralo antes en
     developer.apple.com ▸ Certificates, IDs & Profiles ▸ Identifiers ▸ +, o deja que Xcode lo cree en el paso 3.
3. Llena la ficha con `appstore/LISTING.md`: privacidad, categoría, clasificación por edad y precio.
4. Crea la **compra in-app** con los datos de la sección "Compra dentro de la app" de `LISTING.md`.
   El Product ID tiene que ser exactamente `com.mariosaucedo.HisenseRemote.full`.
5. **Users and Access ▸ Sandbox ▸ +**: crea un probador sandbox con un correo que **no** sea tu Apple ID.
   Sirve para probar compras de verdad sin que te cobren.

## 3. Subir el build desde Xcode

> **Usa Xcode 26 o más nuevo** (SDK de iOS 26+). App Store Connect rechaza los builds hechos con
> Xcode 16 / SDK 18 (así pasó con el build 1). En esta Mac es `/Applications/Copia de Xcode.app` (Xcode 26.3).

1. Abre `HisenseRemote/HisenseRemote.xcodeproj`.
2. Target HisenseRemote ▸ **Signing & Capabilities** ▸ Team = tu cuenta de pago,
   con "Automatically manage signing" activado. Agrega **+ Capability ▸ In-App Purchase**
   (con firma automática ya viene activa en el App ID; así queda visible).
3. Revisa que `client.p12` esté en `HisenseRemote/HisenseRemote/`: sin él la app no conecta.
4. Destino arriba: **Any iOS Device (arm64)**.
5. **Product ▸ Archive**. Cuando termine, se abre el Organizer.
6. **Distribute App ▸ App Store Connect ▸ Upload**, y acepta lo que proponga.
7. En 10 a 30 minutos el build aparece en App Store Connect (pestaña TestFlight) como "Processing" y luego listo.

**Versiones** (target ▸ General):
- **Build** (`CURRENT_PROJECT_VERSION`): súbelo en uno (2, 3, …) **cada vez** que subas algo a
  App Store Connect, aunque sea para la misma versión. Apple no acepta dos builds con el mismo número.
- **Version** (`MARKETING_VERSION`): se queda en **1.0** hasta que se publique. Después:
  1.0.1 para arreglos y 1.1 para funciones nuevas (por ejemplo, de la versión completa).

## 4. Probar antes (recomendado)

En la pestaña **TestFlight**, agrégate como probador interno e instala el build con la app
TestFlight en tu iPhone. Así pruebas exactamente lo que va a revisar Apple, ya firmado para producción.

La compra en TestFlight usa el sandbox y no cobra. Pruébala: ★ ▸ Comprar ▸ Apps desbloqueada.
Luego borra la app, reinstálala y usa **Restaurar compras**.

Mientras desarrollas en Xcode, también puedes simularla sin internet con `Products.storekit`
(ver README, "Probar la compra sin cobrar"). Si eliges ese archivo en el esquema, Xcode usa la
tienda simulada y no el sandbox.

## 5. Mandar a revisión

1. En la versión 1.0 de la ficha: sube el App Preview (`appstore/preview/preview.mp4`) y las capturas, elige el build, **agrega la compra in-app**
   en su sección y pega las **notas para el revisor** con el enlace al video (ver `LISTING.md`).
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
