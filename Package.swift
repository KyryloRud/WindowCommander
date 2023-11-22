// swift-tools-version: 5.9

import PackageDescription

let package = Package(
   name: "WindowCommander",
   platforms: [
      .macOS(.v13),
      .iOS(.v17) // Note: package is not supported by iOS, this line is required just to solve warnings
   ],
   products: [
      .library(
         name: "WindowCommander",
         targets: ["WindowCommander"]),
   ],
   targets: [
      .target(
         name: "WindowCommander"),
      .testTarget(
         name: "WindowCommanderTests",
         dependencies: ["WindowCommander"]),
   ]
)
