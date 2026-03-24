// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JBSConfig",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      .upToNextMinor(from: "1.7.1")
    ),
    .package(
      url: "https://github.com/swiftlang/swift-subprocess",
      .upToNextMinor(from: "0.2.1")
    ),
    .package(
      url: "https://github.com/swiftlang/swift-tools-support-core",
      .upToNextMinor(from: "0.7.3")
    )
  ],
  targets: [
    .executableTarget(
      name: "JBSConfig",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "TSCBasic", package: "swift-tools-support-core")
      ],
      resources: [.process("WallpaperChanger.applescript")]
    )
  ]
)
