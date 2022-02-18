// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BQSwiftTool",
    products: [
        .library(
            name: "BQFoundationTool",
            targets: ["BQFoundationTool"]),
        .library(
            name: "BQAllTools",
            targets: ["BQSwiftTools"])
    ],
    
    dependencies: [ ],
    
    targets: [
        .target(
            name: "BQFoundationTool",
            dependencies: []
        ),
        .target(
            name: "BQSwiftTools",
            dependencies: ["BQFoundationTool"]
        ),
        .testTarget(
            name: "BQSwiftToolsTests",
            dependencies: ["BQSwiftTools"],
            resources: [.copy("directs.txt")]
        )
    ]
)
