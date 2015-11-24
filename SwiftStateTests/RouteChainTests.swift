//
//  MachineChainTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class MachineChainTests: _TestCase
{    
    func testAddRouteChain()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            machine.addRouteChain(.State0 => .State1 => .State2) { context in
                invokeCount++
                return
            }
        
        }
        
        // tryState 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1, "Handler should be performed.")
        
        //
        // reset: tryState 2 => 0
        //
        machine.addRoute(.State2 => .State0)   // make sure to add routes
        machine <- .State0
        
        // tryState 0 => 1 => 2 again
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 2, "Handler should be performed again.")
    }
    
    func testAddRouteChain_condition()
    {
        var flag = false
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            machine.addRouteChain(.State0 => .State1 => .State2, condition: { _ in flag }) { context in
                invokeCount++
                return
            }
        
        }
        
        // tryState 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed because flag=false.")
        
        //
        // reset: tryState 2 => 0
        //
        machine.addRoute(.State2 => .State0)   // make sure to add routes
        machine <- .State0
        
        flag = true
        
        // tryState 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1, "Handler should be performed.")
    }
    
    func testAddRouteChain_failBySkipping()
    {
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            machine.addRouteChain(.State0 => .State1 => .State2) { context in
                XCTFail("Handler should NOT be performed because 0 => 2 is skipping 1.")
            }
        
        }
        
        // tryState 0 => 2 directly (skipping 1)
        machine <- .State2
    }
    
    func testAddRouteChain_failByHangingAround()
    {
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            machine.addRouteChain(.State0 => .State1 => .State2) { context in
                XCTFail("Handler should NOT be performed because 0 => 1 => 3 => 2 is hanging around 3.")
            }
            machine.addRoute(.State1 => .State3)    // add 1 => 3 route for hanging around
        
        }
        
        // tryState 0 => 1 => 3 => 2 (hanging around 3)
        machine <- .State1
        machine <- .State3
        machine <- .State2
    }
    
    func testAddRouteChain_succeedByFailingHangingAround()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            machine.addRouteChain(.State0 => .State1 => .State2) { context in
                invokeCount++
                return
            }
            // machine.addRoute(.State1 => .State3)    // comment-out: 1 => 3 is not possible
        
        }
        
        // tryState 0 => 1 => 3 => 2 (cannot hang around 3)
        machine <- .State1
        machine <- .State3
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1, "Handler should be performed because 1 => 3 is not registered, thus performing 0 => 1 => 2.")
    }
    
    func testAddRouteChain_goBackHomeAWhile()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2 => 0 (back home) => 2
            machine.addRouteChain(.State0 => .State1 => .State2 => .State0 => .State2) { context in
                invokeCount++
                return
            }
        
        }
        
        // tryState 0 => 1 => 2 => 0 => 2
        machine <- .State1
        machine <- .State2
        machine <- .State0
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1)
    }
    
    // https://github.com/inamiy/SwiftState/issues/2
    func testAddRouteChain_goBackHomeAWhile2()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            machine.addRoute(.Any => .Any)    // connect all states
            
            // add 0 => 1 => 2 => 0 (back home) => 1 => 2
            machine.addRouteChain(.State0 => .State1 => .State2 => .State0 => .State1 => .State2) { context in
                invokeCount++
                return
            }
            
        }
        
        // tryState 0 => 1 => 2 => 0 => 1 => 0 => 2
        machine <- .State1
        machine <- .State2
        machine <- .State0
        machine <- .State1
        machine <- .State0
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 0)
        
        // reset to 0
        machine <- .State0
        
        // tryState 0 => 1 => 2 => 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        machine <- .State0
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1)
    }
    
    func testRemoveRouteChain()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            let (routeChainID, _) = machine.addRouteChain(.State0 => .State1 => .State2) { context in
                invokeCount++
                return
            }
            
            // removeRouteChain
            machine.removeRouteChain(routeChainID)
            
        }
        
        // tryState 0 => 1
        let success = machine <- .State1
        
        XCTAssertFalse(success, "RouteChain should be removed.")
        XCTAssertEqual(invokeCount, 0, "ChainHandler should NOT be performed.")
    }
    
    func testRemoveChainHandler()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            let (_, chainHandlerID) = machine.addRouteChain(.State0 => .State1 => .State2) { context in
                invokeCount++
                return
            }
            
            // removeHandler
            machine.removeChainHandler(chainHandlerID)
            
        }
        
        // tryState 0 => 1 => 2
        machine <- .State1
        let success = machine <- .State2
        
        XCTAssertTrue(success, "0 => 1 => 2 should be successful.")
        XCTAssertEqual(invokeCount, 0, "ChainHandler should NOT be performed.")
    }
    
    func testAddChainErrorHandler()
    {
        var errorCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            let transitionChain = MyState.State0 => .State1 => .State2
            
            machine.addRoute(.Any => .Any)    // connect all states
            
            // add 0 => 1 => 2
            machine.addRouteChain(transitionChain) { context in
                XCTFail("0 => 1 => 2 should not be succeeded.")
                return
            }
        
            // add 0 => 1 => 2 chainErrorHandler
            machine.addChainErrorHandler(transitionChain) { context in
                errorCount++
                return
            }
        
        }
        
        // tryState 0 (starting state) => 1 => 0
        machine <- .State1
        XCTAssertEqual(errorCount, 0, "0 => 1 is successful (still chaining), so chainErrorHandler should NOT be performed at this point.")
        machine <- .State0
        XCTAssertEqual(errorCount, 1, "chainErrorHandler should be performed.")
        
        // tryState 0 (starting state) => 2
        machine <- .State2
        XCTAssertEqual(errorCount, 2, "chainErrorHandler should be performed again.")
    }
    
    func testRemoveChainErrorHandler()
    {
        var errorCount = 0
        
        let machine = Machine<MyState, NoEvent>(state: .State0) { machine in
        
            let transitionChain = MyState.State0 => .State1 => .State2
            
            machine.addRoute(.Any => .Any)    // connect all states
            
            // add 0 => 1 => 2 chainErrorHandler
            let chainHandlerID = machine.addChainErrorHandler(transitionChain) { context in
                errorCount++
                return
            }
            
            // remove chainErrorHandler
            machine.removeChainHandler(chainHandlerID)
        
        }
        
        // tryState 0 (starting state) => 1 => 0
        machine <- .State1
        machine <- .State0
        XCTAssertEqual(errorCount, 0, "Chain error, but chainErrorHandler should NOT be performed.")
        
        // tryState 0 (starting state) => 2
        machine <- .State2
        XCTAssertEqual(errorCount, 0, "Chain error, but chainErrorHandler should NOT be performed.")
    }
    
}