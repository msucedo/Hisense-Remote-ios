// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "hisense-remote-ios",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        // La app iOS en Xcode depende de este producto (trae NIO/NIOSSL consigo).
        .library(name: "RemoteKit", targets: ["RemoteKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.26.0"),
    ],
    targets: [
        // Núcleo compartido (también se usará desde la app iOS).
        .target(
            name: "RemoteKit",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ],
            path: "HisenseKit"
        ),
        // CLI de pruebas en la Mac.
        .executableTarget(
            name: "hisensectl",
            dependencies: ["RemoteKit"],
            path: "cli"
        ),
    ]
)
