//
//  Package.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "SwiftState"
    name: "SwiftState",
    platforms: [.iOS(.v11),.watchOS(*)],
    products: [
       .library(name: "SwiftState", targets: ["SwiftState"])
    ],
    targets: [
       .target(name: "SwiftState", path: "Sources")
    ]
)
