// Genera el ícono de la app (1024×1024, sin transparencia) en sus tres variantes de iOS 18:
// claro, oscuro y tintado. Sin dependencias: CoreGraphics + ImageIO.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift tools/make-icon.swift <carpeta>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

struct Palette {
    var background: [CGColor]   // degradado de arriba hacia abajo
    var body: [CGColor]         // degradado del control
    var ring: CGColor           // aro del D-pad
    var ok: CGColor             // botón central
    var detail: CGColor         // flechas y botones chicos
    var power: CGColor
}

let light = Palette(
    background: [rgb(0.23, 0.51, 0.98), rgb(0.33, 0.24, 0.86)],
    body: [rgb(1, 1, 1), rgb(0.90, 0.92, 0.96)],
    ring: rgb(0.13, 0.15, 0.20), ok: rgb(0.23, 0.51, 0.98),
    detail: rgb(0.80, 0.83, 0.90), power: rgb(0.95, 0.27, 0.30))

let dark = Palette(
    background: [rgb(0.08, 0.09, 0.12), rgb(0.03, 0.04, 0.05)],
    body: [rgb(0.30, 0.58, 1.00), rgb(0.38, 0.30, 0.92)],
    ring: rgb(0.07, 0.08, 0.11), ok: rgb(0.35, 0.62, 1.00),
    detail: rgb(1, 1, 1, 0.35), power: rgb(1.00, 0.40, 0.42))

// El tintado va en grises sobre negro: iOS lo colorea con el tono que elija el usuario.
let tinted = Palette(
    background: [rgb(0, 0, 0), rgb(0, 0, 0)],
    body: [rgb(0.95, 0.95, 0.95), rgb(0.75, 0.75, 0.75)],
    ring: rgb(0.18, 0.18, 0.18), ok: rgb(0.85, 0.85, 0.85),
    detail: rgb(0.45, 0.45, 0.45), power: rgb(0.55, 0.55, 0.55))

func gradient(_ ctx: CGContext, _ colors: [CGColor], from: CGPoint, to: CGPoint) {
    let g = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func circle(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
}

func triangle(_ ctx: CGContext, center c: CGPoint, size s: CGFloat, angle: CGFloat, _ color: CGColor) {
    ctx.saveGState()
    ctx.translateBy(x: c.x, y: c.y)
    ctx.rotate(by: angle)
    ctx.move(to: CGPoint(x: 0, y: s * 0.6))
    ctx.addLine(to: CGPoint(x: -s * 0.6, y: -s * 0.3))
    ctx.addLine(to: CGPoint(x: s * 0.6, y: -s * 0.3))
    ctx.closePath()
    ctx.setFillColor(color)
    ctx.fillPath()
    ctx.restoreGState()
}

func draw(_ p: Palette) -> CGImage {
    // Sin canal alfa: la App Store rechaza íconos con transparencia.
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let S = CGFloat(size)
    gradient(ctx, p.background, from: CGPoint(x: 0, y: S), to: CGPoint(x: S, y: 0))

    // Cuerpo del control (el origen de CoreGraphics está abajo a la izquierda).
    let body = CGRect(x: 322, y: 120, width: 380, height: 784)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 150, cornerHeight: 150, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 50, color: rgb(0, 0, 0, 0.35))
    ctx.addPath(bodyPath); ctx.setFillColor(p.body[0]); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(bodyPath); ctx.clip()
    gradient(ctx, p.body, from: CGPoint(x: 0, y: body.maxY), to: CGPoint(x: 0, y: body.minY))
    ctx.restoreGState()

    // Botón de encendido.
    circle(ctx, CGPoint(x: 512, y: 812), 34, p.power)

    // D-pad: aro oscuro, flechas y OK.
    let pad = CGPoint(x: 512, y: 590)
    circle(ctx, pad, 150, p.ring)
    for a in [0, CGFloat.pi / 2, CGFloat.pi, 3 * CGFloat.pi / 2] {
        let d: CGFloat = 112
        let c = CGPoint(x: pad.x - sin(a) * d, y: pad.y + cos(a) * d)
        triangle(ctx, center: c, size: 30, angle: a, p.detail)
    }
    circle(ctx, pad, 66, p.ok)

    // Dos filas de botones chicos (volumen / canales).
    for y in [370, 250] as [CGFloat] {
        for x in [440, 584] as [CGFloat] {
            circle(ctx, CGPoint(x: x, y: y), 40, p.detail)
        }
    }
    return ctx.makeImage()!
}

func save(_ img: CGImage, _ url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("no se pudo escribir \(url.path)") }
    print("✓ \(url.lastPathComponent)")
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
save(draw(light), out.appendingPathComponent("AppIcon.png"))
save(draw(dark), out.appendingPathComponent("AppIcon-dark.png"))
save(draw(tinted), out.appendingPathComponent("AppIcon-tinted.png"))
