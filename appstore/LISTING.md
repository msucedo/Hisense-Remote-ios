# Textos para App Store Connect

Copia y pega cada campo en App Store Connect. Entre paréntesis va el límite de caracteres de Apple.
Idioma principal: **Español (México)**.

## Información de la app

| Campo | Valor |
|---|---|
| Nombre (30) | `HisenseRemote` |
| Subtítulo (30) | `Control remoto para tu tele` |
| Categoría principal | Utilidades |
| Categoría secundaria | Entretenimiento (opcional) |
| Bundle ID | `com.mariosaucedo.HisenseRemote` |
| SKU | `hisenseremote-ios-1` (cualquier texto único; solo lo ves tú) |
| Clasificación por edad | 4+ (responde "No" a todo el cuestionario) |
| Precio | Gratis (con compra in-app de $29 MXN) |
| URL de privacidad | `https://github.com/msucedo/Hisense-Remote-ios/blob/main/PRIVACY.md` |
| URL de soporte | `https://github.com/msucedo/Hisense-Remote-ios` |

> El repo debe ser **público** para que esas URLs abran. Si lo quieres privado,
> publica `PRIVACY.md` en otro lado (GitHub Pages, un Gist público, etc.) y usa esa URL.

## Texto promocional (170)

```
Controla tu tele Hisense VIDAA desde el iPhone por WiFi. Gratis y sin anuncios; la versión completa abre tus apps con un toque.
```

## Descripción (4000)

```
HisenseRemote convierte tu iPhone en el control remoto de tu televisor Hisense con VIDAA, a través de tu red WiFi.

Abre la app, encuentra tu tele automáticamente, emparéjala una sola vez con el PIN que aparece en pantalla y listo.

• Encender y apagar
• D-pad y OK para navegar los menús
• Atrás, Inicio y Menú
• Volumen en vivo: ves el nivel real de la tele mientras lo cambias
• Silenciar
• Cambiar de fuente (HDMI, TV, etc.) con un toque
Gratis y sin anuncios.

VERSIÓN COMPLETA ($29 MXN, una sola compra)
• Abre tus apps directamente: YouTube, Netflix y las demás que tenga tu tele
• Incluye las funciones que se agreguen en el futuro

Privacidad: la app solo habla con tu tele dentro de tu red local. No recolecta datos, no tiene anuncios y no envía nada a internet.

Requisitos: un televisor Hisense con sistema VIDAA conectado al mismo WiFi que tu iPhone.
```

## Palabras clave (100)

```
hisense,vidaa,control,remoto,tv,tele,televisor,wifi,smart tv,mando,volumen
```

## Compra dentro de la app

App Store Connect ▸ tu app ▸ **Monetización ▸ Compras dentro de la app ▸ +**

| Campo | Valor |
|---|---|
| Tipo | **No consumible** |
| Nombre de referencia | `Versión completa` |
| Product ID | `com.mariosaucedo.HisenseRemote.full` (debe ser exacto: es el que busca el código) |
| Precio | $29.00 MXN (elige México como país base; Apple calcula los demás) |
| Compartir en familia | Recomendado **activado**. ⚠️ Una vez activado ya no se puede desactivar. |
| Nombre visible (es-MX) | `Versión completa` |
| Descripción (es-MX, 55) | `Abre tus apps con un toque y lo que venga después.` |
| Imagen (1024×1024) | `appstore/iap-version-completa.png` (se regenera con `swift tools/make-iap-image.swift`; Apple no acepta capturas aquí) |
| Captura para revisión | Captura de la hoja "Versión completa" (botón ★ arriba a la derecha) |
| Notas de revisión | `Unlocks the "Apps" section (launch TV apps with one tap). Tap "★ Versión completa" at the top right of any screen — it is reachable without a TV.` |

La compra debe agregarse a la versión 1.0 (sección "Compras dentro de la app" de la versión)
antes de mandarla a revisión: la primera compra in-app solo se revisa junto con una versión de la app.

## App Privacy (cuestionario de privacidad)

- "¿Tú o tus socios recopilan datos de esta app?" → **No**.
- Resultado: la ficha mostrará **"Data Not Collected"**.

## Exportación / cifrado

Ya está resuelto en el proyecto (`ITSAppUsesNonExemptEncryption = NO`): la app solo
usa TLS estándar, que está exento. App Store Connect no te lo volverá a preguntar.

## Notas para el revisor (App Review Information → Notes)

```
This app is a Wi-Fi remote control for Hisense TVs running VIDAA OS. It only communicates with the TV on the local network (MQTT over TLS, port 36669); it has no server and no account.

Testing requires a Hisense VIDAA TV on the same Wi-Fi network, so we attached a demo video showing the full flow: automatic discovery, PIN pairing, D-pad, live volume, input switching and launching apps.

No login is required. The Local Network permission is used only to discover and control the TV.

In-app purchase: the app is free; the non-consumable "Versión completa" unlocks the "Apps" section. The purchase screen is reachable without a TV from the "★ Versión completa" button at the top right of the first screen, and includes "Restaurar compras" (Restore Purchases).

The developer is authorized by Hisense to use the Hisense name and the client certificate used to connect to the TV. Documentation can be provided on request.
```

> Ajusta el último párrafo para que diga exactamente qué permiso tienes; si Apple lo pide,
> tendrás que mostrar el documento. Sin login, deja vacíos los campos de "Sign-in required".

## Capturas de pantalla

Ya están hechas (capturas reales del simulador, en modo demo):

| Ranura en App Store Connect | Tamaño | Carpeta |
|---|---|---|
| iPhone 6.3" (16 Pro, 15 Pro…) | 1206×2622 | `appstore/screenshots/6.3/` |
| iPhone 6.9" (16 Pro Max…) | 1320×2868 | `appstore/preview/frames/` (sube 01, 02 y 03) |

Si App Store Connect dice "las dimensiones del archivo no son válidas", la captura es de otra ranura.
Para regenerar las de 6.3": `SIM="iPhone 16 Pro" tools/capture-preview.sh appstore/screenshots/6.3`.


- Obligatorias: **iPhone 6.9"** (1320×2868, por ejemplo iPhone 16 Pro Max) **o 6.5"** (1284×2778).
  Si tu iPhone es de otro tamaño, App Store Connect acepta capturas de 6.9" y las escala a los demás.
- Sugeridas (3 a 5): buscando la tele / pantalla del PIN / control con el D-pad / sección de Apps.
- No pongas el PIN real de tu tele visible si no quieres.

## App Preview (el video de arriba de la ficha)

Ya está hecho: `appstore/preview/preview.mp4` (886×1920, 30 fps, 22 s, H.264 + audio en silencio,
que App Store Connect exige aunque no suene). Usa capturas reales de la app, como pide Apple.

- **Dónde se sube:** versión 1.0 ▸ *Vista previa y capturas de pantalla* ▸ iPhone 6.9" ▸ arrastra el MP4
  al primer lugar (antes de las capturas). Hasta 3 videos por idioma.
- **Póster:** App Store Connect te deja elegir el fotograma que se ve antes de que arranque;
  el de ~10 s (el control con "Navega los menús con el D-pad") es buena opción.
- **Regenerarlo** (si cambia la interfaz):
  ```
  tools/capture-preview.sh     # compila, abre el simulador en modo demo y saca las capturas
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift tools/make-preview.swift
  ```
  Las frases, tiempos y toques están al inicio de `tools/make-preview.swift` (sección "Guion").
  El modo demo vive en `HisenseRemote/HisenseRemote/Demo.swift` y solo existe en builds DEBUG.
- Las capturas de `appstore/preview/frames/` (1320×2868) sirven también como screenshots de 6.9".

## Encabezado horizontal (sección de "componentes")

No es lo mismo que el App Preview: esa sección pide **5244×2950** o **3840×1646**
(un archivo de 886×1920 ahí da "las dimensiones del archivo no son válidas").
Hay versión animada y fija en `appstore/preview/`:

| Archivo | Qué es |
|---|---|
| `header-3840x1646.mp4` | video H.264, 22 s |
| `header-5244x2950.mp4` | video HEVC (H.264 no llega a ese ancho), 22 s |
| `header-3840x1646.png`, `header-5244x2950.png` | imagen fija, por si la sección solo acepta imágenes |

Se regeneran pasando el tamaño (y `.png` para la imagen fija):
```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift tools/make-preview.swift \
    appstore/preview/frames appstore/preview/header-3840x1646.mp4 3840x1646
```

## Video para el revisor

Graba la pantalla del iPhone y la tele a la vez (con otro teléfono, por ejemplo): buscar la tele,
el PIN, el D-pad moviendo el menú, el volumen y abrir YouTube. Súbelo a un enlace no listado
(YouTube o Drive) y pega el enlace en las notas, o adjúntalo en "Attachment".
