// Genera los videos de la ficha de la App Store a partir de las capturas reales de la app
// (las saca tools/capture-preview.sh), con textos, toques y transiciones encima:
//   • App Preview, vertical 886×1920 (el valor por defecto).
//   • Encabezado horizontal (5244×2950 o 3840×1646): teléfono a la derecha, textos a la izquierda.
// 30 fps + pista de audio AAC en silencio (App Store Connect rechaza videos sin audio).
// H.264, o HEVC si mide más de 4096 de ancho (H.264 no llega a ese tamaño).
// Si la salida termina en .png saca un solo fotograma fijo (el control, a los 9 s, antes del primer toque).
// Sin dependencias: CoreGraphics + CoreText + AVFoundation.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift tools/make-preview.swift \
//       [frames] [salida.mp4|.png] [ANCHOxALTO]
import AVFoundation
import CoreGraphics
import CoreText
import Foundation
import ImageIO

let args = CommandLine.arguments
let framesDir = URL(fileURLWithPath: args.count > 1 ? args[1] : "appstore/preview/frames")
let outURL = URL(fileURLWithPath: args.count > 2 ? args[2] : "appstore/preview/preview.mp4")
let iconURL = URL(fileURLWithPath: "HisenseRemote/HisenseRemote/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let size = (args.count > 3 ? args[3] : "886x1920").split(separator: "x").compactMap { Int($0) }
guard size.count == 2 else { fatalError("el tamaño va como ANCHOxALTO, por ejemplo 3840x1646") }

let width = size[0], height = size[1], fps: Int32 = 30
let landscape = width > height
let duration = 22.0
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

func load(_ url: URL) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("no pude leer \(url.path)") }
    return img
}
func frame(_ name: String) -> CGImage { load(framesDir.appendingPathComponent(name)) }

// MARK: - Guion
// Tiempos en segundos. Las coordenadas de los toques son píxeles de la captura
// (1320×2868, origen arriba a la izquierda), medidos sobre 03-remote-v18.png.
let up = CGPoint(x: 659, y: 649), right = CGPoint(x: 924, y: 898), ok = CGPoint(x: 659, y: 898)
let volPlus = CGPoint(x: 1075, y: 1594), youtube = CGPoint(x: 244, y: 2448)

struct Shot { let start: Double; let image: CGImage; var fade = 0.35 }   // qué captura se ve desde `start`
struct Caption { let start: Double; let end: Double; let text: String }
struct Tap { let time: Double; let at: CGPoint }

let remote = frame("03-remote-v18.png")
let shots = [
    Shot(start: 0, image: frame("01-scan.png")),
    Shot(start: 5.5, image: frame("02-pin.png")),
    Shot(start: 8.5, image: remote),
    Shot(start: 13.85, image: frame("04-remote-v19.png"), fade: 0.06),   // el número sube justo tras el toque
    Shot(start: 14.85, image: frame("05-remote-v20.png"), fade: 0.06),
    Shot(start: 16, image: remote, fade: 0.06),
]
let captions = [
    Caption(start: 2.6, end: 5.5, text: "La encuentra sola\nen tu WiFi"),
    Caption(start: 5.5, end: 8.5, text: "Empareja una vez\ncon el PIN de la tele"),
    Caption(start: 8.5, end: 13, text: "Navega los menús\ncon el D-pad"),
    Caption(start: 13, end: 16, text: "Volumen en vivo,\nel real de tu tele"),
    Caption(start: 16, end: 19.4, text: "Abre tus apps\ncon un toque"),
] + (landscape ? [   // el horizontal no tiene pantallas de entrada y salida: el ícono está siempre
    Caption(start: 0, end: 2.6, text: "Tu tele Hisense,\ndesde el iPhone"),
    Caption(start: 19.4, end: 22, text: "Gratis y\nsin anuncios"),
] : [])
let taps = [
    Tap(time: 9.6, at: up), Tap(time: 10.5, at: right), Tap(time: 11.4, at: right), Tap(time: 12.3, at: ok),
    Tap(time: 13.75, at: volPlus), Tap(time: 14.75, at: volPlus),
    Tap(time: 17.4, at: youtube),
]
let phoneIn = 2.2, phoneOut = 19.4

// MARK: - Dibujo
func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
func ease(_ x: Double) -> CGFloat { let t = clamp(x); return CGFloat(t * t * (3 - 2 * t)) }

// Texto centrado en `cx` (por defecto, el centro); `\n` separa renglones. `top` es la línea base del primer renglón.
func text(_ ctx: CGContext, _ s: String, size: CGFloat, bold: Bool, top: CGFloat, alpha: CGFloat,
          cx: CGFloat = CGFloat(width) / 2) {
    let base = CTFontCreateUIFontForLanguage(bold ? .emphasizedSystem : .system, size, nil)!
    let attrs = [kCTFontAttributeName: base, kCTForegroundColorAttributeName: rgb(1, 1, 1)] as CFDictionary
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.setShadow(offset: CGSize(width: 0, height: -3), blur: 12, color: rgb(0, 0, 0, 0.25))
    for (i, lineText) in s.split(separator: "\n").enumerated() {
        let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, String(lineText) as CFString, attrs))
        let w = CTLineGetTypographicBounds(line, nil, nil, nil)
        ctx.textPosition = CGPoint(x: cx - CGFloat(w) / 2, y: top - CGFloat(i) * size * 1.2)
        CTLineDraw(line, ctx)
    }
    ctx.restoreGState()
}

// El fondo es el degradado del ícono, que se mueve despacio para que no se vea estático.
func background(_ ctx: CGContext, _ t: Double) {
    let g = CGGradient(colorsSpace: space, colors: [rgb(0.23, 0.51, 0.98), rgb(0.33, 0.24, 0.86)] as CFArray,
                       locations: [0, 1])!
    let s = CGFloat(sin(t * 0.4)) * 200
    ctx.drawLinearGradient(g, start: CGPoint(x: s, y: CGFloat(height)), end: CGPoint(x: CGFloat(width) - s, y: 0),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func icon(_ ctx: CGContext, _ img: CGImage, center: CGPoint, size: CGFloat, alpha: CGFloat) {
    let r = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: rgb(0, 0, 0, 0.35))
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: size * 0.2237, cornerHeight: size * 0.2237, transform: nil))
    ctx.fillPath()   // la sombra va en una capa aparte del recorte
    ctx.restoreGState()
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: size * 0.2237, cornerHeight: size * 0.2237, transform: nil))
    ctx.clip()
    ctx.draw(img, in: r)
    ctx.restoreGState()
}

// Teléfono con bisel negro. Vertical: 620 px de ancho, debajo del encabezado.
// Horizontal: ocupa el 86 % del alto, a la derecha. `k` escala bisel, sombras y toques.
let screenH: CGFloat = landscape ? CGFloat(height) * 0.86 : 2868 * 620 / 1320
let screenW = screenH * 1320 / 2868
let screenScale = screenW / 1320
let k = screenW / 620
let bezel = 16 * k
let screenRest = landscape
    ? CGRect(x: CGFloat(width) * 0.70 - screenW / 2, y: (CGFloat(height) - screenH) / 2, width: screenW, height: screenH)
    : CGRect(x: (CGFloat(width) - screenW) / 2, y: 141 + bezel, width: screenW, height: screenH)

func shot(at t: Double) -> (current: CGImage, previous: CGImage?, mix: CGFloat) {
    let i = shots.lastIndex { $0.start <= t } ?? 0
    let mix = ease((t - shots[i].start) / shots[i].fade)   // fundido entre capturas
    return (shots[i].image, i > 0 ? shots[i - 1].image : nil, mix)
}

func phone(_ ctx: CGContext, _ t: Double, offsetY: CGFloat, alpha: CGFloat) {
    let screen = screenRest.offsetBy(dx: 0, dy: offsetY)
    let body = screen.insetBy(dx: -bezel, dy: -bezel)
    let radius = screenW * 0.125
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -24 * k), blur: 60 * k, color: rgb(0, 0, 0, 0.45))
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: radius + bezel, cornerHeight: radius + bezel, transform: nil))
    ctx.setFillColor(rgb(0.06, 0.06, 0.07)); ctx.fillPath()
    ctx.restoreGState()
    ctx.addPath(CGPath(roundedRect: body.insetBy(dx: 1.5 * k, dy: 1.5 * k), cornerWidth: radius + bezel - 1.5 * k,
                       cornerHeight: radius + bezel - 1.5 * k, transform: nil))
    ctx.setStrokeColor(rgb(1, 1, 1, 0.18)); ctx.setLineWidth(3 * k); ctx.strokePath()

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: screen, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.clip()
    let s = shot(at: t)
    if let prev = s.previous, s.mix < 1 { ctx.draw(prev, in: screen) }
    ctx.setAlpha(s.mix); ctx.draw(s.current, in: screen); ctx.setAlpha(1)

    // Toques: un dedo que baja (punto) y una onda que se abre al soltar.
    for tap in taps {
        let dt = t - tap.time
        guard dt > -0.25, dt < 0.6 else { continue }
        let p = CGPoint(x: screen.minX + tap.at.x * screenScale, y: screen.maxY - tap.at.y * screenScale)
        if dt < 0.15 {
            let a = dt < 0 ? ease((dt + 0.25) / 0.25) : 1 - ease(dt / 0.15)
            ctx.setFillColor(rgb(1, 1, 1, 0.45 * a))
            ctx.fillEllipse(in: CGRect(x: p.x - 26 * k, y: p.y - 26 * k, width: 52 * k, height: 52 * k))
        }
        if dt >= 0 {
            let e = ease(dt / 0.6), r = (22 + 46 * e) * k
            ctx.setStrokeColor(rgb(1, 1, 1, 0.8 * (1 - e))); ctx.setLineWidth(4 * k)
            ctx.strokeEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
        }
    }
    ctx.restoreGState()
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

let iconImage = load(iconURL)

// Encabezado horizontal: ícono y nombre fijos a la izquierda, la frase cambia debajo,
// y el teléfono siempre a la derecha (así se puede repetir en bucle).
func renderLandscape(_ ctx: CGContext, _ t: Double) {
    background(ctx, t)
    let H = CGFloat(height), cx = CGFloat(width) * 0.33
    icon(ctx, iconImage, center: CGPoint(x: cx, y: H * 0.72), size: H * 0.2, alpha: 1)
    text(ctx, "HisenseRemote", size: H * 0.065, bold: true, top: H * 0.53, alpha: 1, cx: cx)
    for c in captions where t >= c.start && t < c.end {
        let a = ease((t - c.start) / 0.35) * (1 - ease((t - c.end + 0.3) / 0.3))
        let rise = H * 0.02 * (1 - ease((t - c.start) / 0.45))
        text(ctx, c.text, size: H * 0.075, bold: false, top: H * 0.38 - rise, alpha: a, cx: cx)
    }
    phone(ctx, t, offsetY: 0, alpha: 1)
}

func render(_ ctx: CGContext, _ t: Double) {
    if landscape { renderLandscape(ctx, t); return }
    background(ctx, t)
    let H = CGFloat(height), mid = CGFloat(width) / 2

    // Entrada: ícono + nombre, se va al llegar el teléfono.
    if t < 2.6 {
        let a = ease(t / 0.5) * (1 - ease((t - 2.1) / 0.5))
        icon(ctx, iconImage, center: CGPoint(x: mid, y: H * 0.6), size: 300 * (0.85 + 0.15 * ease(t / 0.7)), alpha: a)
        text(ctx, "HisenseRemote", size: 78, bold: true, top: H * 0.6 - 280, alpha: a)
        text(ctx, "Tu tele Hisense,\ndesde el iPhone", size: 50, bold: false, top: H * 0.6 - 380, alpha: a * 0.9)
    }
    // Salida: el mismo ícono con el cierre.
    if t > phoneOut + 0.3 {
        let a = ease((t - phoneOut - 0.3) / 0.5)
        icon(ctx, iconImage, center: CGPoint(x: mid, y: H * 0.6), size: 300 * (0.85 + 0.15 * a), alpha: a)
        text(ctx, "HisenseRemote", size: 78, bold: true, top: H * 0.6 - 280, alpha: a)
        text(ctx, "Gratis y sin anuncios", size: 50, bold: false, top: H * 0.6 - 380, alpha: a * 0.9)
    }

    // El teléfono sube desde abajo, y al final baja.
    if t > phoneIn && t < phoneOut + 0.7 {
        let inK = ease((t - phoneIn) / 0.8), outK = ease((t - phoneOut) / 0.6)
        phone(ctx, t, offsetY: -1500 * (1 - inK) - 1500 * outK, alpha: 1)
    }

    // Encabezado: cada frase entra subiendo y se desvanece al final.
    for c in captions where t >= c.start && t < c.end {
        let a = ease((t - c.start) / 0.35) * (1 - ease((t - c.end + 0.3) / 0.3))
        let rise = 30 * (1 - ease((t - c.start) / 0.45))
        text(ctx, c.text, size: 62, bold: true, top: H - 170 - rise, alpha: a)
    }
}

func context(_ data: UnsafeMutableRawPointer?, bytesPerRow: Int) -> CGContext {
    let ctx = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                        space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    ctx.interpolationQuality = .high
    return ctx
}

try? FileManager.default.removeItem(at: outURL)
try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)

// MARK: - Imagen fija
if outURL.pathExtension.lowercased() == "png" {
    let ctx = context(nil, bytesPerRow: 0)
    render(ctx, 9.0)
    let dest = CGImageDestinationCreateWithURL(outURL as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("no se pudo escribir \(outURL.path)") }
    print("✓ \(outURL.path)")
    exit(0)
}

// MARK: - Video
let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)

let video = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: width > 4096 ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
    AVVideoWidthKey: width, AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        // 10 Mbps para el App Preview (lo que pide Apple); más para los tamaños grandes.
        AVVideoAverageBitRateKey: min(40_000_000, 10_000_000 * width * height / (886 * 1920)),
        AVVideoExpectedSourceFrameRateKey: fps, AVVideoMaxKeyFrameIntervalKey: fps,
    ].merging(width > 4096 ? [:] : [AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]) { a, _ in a },
])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: video, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
])
let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: [
    AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44_100, AVNumberOfChannelsKey: 2,
    AVEncoderBitRateKey: 256_000,
])
writer.add(video); writer.add(audio)
guard writer.startWriting() else { fatalError("AVAssetWriter: \(writer.error?.localizedDescription ?? "?")") }
writer.startSession(atSourceTime: .zero)

// Audio en silencio: bloques de 0.1 s de PCM 16 bits estéreo en ceros; AVAssetWriter lo pasa a AAC.
let rate = 44_100, chunk = 4_410
var asbd = AudioStreamBasicDescription(mSampleRate: Double(rate), mFormatID: kAudioFormatLinearPCM,
    mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
    mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 2, mBitsPerChannel: 16,
    mReserved: 0)
var pcmFormat: CMAudioFormatDescription?
CMAudioFormatDescriptionCreate(allocator: nil, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0,
                               magicCookie: nil, extensions: nil, formatDescriptionOut: &pcmFormat)

func silence(from sample: Int) -> CMSampleBuffer {
    var block: CMBlockBuffer?
    CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: chunk * 4,
        blockAllocator: kCFAllocatorDefault, customBlockSource: nil, offsetToData: 0, dataLength: chunk * 4,
        flags: kCMBlockBufferAssureMemoryNowFlag, blockBufferOut: &block)
    CMBlockBufferFillDataBytes(with: 0, blockBuffer: block!, offsetIntoDestination: 0, dataLength: chunk * 4)
    var buf: CMSampleBuffer?
    CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: block!,
        formatDescription: pcmFormat!, sampleCount: chunk,
        presentationTimeStamp: CMTime(value: CMTimeValue(sample), timescale: CMTimeScale(rate)),
        packetDescriptions: nil, sampleBufferOut: &buf)
    return buf!
}

// Cada pista se alimenta sola cuando el escritor la pide (así él decide cómo
// intercalarlas; empujar las dos desde un mismo ciclo se puede trabar).
let totalFrames = Int(duration * Double(fps))
let totalSamples = Int(duration) * rate
let done = DispatchGroup()

func videoFrame(_ n: Int) -> CVPixelBuffer {
    let t = Double(n) / Double(fps)
    var pb: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
    let buffer = pb!
    CVPixelBufferLockBaseAddress(buffer, [])
    render(context(CVPixelBufferGetBaseAddress(buffer), bytesPerRow: CVPixelBufferGetBytesPerRow(buffer)), t)
    CVPixelBufferUnlockBaseAddress(buffer, [])
    return buffer
}

var frameN = 0
done.enter()
video.requestMediaDataWhenReady(on: DispatchQueue(label: "video")) {
    while video.isReadyForMoreMediaData {
        if frameN == totalFrames { video.markAsFinished(); done.leave(); return }
        adaptor.append(videoFrame(frameN), withPresentationTime: CMTime(value: CMTimeValue(frameN), timescale: fps))
        if frameN % Int(fps) == 0 { print("  \(frameN / Int(fps)) s") }
        frameN += 1
    }
}

var audioSample = 0
done.enter()
audio.requestMediaDataWhenReady(on: DispatchQueue(label: "audio")) {
    while audio.isReadyForMoreMediaData {
        if audioSample >= totalSamples { audio.markAsFinished(); done.leave(); return }
        audio.append(silence(from: audioSample)); audioSample += chunk
    }
}

done.wait()
let finished = DispatchSemaphore(value: 0)
writer.finishWriting { finished.signal() }
finished.wait()
guard writer.status == .completed else { fatalError("no se pudo escribir: \(writer.error?.localizedDescription ?? "?")") }
print("✓ \(outURL.path)")
