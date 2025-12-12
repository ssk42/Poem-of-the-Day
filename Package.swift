// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Poem-of-the-Day",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Poem_of_the_Day", targets: ["Poem_of_the_Day"]),
        .library(name: "Poem_of_the_Day_Widget", targets: ["Poem_of_the_Day_Widget"])
    ],
    targets: [
        .target(
            name: "Poem_of_the_Day",
            path: "Poem of the Day",
            exclude: ["Poem of the Day.entitlements"],
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content")
            ]
        ),
        .target(
            name: "Poem_of_the_Day_Widget",
            dependencies: ["Poem_of_the_Day"],
            path: "Poem of the Day Widget",
            exclude: ["Info.plist"],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "Poem_of_the_DayTests",
            dependencies: ["Poem_of_the_Day"],
            path: "Poem of the DayTests"
        )
    ]
)

#if canImport(Darwin)
package.targets.append(
    .testTarget(
        name: "Poem_of_the_DayUITests",
        dependencies: [],
        path: "Poem of the DayUITests"
    )
)
#endif
