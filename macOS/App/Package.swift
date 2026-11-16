// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WhisperStudio",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "WhisperStudio", targets: ["WhisperStudio"])
    ],
    targets: [
        .executableTarget(
            name: "WhisperStudio",
            path: "Sources",
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        )
    ]
)
