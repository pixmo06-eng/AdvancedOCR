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
        .library(name: "OCRPresentation", targets: ["OCRPresentation"]),
        .library(name: "JapaneseLearningDomain", targets: ["JapaneseLearningDomain"]),
        .library(name: "JapaneseLearningData", targets: ["JapaneseLearningData"]),
        .library(name: "JapaneseLearningPresentation", targets: ["JapaneseLearningPresentation"])
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
        .target(
            name: "JapaneseLearningDomain",
            dependencies: ["Core", "OCRDomain"]
        ),
        .target(
            name: "JapaneseLearningData",
            dependencies: ["Core", "OCRDomain", "JapaneseLearningDomain"]
        ),
        .target(
            name: "JapaneseLearningPresentation",
            dependencies: ["Core", "OCRDomain", "OCRData", "JapaneseLearningDomain", "JapaneseLearningData"]
        ),
        .testTarget(
            name: "OCRDomainTests",
            dependencies: ["OCRDomain", "OCRData"]
        ),
        .testTarget(
            name: "JapaneseLearningDomainTests",
            dependencies: ["JapaneseLearningDomain"]
        ),
        .testTarget(
            name: "JapaneseLearningDataTests",
            dependencies: ["JapaneseLearningDomain", "JapaneseLearningData"]
        )
    ]
)
