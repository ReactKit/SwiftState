//
//  StateMachineTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateMachineTests: _TestCase
{
    func testInit()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0)

        XCTAssertEqual(machine.state, MyState.state0)
    }

    //--------------------------------------------------
    // MARK: - tryState a.k.a `<-`
    //--------------------------------------------------

    // machine <- state
    func testTryState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0)

        // tryState 0 => 1, without registering any transitions
        machine <- .state1

        XCTAssertEqual(machine.state, MyState.state0, "0 => 1 should fail because transition is not added yet.")

        // add 0 => 1
        machine.addRoute(.state0 => .state1)

        // tryState 0 => 1
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)
    }

    func testTryState_string()
    {
        let machine = StateMachine<String, NoEvent>(state: "0")

        // tryState 0 => 1, without registering any transitions
        machine <- "1"

        XCTAssertEqual(machine.state, "0", "0 => 1 should fail because transition is not added yet.")

        // add 0 => 1
        machine.addRoute("0" => "1")

        // tryState 0 => 1
        machine <- "1"
        XCTAssertEqual(machine.state, "1")
    }

    //--------------------------------------------------
    // MARK: - addRoute
    //--------------------------------------------------

    // add state1 => state2
    func testAddRoute()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            machine.addRoute(.state0 => .state1)
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))     // true
        XCTAssertFalse(machine.hasRoute(.state0 => .state2))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
    }

    // add .any => state
    func testAddRoute_fromAnyState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            machine.addRoute(.any => .state1) // Any => State1
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))     // true
        XCTAssertFalse(machine.hasRoute(.state0 => .state2))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertTrue(machine.hasRoute(.state1 => .state1))     // true
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
    }

    // add state => .any
    func testAddRoute_toAnyState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            machine.addRoute(.state1 => .any) // State1 => Any
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
        XCTAssertFalse(machine.hasRoute(.state0 => .state2))
        XCTAssertTrue(machine.hasRoute(.state1 => .state0))     // true
        XCTAssertTrue(machine.hasRoute(.state1 => .state1))     // true
        XCTAssertTrue(machine.hasRoute(.state1 => .state2))     // true
    }

    // add .any => .any
    func testAddRoute_bothAnyState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            machine.addRoute(.any => .any) // Any => Any
        }

        XCTAssertTrue(machine.hasRoute(.state0 => .state0))     // true
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))     // true
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))     // true
        XCTAssertTrue(machine.hasRoute(.state1 => .state0))     // true
        XCTAssertTrue(machine.hasRoute(.state1 => .state1))     // true
        XCTAssertTrue(machine.hasRoute(.state1 => .state2))     // true
    }

    // add state0 => state0
    func testAddRoute_sameState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            machine.addRoute(.state0 => .state0)
        }

        XCTAssertTrue(machine.hasRoute(.state0 => .state0))
    }

    // add route + condition
    func testAddRoute_condition()
    {
        var flag = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            // add 0 => 1
            machine.addRoute(.state0 => .state1, condition: { _ in flag })

        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state1))

        flag = true

        XCTAssertTrue(machine.hasRoute(.state0 => .state1))
    }

    // add route + condition + blacklist
    func testAddRoute_condition_blacklist()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            // add 0 => Any, except 0 => 2
            machine.addRoute(.state0 => .any, condition: { context in
                return context.toState != .state2
            })
        }

        XCTAssertTrue(machine.hasRoute(.state0 => .state0))
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))
        XCTAssertFalse(machine.hasRoute(.state0 => .state2))
        XCTAssertTrue(machine.hasRoute(.state0 => .state3))
    }

    // add route + handler
    func testAddRoute_handler()
    {
        var invokedCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            machine.addRoute(.state0 => .state1) { context in
                XCTAssertEqual(context.fromState, MyState.state0)
                XCTAssertEqual(context.toState, MyState.state1)

                invokedCount += 1
            }

        }

        XCTAssertEqual(invokedCount, 0, "Transition has not started yet.")

        // tryState 0 => 1
        machine <- .state1

        XCTAssertEqual(invokedCount, 1)
    }

    // add route + conditional handler
    func testAddRoute_conditionalHandler()
    {
        var invokedCount = 0
        var flag = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 without condition to guarantee 0 => 1 transition
            machine.addRoute(.state0 => .state1)

            // add 0 => 1 with condition + conditionalHandler
            machine.addRoute(.state0 => .state1, condition: { _ in flag }) { context in
                XCTAssertEqual(context.fromState, MyState.state0)
                XCTAssertEqual(context.toState, MyState.state1)

                invokedCount += 1
            }

            // add 1 => 0 for resetting state
            machine.addRoute(.state1 => .state0)

        }

        // tryState 0 => 1
        machine <- .state1

        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertEqual(invokedCount, 0, "Conditional handler should NOT be performed because flag=false.")

        // tryState 1 => 0 (resetting to 0)
        machine <- .state0

        XCTAssertEqual(machine.state, MyState.state0)

        flag = true

        // tryState 0 => 1
        machine <- .state1

        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertEqual(invokedCount, 1)

    }

    // MARK: addRoute using array

    func testAddRoute_array_left()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            // add 0 => 2 or 1 => 2
            machine.addRoute([.state0, .state1] => .state2)
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertTrue(machine.hasRoute(.state1 => .state2))
    }

    func testAddRoute_array_right()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            // add 0 => 1 or 0 => 2
            machine.addRoute(.state0 => [.state1, .state2])
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
    }

    func testAddRoute_array_both()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
            // add 0 => 2 or 0 => 3 or 1 => 2 or 1 => 3
            machine.addRoute([MyState.state0, MyState.state1] => [MyState.state2, MyState.state3])
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))
        XCTAssertTrue(machine.hasRoute(.state0 => .state3))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertTrue(machine.hasRoute(.state1 => .state2))
        XCTAssertTrue(machine.hasRoute(.state1 => .state3))
        XCTAssertFalse(machine.hasRoute(.state2 => .state0))
        XCTAssertFalse(machine.hasRoute(.state2 => .state1))
        XCTAssertFalse(machine.hasRoute(.state2 => .state2))
        XCTAssertFalse(machine.hasRoute(.state2 => .state3))
        XCTAssertFalse(machine.hasRoute(.state3 => .state0))
        XCTAssertFalse(machine.hasRoute(.state3 => .state1))
        XCTAssertFalse(machine.hasRoute(.state3 => .state2))
        XCTAssertFalse(machine.hasRoute(.state3 => .state3))
    }

    //--------------------------------------------------
    // MARK: - removeRoute
    //--------------------------------------------------

    func testRemoveRoute()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0)

        let routeDisposable = machine.addRoute(.state0 => .state1)

        XCTAssertTrue(machine.hasRoute(.state0 => .state1))

        // remove route
        routeDisposable.dispose()

        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
    }

    func testRemoveRoute_handler()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0)

        let routeDisposable = machine.addRoute(.state0 => .state1, handler: { _ in })

        XCTAssertTrue(machine.hasRoute(.state0 => .state1))

        // remove route
        routeDisposable.dispose()

        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
    }

    //--------------------------------------------------
    // MARK: - addHandler
    //--------------------------------------------------

    func testAddHandler()
    {
        var invokedCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1
            machine.addRoute(.state0 => .state1)

            machine.addHandler(.state0 => .state1) { context in
                XCTAssertEqual(context.fromState, MyState.state0)
                XCTAssertEqual(context.toState, MyState.state1)

                invokedCount += 1
            }

        }

        // not tried yet
        XCTAssertEqual(invokedCount, 0, "Transition has not started yet.")

        // tryState 0 => 1
        machine <- .state1

        XCTAssertEqual(invokedCount, 1)
    }

    func testAddHandler_order()
    {
        var invokedCount = 0

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1
            machine.addRoute(.state0 => .state1)

            // order = 100 (default)
            machine.addHandler(.state0 => .state1) { context in
                XCTAssertEqual(invokedCount, 1)

                XCTAssertEqual(context.fromState, MyState.state0)
                XCTAssertEqual(context.toState, MyState.state1)

                invokedCount += 1
            }

            // order = 99
            machine.addHandler(.state0 => .state1, order: 99) { context in
                XCTAssertEqual(invokedCount, 0)

                XCTAssertEqual(context.fromState, MyState.state0)
                XCTAssertEqual(context.toState, MyState.state1)

                invokedCount += 1
            }

        }

        XCTAssertEqual(invokedCount, 0)

        // tryState 0 => 1
        machine <- .state1

        XCTAssertEqual(invokedCount, 2)
    }


    func testAddHandler_multiple()
    {
        var passed1 = false
        var passed2 = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1
            machine.addRoute(.state0 => .state1)

            machine.addHandler(.state0 => .state1) { context in
                passed1 = true
            }

            // add 0 => 1 once more
            machine.addRoute(.state0 => .state1)

            machine.addHandler(.state0 => .state1) { context in
                passed2 = true
            }

        }

        // tryState 0 => 1
        machine <- .state1

        XCTAssertTrue(passed1)
        XCTAssertTrue(passed2)
    }

    func testAddHandler_overload()
    {
        var passed = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            machine.addRoute(.state0 => .state1)

            machine.addHandler(.state0 => .state1) { context in
                // empty
            }

            machine.addHandler(.state0 => .state1) { context in
                passed = true
            }

        }

        XCTAssertFalse(passed)

        machine <- .state1

        XCTAssertTrue(passed)
    }

    //--------------------------------------------------
    // MARK: - removeHandler
    //--------------------------------------------------

    func testRemoveHandler()
    {
        var passed = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1
            machine.addRoute(.state0 => .state1)

            let handlerDisposable = machine.addHandler(.state0 => .state1) { context in
                XCTFail("Should never reach here")
            }

            // add 0 => 1 once more
            machine.addRoute(.state0 => .state1)

            machine.addHandler(.state0 => .state1) { context in
                passed = true
            }

            // remove handler
            handlerDisposable.dispose()

        }

        XCTAssertFalse(passed)

        // tryState 0 => 1
        machine <- .state1

        XCTAssertTrue(passed)
    }

    func testRemoveHandler_unregistered()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0)

        // add 0 => 1
        machine.addRoute(.state0 => .state1)

        let handlerDisposable = machine.addHandler(.state0 => .state1) { context in
            // empty
        }

        XCTAssertFalse(handlerDisposable.disposed)

        // remove handler
        handlerDisposable.dispose()

        // remove already unregistered handler
        XCTAssertTrue(handlerDisposable.disposed, "removeHandler should fail because handler is already removed.")
    }

    func testRemoveErrorHandler()
    {
        var passed = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 2 => 1
            machine.addRoute(.state2 => .state1)

            let handlerDisposable = machine.addErrorHandler { context in
                XCTFail("Should never reach here")
            }

            // add 2 => 1 once more
            machine.addRoute(.state2 => .state1)

            machine.addErrorHandler { context in
                passed = true
            }

            // remove handler
            handlerDisposable.dispose()

        }

        // tryState 0 => 1
        machine <- .state1

        XCTAssertTrue(passed)
    }

    func testRemoveErrorHandler_unregistered()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0)

        // add 0 => 1
        machine.addRoute(.state0 => .state1)

        let handlerDisposable = machine.addErrorHandler { context in
            // empty
        }

        XCTAssertFalse(handlerDisposable.disposed)

        // remove handler
        handlerDisposable.dispose()

        // remove already unregistered handler
        XCTAssertTrue(handlerDisposable.disposed, "removeHandler should fail because handler is already removed.")
    }

    //--------------------------------------------------
    // MARK: - addRouteChain
    //--------------------------------------------------

    func testAddRouteChain()
    {
        var success = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 => 2 => 3
            machine.addRouteChain(.state0 => .state1 => .state2 => .state3) { context in
                success = true
            }
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

        // 0 => 1
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertFalse(success, "RouteChain is not completed yet.")

        // 1 => 2
        machine <- .state2
        XCTAssertEqual(machine.state, MyState.state2)
        XCTAssertFalse(success, "RouteChain is not completed yet.")

        // 2 => 3
        machine <- .state3
        XCTAssertEqual(machine.state, MyState.state3)
        XCTAssertTrue(success)
    }

    func testAddChainHandler()
    {
        var success = false

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add all routes
            machine.addRoute(.any => .any)

            // add 0 => 1 => 2 => 3
            machine.addChainHandler(.state0 => .state1 => .state2 => .state3) { context in
                success = true
            }
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

        // 0 => 1
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertFalse(success, "RouteChain is not completed yet.")

        // 1 => 2
        machine <- .state2
        XCTAssertEqual(machine.state, MyState.state2)
        XCTAssertFalse(success, "RouteChain is not completed yet.")

        // 2 => 2 (fails & resets chaining count)
        machine <- .state2
        XCTAssertEqual(machine.state, MyState.state2, "State should not change.")
        XCTAssertFalse(success, "RouteChain failed and reset count.")

        // 2 => 3 (chaining is failed)
        machine <- .state3
        XCTAssertEqual(machine.state, MyState.state3)
        XCTAssertFalse(success, "RouteChain is already failed.")

        // go back to 0 & run 0 => 1 => 2 => 3
        machine <- .state0 <- .state1 <- .state2 <- .state3
        XCTAssertEqual(machine.state, MyState.state3)
        XCTAssertTrue(success, "RouteChain is resetted & should succeed its chaining.")
    }

    //--------------------------------------------------
    // MARK: - Event/StateRouteMapping
    //--------------------------------------------------

    func testAddStateRouteMapping()
    {
        var routeMappingDisposable: Disposable?

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 & 0 => 2
            routeMappingDisposable = machine.addStateRouteMapping { fromState, userInfo -> [MyState]? in
                if fromState == .state0 {
                    return [.state1, .state2]
                }
                else {
                    return nil
                }
            }

        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
        XCTAssertFalse(machine.hasRoute(.state2 => .state0))
        XCTAssertFalse(machine.hasRoute(.state2 => .state1))
        XCTAssertFalse(machine.hasRoute(.state2 => .state2))

        // remove routeMapping
        routeMappingDisposable?.dispose()

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
        XCTAssertFalse(machine.hasRoute(.state0 => .state2))
        XCTAssertFalse(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
        XCTAssertFalse(machine.hasRoute(.state2 => .state0))
        XCTAssertFalse(machine.hasRoute(.state2 => .state1))
        XCTAssertFalse(machine.hasRoute(.state2 => .state2))
    }

    func testAddStateRouteMapping_handler()
    {
        var invokedCount = 0
        var routeMappingDisposable: Disposable?

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 & 0 => 2
            routeMappingDisposable = machine.addStateRouteMapping({ fromState, userInfo -> [MyState]? in

                if fromState == .state0 {
                    return [.state1, .state2]
                }
                else {
                    return nil
                }

            }, handler: { context in
                invokedCount += 1
            })

        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)
        XCTAssertEqual(invokedCount, 0)

        // 0 => 1
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertEqual(invokedCount, 1)

        // remove routeMapping
        routeMappingDisposable?.dispose()

        // 1 => 2 (fails)
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertEqual(invokedCount, 1)

    }

    /// Test `Event/StateRouteMapping`s.
    func testAddBothRouteMappings()
    {
        var routeMappingDisposable: Disposable?

        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            // add 0 => 1 & 0 => 2
            routeMappingDisposable = machine.addStateRouteMapping { fromState, userInfo -> [MyState]? in
                if fromState == .state0 {
                    return [.state1, .state2]
                }
                else {
                    return nil
                }
            }

            // add 1 => 0 (can also use `RouteMapping` closure for single-`toState`)
            machine.addRouteMapping { event, fromState, userInfo -> MyState? in
                guard event == nil else { return nil }

                if fromState == .state1 {
                    return .state0
                }
                else {
                    return nil
                }
            }
        }

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))
        XCTAssertTrue(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
        XCTAssertFalse(machine.hasRoute(.state2 => .state0))
        XCTAssertFalse(machine.hasRoute(.state2 => .state1))
        XCTAssertFalse(machine.hasRoute(.state2 => .state2))

        // remove routeMapping
        routeMappingDisposable?.dispose()

        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertFalse(machine.hasRoute(.state0 => .state1))
        XCTAssertFalse(machine.hasRoute(.state0 => .state2))
        XCTAssertTrue(machine.hasRoute(.state1 => .state0))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state2))
        XCTAssertFalse(machine.hasRoute(.state2 => .state0))
        XCTAssertFalse(machine.hasRoute(.state2 => .state1))
        XCTAssertFalse(machine.hasRoute(.state2 => .state2))
    }
}
