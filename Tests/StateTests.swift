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
        let state = State<MyState>(rawValue: .State0)
        XCTAssertTrue(state == .State0)
        XCTAssertTrue(.State0 == state)
    }

    func testInit_nil()
    {
        let state = State<MyState>(rawValue: nil)
        XCTAssertTrue(state == .Any)
        XCTAssertTrue(.Any == state)
    }

    func testRawValue_state()
    {
        let state = State<MyState>.Some(.State0)
        XCTAssertTrue(state.rawValue == .State0)
    }

    func testRawValue_any()
    {
        let state = State<MyState>.Any
        XCTAssertTrue(state.rawValue == nil)
    }
}
