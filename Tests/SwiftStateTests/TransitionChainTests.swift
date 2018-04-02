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
        var chain = MyState.state0 => .state1 => .state2

        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .state0)
        XCTAssertTrue(chain.states[1] == .state1)
        XCTAssertTrue(chain.states[2] == .state2)

        // (1 => 2) => 3
        chain = MyState.state1 => .state2 => .state3

        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .state1)
        XCTAssertTrue(chain.states[1] == .state2)
        XCTAssertTrue(chain.states[2] == .state3)

        // 2 => (3 => 0)
        chain = MyState.state2 => (.state3 => .state0)

        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .state2)
        XCTAssertTrue(chain.states[1] == .state3)
        XCTAssertTrue(chain.states[2] == .state0)
    }

    func testAppend()
    {
        // 0 => 1
        let transition = MyState.state0 => .state1
        var chain = TransitionChain(transition: transition)

        XCTAssertEqual(chain.states.count, 2)
        XCTAssertTrue(chain.states[0] == .state0)
        XCTAssertTrue(chain.states[1] == .state1)

        // 0 => 1 => 2
        chain = chain => .state2
        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .state0)
        XCTAssertTrue(chain.states[1] == .state1)
        XCTAssertTrue(chain.states[2] == .state2)

        // 0 => 1 => 2 => 3
        chain = chain => .state3
        XCTAssertEqual(chain.states.count, 4)
        XCTAssertTrue(chain.states[0] == .state0)
        XCTAssertTrue(chain.states[1] == .state1)
        XCTAssertTrue(chain.states[2] == .state2)
        XCTAssertTrue(chain.states[3] == .state3)
    }

    func testPrepend()
    {
        // 0 => 1
        let transition = MyState.state0 => .state1
        var chain = TransitionChain(transition: transition)

        XCTAssertEqual(chain.states.count, 2)
        XCTAssertTrue(chain.states[0] == .state0)
        XCTAssertTrue(chain.states[1] == .state1)

        // 2 => 0 => 1
        chain = .state2 => chain  // same as prepend
        XCTAssertEqual(chain.states.count, 3)
        XCTAssertTrue(chain.states[0] == .state2)
        XCTAssertTrue(chain.states[1] == .state0)
        XCTAssertTrue(chain.states[2] == .state1)

        // 3 => 2 => 0 => 1
        chain = .state3 => chain
        XCTAssertEqual(chain.states.count, 4)
        XCTAssertTrue(chain.states[0] == .state3)
        XCTAssertTrue(chain.states[1] == .state2)
        XCTAssertTrue(chain.states[2] == .state0)
        XCTAssertTrue(chain.states[3] == .state1)
    }
}
