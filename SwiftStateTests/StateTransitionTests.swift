//
//  StateTransitionTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateTransitionTests: _TestCase
{
    func testInit()
    {
        let transition = StateTransition<MyState>(fromState: .State0, toState: .State1)
        XCTAssertEqual(transition.fromState, MyState.State0)
        XCTAssertEqual(transition.toState, MyState.State1)
        
        // shorthand
        let transition2 = MyState.State1 => .State0
        XCTAssertEqual(transition2.fromState, MyState.State1)
        XCTAssertEqual(transition2.toState, MyState.State0)
    }
    
    func testNil()
    {
        // nil => state
        let transition = nil => MyState.State0
        XCTAssertEqual(transition.fromState, nil as MyState)
        XCTAssertEqual(transition.toState, MyState.State0)
        
        // state => nil
        let transition2 = MyState.State0 => nil
        XCTAssertEqual(transition2.fromState, MyState.State0)
        XCTAssertEqual(transition2.toState, nil as MyState)
        
        // nil => nil
        let transition3: StateTransition<MyState> = nil => nil
        XCTAssertEqual(transition3.fromState, nil as MyState)
        XCTAssertEqual(transition3.toState, nil as MyState)
    }
}