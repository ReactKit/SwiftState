//
//  StateRouteTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateRouteTests: _TestCase
{
    func testInit()
    {
        let route = StateRoute<MyState>(transition: .State0 => .State1, condition: nil)
        XCTAssertEqual(route.transition.fromState, MyState.State0)
        XCTAssertEqual(route.transition.toState, MyState.State1)
        XCTAssertTrue(route.condition == nil)
        
        //
        // comment-out: 
        // `condition` using lazy-evaluated-@autoclosure is removed due to Swift 1.2 change
        //
        // From Release Note:
        // > The @autoclosure attribute on parameters now implies the new @noescape attribute.
        // > This intentionally limits the power of @autoclosure to control-flow and lazy evaluation use cases.
        //
//        let route2 = StateRoute<MyState>(transition: .State1 => .State2, condition: false)
//        XCTAssertEqual(route2.transition.fromState, MyState.State1)
//        XCTAssertEqual(route2.transition.toState, MyState.State2)
//        XCTAssertTrue(route2.condition != nil)
        
        let route3 = StateRoute<MyState>(transition: .State2 => .State3, condition: { transition in false })
        XCTAssertEqual(route3.transition.fromState, MyState.State2)
        XCTAssertEqual(route3.transition.toState, MyState.State3)
        XCTAssertTrue(route3.condition != nil)
    }
}