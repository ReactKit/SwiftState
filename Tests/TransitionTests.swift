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
        XCTAssertEqual(transition.fromState.rawValue, MyState.State0)
        XCTAssertEqual(transition.toState.rawValue, MyState.State1)

        // shorthand
        let transition2 = MyState.State1 => .State0
        XCTAssertEqual(transition2.fromState.rawValue, MyState.State1)
        XCTAssertEqual(transition2.toState.rawValue, MyState.State0)
    }

    func testInit_fromAny()
    {
        let transition = Transition<MyState>(fromState: .Any, toState: .State1)
        XCTAssertNil(transition.fromState.rawValue)
        XCTAssertEqual(transition.toState.rawValue, MyState.State1)

        // shorthand
        let transition2 = .Any => MyState.State0
        XCTAssertNil(transition2.fromState.rawValue)
        XCTAssertEqual(transition2.toState.rawValue, MyState.State0)
    }

    func testInit_toAny()
    {
        let transition = Transition<MyState>(fromState: .State0, toState: .Any)
        XCTAssertEqual(transition.fromState.rawValue, MyState.State0)
        XCTAssertNil(transition.toState.rawValue)

        // shorthand
        let transition2 = MyState.State1 => .Any
        XCTAssertEqual(transition2.fromState.rawValue, MyState.State1)
        XCTAssertNil(transition2.toState.rawValue)
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
