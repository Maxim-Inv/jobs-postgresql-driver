// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "JobsPostgreSQLDriver",
  platforms: [
       .macOS(.v10_14)
    ],
  products: [
    .library(
      name: "JobsPostgreSQLDriver",
      targets: ["JobsPostgreSQLDriver"]),
    ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.10"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta.2.4"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-beta.2.3"),
    .package(url: "https://github.com/vapor-community/jobs.git", from: "1.0.0-beta.3"),
  ],
  targets: [
    .target(
      name: "JobsPostgreSQLDriver",
      dependencies: ["Vapor", "Jobs", "FluentPostgresDriver", "Fluent"]),
    .testTarget(
      name: "JobsPostgreSQLDriverTests",
      dependencies: ["JobsPostgreSQLDriver"]),
    ]
)

