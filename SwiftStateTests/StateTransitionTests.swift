//
//  TransitionTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class TransitionTests: _TestCase
{
    func testInit()
    {
        let transition = Transition<MyState>(fromState: .State0, toState: .State1)
        XCTAssertEqual(transition.fromState.value, MyState.State0)
        XCTAssertEqual(transition.toState.value, MyState.State1)
        
        // shorthand
        let transition2 = MyState.State1 => .State0
        XCTAssertEqual(transition2.fromState.value, MyState.State1)
        XCTAssertEqual(transition2.toState.value, MyState.State0)
    }
    
    func testNil()
    {
        // .Any => state
        let transition = .Any => MyState.State0
        XCTAssertTrue(transition.fromState == .Any)
        XCTAssertTrue(transition.toState == .State0)
        
        // state => .Any
        let transition2 = MyState.State0 => .Any
        XCTAssertTrue(transition2.fromState == .State0)
        XCTAssertTrue(transition2.toState == .Any)
        
        // .Any => .Any
        let transition3: Transition<MyState> = .Any => .Any
        XCTAssertTrue(transition3.fromState == .Any)
        XCTAssertTrue(transition3.toState == .Any)
    }
}