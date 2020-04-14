// swift-tools-version:5.2

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
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-rc"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
    .package(url: "https://github.com/vapor/queues.git", from: "1.0.0-rc"),
  ],
  targets: [
    .target(name: "JobsPostgreSQLDriver", dependencies: [
		.product(name: "Vapor", package: "vapor"),
		.product(name: "Fluent", package: "fluent"),
		.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
		.product(name: "Queues", package: "queues")
	]),
    .testTarget(
      name: "JobsPostgreSQLDriverTests",
      dependencies: ["JobsPostgreSQLDriver"]),
    ]
)

