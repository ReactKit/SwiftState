//
//  StateTransitionChainTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateTransitionChainTests: _TestCase
{
    func testInit()
    {
        // 0 => 1 => 2
        var chain = MyState.State0 => .State1 => .State2
        
        XCTAssertEqual(chain.numberOfTransitions, 2)
        XCTAssertEqual(chain.firstState, MyState.State0)
        XCTAssertEqual(chain.lastState, MyState.State2)
        
        // (1 => 2) => 3
        chain = MyState.State1 => .State2 => .State3
        
        XCTAssertEqual(chain.numberOfTransitions, 2)
        XCTAssertEqual(chain.firstState, MyState.State1)
        XCTAssertEqual(chain.lastState, MyState.State3)
        
        // 2 => (3 => 0)
        chain = MyState.State2 => (.State3 => .State0)
        
        XCTAssertEqual(chain.numberOfTransitions, 2)
        XCTAssertEqual(chain.firstState, MyState.State2)
        XCTAssertEqual(chain.lastState, MyState.State0)
    }
    
    func testAppend()
    {
        // 0 => 1
        let transition = MyState.State0 => .State1
        var chain = transition as StateTransitionChain
        
        XCTAssertEqual(chain.numberOfTransitions, 1)
        XCTAssertEqual(chain.firstState, MyState.State0)
        XCTAssertEqual(chain.lastState, MyState.State1)
        
        // 0 => 1 => 2
        chain = chain => .State2  // same as append
        XCTAssertEqual(chain.numberOfTransitions, 2)
        XCTAssertEqual(chain.firstState, MyState.State0)
        XCTAssertEqual(chain.lastState, MyState.State2)
        
        // 0 => 1 => 2 => 3
        chain.append(.State3)
        XCTAssertEqual(chain.numberOfTransitions, 3)
        XCTAssertEqual(chain.firstState, MyState.State0)
        XCTAssertEqual(chain.lastState, MyState.State3)
    }
    
    func testPrepend()
    {
        // 0 => 1
        var transition = MyState.State0 => .State1
        var chain = transition as StateTransitionChain
        
        XCTAssertEqual(chain.numberOfTransitions, 1)
        XCTAssertEqual(chain.firstState, MyState.State0)
        XCTAssertEqual(chain.lastState, MyState.State1)
        
        // 2 => 0 => 1
        chain = .State2 => chain  // same as prepend
        XCTAssertEqual(chain.numberOfTransitions, 2)
        XCTAssertEqual(chain.firstState, MyState.State2)
        XCTAssertEqual(chain.lastState, MyState.State1)
        
        // 3 => 2 => 0 => 1
        chain.prepend(.State3)
        XCTAssertEqual(chain.numberOfTransitions, 3)
        XCTAssertEqual(chain.firstState, MyState.State3)
        XCTAssertEqual(chain.lastState, MyState.State1)
    }
}