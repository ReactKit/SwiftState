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

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRouteChain(.state0 => .state1 => .state2) { context in
                invokeCount += 1
                return
            }

        }

        // tryState 0 => 1 => 2
        machine <- .state1
        machine <- .state2

        XCTAssertEqual(invokeCount, 1, "Handler should be performed.")

        //
        // reset: tryState 2 => 0
        //
        machine.addRoute(.state2 => .state0)   // make sure to add routes
        machine <- .state0

        // tryState 0 => 1 => 2 again
        machine <- .state1
        machine <- .state2

        XCTAssertEqual(invokeCount, 2, "Handler should be performed again.")
    }

    func testAddRouteChain_condition()
    {
        var flag = false
        var invokeCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRouteChain(.state0 => .state1 => .state2, condition: { _ in flag }) { context in
                invokeCount += 1
                return
            }

        }

        // tryState 0 => 1 => 2
        machine <- .state1
        machine <- .state2

        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed because flag=false.")

        //
        // reset: tryState 2 => 0
        //
        machine.addRoute(.state2 => .state0)   // make sure to add routes
        machine <- .state0

        flag = true

        // tryState 0 => 1 => 2
        machine <- .state1
        machine <- .state2

        XCTAssertEqual(invokeCount, 1, "Handler should be performed.")
    }

    func testAddRouteChain_failBySkipping()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRouteChain(.state0 => .state1 => .state2) { context in
                XCTFail("Handler should NOT be performed because 0 => 2 is skipping 1.")
            }

        }

        // tryState 0 => 2 directly (skipping 1)
        machine <- .state2
    }

    func testAddRouteChain_failByHangingAround()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRouteChain(.state0 => .state1 => .state2) { context in
                XCTFail("Handler should NOT be performed because 0 => 1 => 3 => 2 is hanging around 3.")
            }
            machine.addRoute(.state1 => .state3)    // add 1 => 3 route for hanging around

        }

        // tryState 0 => 1 => 3 => 2 (hanging around 3)
        machine <- .state1
        machine <- .state3
        machine <- .state2
    }

    func testAddRouteChain_succeedByFailingHangingAround()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRouteChain(.state0 => .state1 => .state2) { context in
                invokeCount += 1
                return
            }
            // machine.addRoute(.state1 => .state3)    // comment-out: 1 => 3 is not possible

        }

        // tryState 0 => 1 => 3 => 2 (cannot hang around 3)
        machine <- .state1
        machine <- .state3
        machine <- .state2

        XCTAssertEqual(invokeCount, 1, "Handler should be performed because 1 => 3 is not registered, thus performing 0 => 1 => 2.")
    }

    func testAddRouteChain_goBackHomeAWhile()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2 => 0 (back home) => 2
            machine.addRouteChain(.state0 => .state1 => .state2 => .state0 => .state2) { context in
                invokeCount += 1
                return
            }

        }

        // tryState 0 => 1 => 2 => 0 => 2
        machine <- .state1
        machine <- .state2
        machine <- .state0
        machine <- .state2

        XCTAssertEqual(invokeCount, 1)
    }

    // https://github.com/inamiy/SwiftState/issues/2
    func testAddRouteChain_goBackHomeAWhile2()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            machine.addRoute(.any => .any)    // connect all states

            // add 0 => 1 => 2 => 0 (back home) => 1 => 2
            machine.addRouteChain(.state0 => .state1 => .state2 => .state0 => .state1 => .state2) { context in
                invokeCount += 1
                return
            }

        }

        // tryState 0 => 1 => 2 => 0 => 1 => 0 => 2
        machine <- .state1
        machine <- .state2
        machine <- .state0
        machine <- .state1
        machine <- .state0
        machine <- .state2

        XCTAssertEqual(invokeCount, 0)

        // reset to 0
        machine <- .state0

        // tryState 0 => 1 => 2 => 0 => 1 => 2
        machine <- .state1
        machine <- .state2
        machine <- .state0
        machine <- .state1
        machine <- .state2

        XCTAssertEqual(invokeCount, 1)
    }

    func testRemoveRouteChain()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            let chainDisposable = machine.addRouteChain(.state0 => .state1 => .state2) { context in
                invokeCount += 1
                return
            }

            // remove chain
            chainDisposable.dispose()

        }

        // tryState 0 => 1 => 2

        machine <- .state1
        XCTAssertEqual(invokeCount, 0, "ChainHandler should NOT be performed.")

        machine <- .state2
        XCTAssertEqual(invokeCount, 0, "ChainHandler should NOT be performed.")
    }

    func testAddChainErrorHandler()
    {
        var errorCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            let transitionChain = MyState.state0 => .state1 => .state2

            machine.addRoute(.any => .any)    // connect all states

            // add 0 => 1 => 2
            machine.addRouteChain(transitionChain) { context in
                XCTFail("0 => 1 => 2 should not be succeeded.")
                return
            }

            // add 0 => 1 => 2 chainErrorHandler
            machine.addChainErrorHandler(transitionChain) { context in
                errorCount += 1
                return
            }

        }

        // tryState 0 (starting state) => 1 => 0
        machine <- .state1
        XCTAssertEqual(errorCount, 0, "0 => 1 is successful (still chaining), so chainErrorHandler should NOT be performed at this point.")
        machine <- .state0
        XCTAssertEqual(errorCount, 1, "chainErrorHandler should be performed.")

        // tryState 0 (starting state) => 2
        machine <- .state2
        XCTAssertEqual(errorCount, 2, "chainErrorHandler should be performed again.")
    }

    func testRemoveChainErrorHandler()
    {
        var errorCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            let transitionChain = MyState.state0 => .state1 => .state2

            machine.addRoute(.any => .any)    // connect all states

            // add 0 => 1 => 2 chainErrorHandler
            let chainErrorHandlerDisposable = machine.addChainErrorHandler(transitionChain) { context in
                errorCount += 1
                return
            }

            // remove chainErrorHandler
            chainErrorHandlerDisposable.dispose()

        }

        // tryState 0 (starting state) => 1 => 0
        machine <- .state1
        machine <- .state0
        XCTAssertEqual(errorCount, 0, "Chain error, but chainErrorHandler should NOT be performed.")

        // tryState 0 (starting state) => 2
        machine <- .state2
        XCTAssertEqual(errorCount, 0, "Chain error, but chainErrorHandler should NOT be performed.")
    }

}
