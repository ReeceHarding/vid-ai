// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIVideoEditor",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AIVideoEditor",
            targets: ["AIVideoEditor"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.21.0")
    ],
    targets: [
        .target(
            name: "AIVideoEditor",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "AIVideoEditorTests",
            dependencies: ["AIVideoEditor"]
        )
    ]
)
