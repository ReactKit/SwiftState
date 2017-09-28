//
//  StateTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-08.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateTests: _TestCase
{
    func testInit_state()
    {
        let state = State<MyState>(rawValue: .state0)
        XCTAssertTrue(state == .state0)
        XCTAssertTrue(.state0 == state)
    }

    func testInit_nil()
    {
        let state = State<MyState>(rawValue: nil)
        XCTAssertTrue(state == .any)
        XCTAssertTrue(.any == state)
    }

    func testRawValue_state()
    {
        let state = State<MyState>.some(.state0)
        XCTAssertTrue(state.rawValue == .state0)
    }

    func testRawValue_any()
    {
        let state = State<MyState>.any
        XCTAssertTrue(state.rawValue == nil)
    }
}
