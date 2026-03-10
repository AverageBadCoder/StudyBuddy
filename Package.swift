// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ACSProject2",
    platforms: [
        .macOS(.v12),
        .iOS(.v13)
    ],
    products: [
        .library(name: "ACSProject2", targets: ["ACSProject2"])
    ],
    dependencies: [
        // replace "0.24.0" below with the tag you found (e.g. "0.23.0" or "v0.23.0")
        .package(url: "https://github.com/supabase-community/supabase-swift.git", .exact("2.9.0"))
    ],
    targets: [
        .target(
            name: "ACSProject2",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: ".",
            exclude: ["Package.swift", "README.md", ".git", "Passwords and Keys"]
        )
    ]
)