# HisenseRemote

Control remoto iPhone app para televisores **Hisense VIDAA**a travez de WiFi.
Abres la app, encuentra tu tele en la red, la emparejas con un PIN una sola vez y listo:
D-pad, volumen en vivo, encender/apagar, cambiar de fuente y botones directos a aplicaciónes.


## Cómo funciona

La tele escucha en el puerto `36669` un broker MQTT sobre TLS (el mismo que usa
la app oficial RemoteNOW). El firmware moderno pide tres cosas:

- un **certificado de cliente** (mutual TLS);
- **credenciales derivadas** de la hora y una MAC en cada conexión;
- un **emparejamiento por PIN** que entrega un token de larga duración.

El cliente MQTT está escrito a mano. Para el TLS se usa **SwiftNIO + NIOSSL**:
el TLS de Apple (Network.framework) rechaza el handshake de estas teles de forma
intermitente, y NIOSSL (BoringSSL) lo acepta igual que OpenSSL.

| Parte | Qué hace |
|---|---|
| `HisenseKit/` | El núcleo `RemoteKit` (paquete Swift): cripto, MQTT, comandos de la tele y descubrimiento en la red. |
| `HisenseRemote/` | La app SwiftUI para iPhone (proyecto de Xcode). |
| `cli/` | `hisensectl`, una herramienta de terminal para probar el núcleo desde la Mac. |

## Requisitos

- Xcode 16 con la plataforma iOS instalada, y un iPhone con iOS 18.
- Una Apple ID para firmar (la gratuita sirve; la app caduca a los ~7 días y se renueva corriéndola de nuevo).
- El iPhone y la tele en el mismo WiFi.

## Puesta en marcha

### El certificado de cliente

El firmware exige el certificado que viene dentro de la app oficial de Hisense.
**No se incluye en este repositorio.** Si tienes el `.p12` de la app, cópialo
como `HisenseRemote/HisenseRemote/client.p12` (junto a los `.swift`; si queda
en otra carpeta, Xcode no lo mete en la app). `*.p12` está en `.gitignore`.

### Correr la app

1. Abre `HisenseRemote/HisenseRemote.xcodeproj` en Xcode.
2. En **Signing & Capabilities** elige tu Team (tu Apple ID).
3. Conecta el iPhone, selecciónalo como destino y dale **Run**.
4. Acepta el permiso de **Red local**. Con la app oficial RemoteNOW cerrada,
   escribe el PIN que muestra la tele.

### Probar desde la terminal

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
.build/debug/hisensectl scan                    # encuentra la tele
.build/debug/hisensectl ping <ip>               # comprueba la conexión
.build/debug/hisensectl pair <ip>               # empareja con el PIN
.build/debug/hisensectl cmd <ip> app YouTube    # abre YouTube
```

## Lo que viene

La arquitectura está pensada para un control universal: más adelante entrarán
Samsung y Sony como drivers aparte. El plan está en [`ROADMAP.md`](ROADMAP.md).

## Nota

El certificado es propiedad de Hisense; ni el certificado ni la app
oficial se incluyen aquí. Los tokens de emparejamiento quedan en el teléfono
(o en `cli.token.json`, ignorado por git).

## Licencia

MIT — ver [LICENSE](LICENSE).
