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
| Precio | Gratis |
| URL de privacidad | `https://github.com/msucedo/Hisense-Remote-ios/blob/main/PRIVACY.md` |
| URL de soporte | `https://github.com/msucedo/Hisense-Remote-ios` |

> El repo debe ser **público** para que esas URLs abran. Si lo quieres privado,
> publica `PRIVACY.md` en otro lado (GitHub Pages, un Gist público, etc.) y usa esa URL.

## Texto promocional (170)

```
Controla tu tele Hisense VIDAA desde el iPhone por WiFi: D-pad, volumen en vivo, fuentes y tus apps a un toque.
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
• Abrir tus apps directamente: YouTube, Netflix y las demás que tenga tu tele

Privacidad: la app solo habla con tu tele dentro de tu red local. No recolecta datos, no tiene anuncios y no envía nada a internet.

Requisitos: un televisor Hisense con sistema VIDAA conectado al mismo WiFi que tu iPhone.
```

## Palabras clave (100)

```
hisense,vidaa,control,remoto,tv,tele,televisor,wifi,smart tv,mando,volumen
```

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

The developer is authorized by Hisense to use the Hisense name and the client certificate used to connect to the TV. Documentation can be provided on request.
```

> Ajusta el último párrafo para que diga exactamente qué permiso tienes; si Apple lo pide,
> tendrás que mostrar el documento. Sin login, deja vacíos los campos de "Sign-in required".

## Capturas de pantalla

- Obligatorias: **iPhone 6.9"** (1320×2868, por ejemplo iPhone 16 Pro Max) **o 6.5"** (1284×2778).
  Si tu iPhone es de otro tamaño, App Store Connect acepta capturas de 6.9" y las escala a los demás.
- Sugeridas (3 a 5): buscando la tele / pantalla del PIN / control con el D-pad / sección de Apps.
- No pongas el PIN real de tu tele visible si no quieres.

## Video para el revisor

Graba la pantalla del iPhone y la tele a la vez (con otro teléfono, por ejemplo): buscar la tele,
el PIN, el D-pad moviendo el menú, el volumen y abrir YouTube. Súbelo a un enlace no listado
(YouTube o Drive) y pega el enlace en las notas, o adjúntalo en "Attachment".
