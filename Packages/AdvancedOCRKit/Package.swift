// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AdvancedOCRKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "OCRDomain", targets: ["OCRDomain"]),
        .library(name: "OCRData", targets: ["OCRData"]),
        .library(name: "OCRPresentation", targets: ["OCRPresentation"])
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: []
        ),
        .target(
            name: "OCRDomain",
            dependencies: ["Core"]
        ),
        .target(
            name: "OCRData",
            dependencies: ["Core", "OCRDomain"]
        ),
        .target(
            name: "OCRPresentation",
            dependencies: ["Core", "OCRDomain"]
        ),
        .testTarget(
            name: "OCRDomainTests",
            dependencies: ["OCRDomain"]
        )
    ]
)
