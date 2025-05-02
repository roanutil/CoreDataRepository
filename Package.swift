// swift-tools-version:5.10

import Foundation
import PackageDescription

let package = Package(
    name: "CoreDataRepository",
    defaultLocalization: "en",
    platforms: .shared,
    products: [
        .library(
            name: "CoreDataRepository",
            targets: ["CoreDataRepository"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-custom-dump.git",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "CoreDataRepository",
            resources: [.process("Resources")],
            swiftSettings: .swiftSix
        ),
        .testTarget(
            name: "CoreDataRepositoryTests",
            dependencies: [
                "CoreDataRepository",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                "Internal",
            ],
            swiftSettings: .swiftSix
        ),
        .target(
            name: "Internal",
            dependencies: [
                "CoreDataRepository",
            ],
            swiftSettings: .swiftSix
        ),
    ]
)

extension [SupportedPlatform] {
    static let shared: Self = if ProcessInfo.benchmarkingEnabled {
        [
            .iOS(.v15),
            .macOS(.v12),
            .tvOS(.v15),
            .watchOS(.v8),
            .macCatalyst(.v15),
            .visionOS(.v1),
        ]
    } else {
        [
            .iOS(.v15),
            .macOS(.v13),
            .tvOS(.v15),
            .watchOS(.v8),
            .macCatalyst(.v15),
            .visionOS(.v1),
        ]
    }
}

extension [SwiftSetting] {
    static let swiftSix: Self = [
        .enableUpcomingFeature("BareSlashRegexLiterals"),
        .enableUpcomingFeature("ConciseMagicFile"),
        .enableUpcomingFeature("DeprecateApplicationMain"),
        .enableUpcomingFeature("DisableOutwardActorInference"),
        .enableUpcomingFeature("ForwardTrailingClosures"),
        .enableUpcomingFeature("ImportObjcForwardDeclarations"),
        .enableUpcomingFeature("StrictConcurrency"),
    ]
}

if ProcessInfo.benchmarkingEnabled {
    package.dependencies += [
        .package(
            url: "https://github.com/ordo-one/package-benchmark.git",
            from: "1.23.5"
        ),
    ]

    // Benchmark of coredata-repository-benchmarks
    package.targets += [
        .executableTarget(
            name: "coredata-repository-benchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                "CoreDataRepository",
                "Internal",
            ],
            path: "Benchmarks/coredata-repository-benchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
}

extension ProcessInfo {
    static let benchmarkingEnabled: Bool = ["YES", "TRUE"]
        .contains((ProcessInfo.processInfo.environment["BENCHMARKS"])?.uppercased())
}
