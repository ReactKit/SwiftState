//
//  RouteTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class RouteTests: _TestCase
{
    func testInit()
    {
        let route = Route<MyState, NoEvent>(transition: .state0 => .state1, condition: nil)
        XCTAssertEqual(route.transition.fromState.rawValue, MyState.state0)
        XCTAssertEqual(route.transition.toState.rawValue, MyState.state1)
        XCTAssertTrue(route.condition == nil)

        let route2 = Route<MyState, NoEvent>(transition: .state1 => .state2, condition: { _ in false })
        XCTAssertEqual(route2.transition.fromState.rawValue, MyState.state1)
        XCTAssertEqual(route2.transition.toState.rawValue, MyState.state2)
        XCTAssertTrue(route2.condition != nil)

        let route3 = Route<MyState, NoEvent>(transition: .state2 => .state3, condition: { context in false })
        XCTAssertEqual(route3.transition.fromState.rawValue, MyState.state2)
        XCTAssertEqual(route3.transition.toState.rawValue, MyState.state3)
        XCTAssertTrue(route3.condition != nil)
    }
}
