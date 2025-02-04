// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIVideoEditor",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AIVideoEditorApp",
            targets: ["AIVideoEditorApp"]
        ),
        .library(
            name: "AIVideoEditorLib",
            targets: ["AIVideoEditorLib"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "10.29.0")
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            .upToNextMajor(from: "5.10.2")
        ),
        .package(
            url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "AIVideoEditorApp",
            dependencies: [
                "AIVideoEditorLib",
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "Sources/AIVideoEditorApp",
            resources: [
                .copy("Resources")
            ]
        ),
        .target(
            name: "AIVideoEditorLib",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/AIVideoEditorLib",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AIVideoEditorTests",
            dependencies: [
                "AIVideoEditorLib",
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "Tests/AIVideoEditorTests"
        ),
        .testTarget(
            name: "AIVideoEditorUITests",
            dependencies: [
                "AIVideoEditorApp",
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
            ],
            path: "Tests/AIVideoEditorUITests",
            resources: [
                .process("Resources")
            ]
        )
    ]
) 