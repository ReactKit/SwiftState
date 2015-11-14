//
//  BugFixTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015/03/07.
//  Copyright (c) 2015年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class BugFixTests: _TestCase
{
    // Fix hasRoute() bug when there are routes for both AnyEvent & SomeEvent.
    // https://github.com/ReactKit/SwiftState/pull/19
    func testHasRoute_anyEvent_someEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        machine.addRoute(.State0 => .State1)
        machine.addRouteEvent(.Event0, transitions: [.State1 => .State2])
        
        let hasRoute = machine.hasRoute(.State1 => .State2, forEvent: .Event0)
        XCTAssertTrue(hasRoute)
    }
}