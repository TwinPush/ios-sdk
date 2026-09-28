// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TwinPushSDK",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "TwinPushSDK", targets: ["TwinPushSDK"])
    ],
    targets: [
        .target(
            name: "TwinPushSDK",
            path: "TwinPushSDK",
            exclude: ["TwinPushSDK-Prefix.pch"],
            sources: ["Classes", "ViewControllers"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Classes"),
                .headerSearchPath("Classes/Communications/Pinning"),
                .define("DEBUG", .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("MobileCoreServices"),
                .linkedFramework("CFNetwork"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("Security"),
                .linkedFramework("WebKit"),
                .linkedLibrary("z")
            ]
        )
    ]
)
