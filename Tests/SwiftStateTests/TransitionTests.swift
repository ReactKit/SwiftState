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
        let transition = Transition<MyState>(fromState: .state0, toState: .state1)
        XCTAssertEqual(transition.fromState.rawValue, MyState.state0)
        XCTAssertEqual(transition.toState.rawValue, MyState.state1)

        // shorthand
        let transition2 = MyState.state1 => .state0
        XCTAssertEqual(transition2.fromState.rawValue, MyState.state1)
        XCTAssertEqual(transition2.toState.rawValue, MyState.state0)
    }

    func testInit_fromAny()
    {
        let transition = Transition<MyState>(fromState: .any, toState: .state1)
        XCTAssertNil(transition.fromState.rawValue)
        XCTAssertEqual(transition.toState.rawValue, MyState.state1)

        // shorthand
        let transition2 = .any => MyState.state0
        XCTAssertNil(transition2.fromState.rawValue)
        XCTAssertEqual(transition2.toState.rawValue, MyState.state0)
    }

    func testInit_toAny()
    {
        let transition = Transition<MyState>(fromState: .state0, toState: .any)
        XCTAssertEqual(transition.fromState.rawValue, MyState.state0)
        XCTAssertNil(transition.toState.rawValue)

        // shorthand
        let transition2 = MyState.state1 => .any
        XCTAssertEqual(transition2.fromState.rawValue, MyState.state1)
        XCTAssertNil(transition2.toState.rawValue)
    }

    func testNil()
    {
        // .any => state
        let transition = .any => MyState.state0
        XCTAssertTrue(transition.fromState == .any)
        XCTAssertTrue(transition.toState == .state0)

        // state => .any
        let transition2 = MyState.state0 => .any
        XCTAssertTrue(transition2.fromState == .state0)
        XCTAssertTrue(transition2.toState == .any)

        // .any => .any
        let transition3: Transition<MyState> = .any => .any
        XCTAssertTrue(transition3.fromState == .any)
        XCTAssertTrue(transition3.toState == .any)
    }
}
