//
//  TransitionChainTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class TransitionChainTests: _TestCase
{
    func testInit()
    {
        // 0 => 1 => 2
        var chain = MyState.State0 => .State1 => .State2

        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .State0)
        XCTAssertTrue(chain.states[1] == .State1)
        XCTAssertTrue(chain.states[2] == .State2)

        // (1 => 2) => 3
        chain = MyState.State1 => .State2 => .State3

        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .State1)
        XCTAssertTrue(chain.states[1] == .State2)
        XCTAssertTrue(chain.states[2] == .State3)

        // 2 => (3 => 0)
        chain = MyState.State2 => (.State3 => .State0)

        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .State2)
        XCTAssertTrue(chain.states[1] == .State3)
        XCTAssertTrue(chain.states[2] == .State0)
    }

    func testAppend()
    {
        // 0 => 1
        let transition = MyState.State0 => .State1
        var chain = TransitionChain(transition: transition)

        XCTAssertEqual(chain.states.count, 2)
        XCTAssertTrue(chain.states[0] == .State0)
        XCTAssertTrue(chain.states[1] == .State1)

        // 0 => 1 => 2
        chain = chain => .State2
        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .State0)
        XCTAssertTrue(chain.states[1] == .State1)
        XCTAssertTrue(chain.states[2] == .State2)

        // 0 => 1 => 2 => 3
        chain = chain => .State3
        XCTAssertEqual(chain.states.count, 4)
        XCTAssertTrue(chain.states[0] == .State0)
        XCTAssertTrue(chain.states[1] == .State1)
        XCTAssertTrue(chain.states[2] == .State2)
        XCTAssertTrue(chain.states[3] == .State3)
    }

    func testPrepend()
    {
        // 0 => 1
        let transition = MyState.State0 => .State1
        var chain = TransitionChain(transition: transition)

        XCTAssertEqual(chain.states.count, 2)
        XCTAssertTrue(chain.states[0] == .State0)
        XCTAssertTrue(chain.states[1] == .State1)

        // 2 => 0 => 1
        chain = .State2 => chain  // same as prepend
        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .State2)
        XCTAssertTrue(chain.states[1] == .State0)
        XCTAssertTrue(chain.states[2] == .State1)

        // 3 => 2 => 0 => 1
        chain = .State3 => chain
        XCTAssertEqual(chain.states.count, 4)
        XCTAssertTrue(chain.states[0] == .State3)
        XCTAssertTrue(chain.states[1] == .State2)
        XCTAssertTrue(chain.states[2] == .State0)
        XCTAssertTrue(chain.states[3] == .State1)
    }
}
