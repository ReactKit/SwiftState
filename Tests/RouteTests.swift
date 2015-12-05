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
        let route = Route<MyState, NoEvent>(transition: .State0 => .State1, condition: nil)
        XCTAssertEqual(route.transition.fromState.value, MyState.State0)
        XCTAssertEqual(route.transition.toState.value, MyState.State1)
        XCTAssertTrue(route.condition == nil)
        
        let route2 = Route<MyState, NoEvent>(transition: .State1 => .State2, condition: { _ in false })
        XCTAssertEqual(route2.transition.fromState.value, MyState.State1)
        XCTAssertEqual(route2.transition.toState.value, MyState.State2)
        XCTAssertTrue(route2.condition != nil)
        
        let route3 = Route<MyState, NoEvent>(transition: .State2 => .State3, condition: { context in false })
        XCTAssertEqual(route3.transition.fromState.value, MyState.State2)
        XCTAssertEqual(route3.transition.toState.value, MyState.State3)
        XCTAssertTrue(route3.condition != nil)
    }
}