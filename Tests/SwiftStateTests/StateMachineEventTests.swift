//
//  StateMachineEventTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateMachineEventTests: _TestCase
{
    func testCanTryEvent()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0)

        // add 0 => 1 & 1 => 2
        // (NOTE: this is not chaining e.g. 0 => 1 => 2)
        machine.addRoutes(event: .event0, transitions: [
            .state0 => .state1,
            .state1 => .state2,
        ])

        XCTAssertTrue(machine.canTryEvent(.event0) != nil)
    }

    //--------------------------------------------------
    // MARK: - tryEvent a.k.a `<-!`
    //--------------------------------------------------

    func testTryEvent()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0)

        // add 0 => 1 => 2
        machine.addRoutes(event: .event0, transitions: [
            .state0 => .state1,
            .state1 => .state2,
        ])

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2, "Event0 doesn't have 2 => Any")
    }

    func testTryEvent_string()
    {
        let machine = StateMachine<MyState, String>(state: .state0)

        // add 0 => 1 => 2
        machine.addRoutes(event: "Run", transitions: [
            .state0 => .state1,
            .state1 => .state2,
        ])

        // tryEvent
        machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.state2)

        // tryEvent
        machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.state2, "Event=Run doesn't have 2 => Any")
    }

    // https://github.com/ReactKit/SwiftState/issues/20
    func testTryEvent_issue20()
    {
        let machine = StateMachine<MyState, MyEvent>(state: MyState.state2) { machine in
            machine.addRoutes(event: .event0, transitions: [.any => .state0])
        }

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state0)
    }

    // https://github.com/ReactKit/SwiftState/issues/28
    func testTryEvent_issue28()
    {
        var eventCount = 0

        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in
            machine.addRoute(.state0 => .state1)
            machine.addRoutes(event: .event0, transitions: [.any => .any]) { _ in
                eventCount += 1
            }
        }

        XCTAssertEqual(eventCount, 0)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(eventCount, 1)
        XCTAssertEqual(machine.state, MyState.state0, "State should NOT be changed")

        // tryEvent
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1, "State should be changed")

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(eventCount, 2)
        XCTAssertEqual(machine.state, MyState.state1, "State should NOT be changed")
    }

    // Fix for transitioning of routes w/ multiple from-states
    // https://github.com/ReactKit/SwiftState/pull/32
    func testTryEvent_issue32()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in
            machine.addRoutes(event: .event0, transitions: [ .state0 => .state1 ])
            machine.addRoutes(event: .event1, routes: [ [ .state1, .state2 ] => .state3 ])
        }

        XCTAssertEqual(machine.state, MyState.state0)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event1
        XCTAssertEqual(machine.state, MyState.state3)
    }

    // MARK: hasRoute + event

    func testHasRoute_anyEvent()
    {
        ({
            let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in
                machine.addRoute(.state0 => .state1)
                machine.addRoutes(event: .any, transitions: [.state0 => .state1])
            }

            let hasRoute = machine.hasRoute(event: .event0, transition: .state0 => .state1)
            XCTAssertTrue(hasRoute)
        })()

        ({
            let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in
                machine.addRoute(.state0 => .state1)
                machine.addRoutes(event: .any, transitions: [.state2 => .state3])
            }

            let hasRoute = machine.hasRoute(event: .event0, transition: .state0 => .state1)
            XCTAssertFalse(hasRoute)
        })()
    }

    // Fix hasRoute() bug when there are routes for no-event & with-event.
    // https://github.com/ReactKit/SwiftState/pull/19
    func testHasRoute_issue19()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in
            machine.addRoute(.state0 => .state1)    // no-event
            machine.addRoutes(event: .event0, transitions: [.state1 => .state2])   // with-event
        }

        let hasRoute = machine.hasRoute(event: .event0, transition: .state1 => .state2)
        XCTAssertTrue(hasRoute)
    }

    //--------------------------------------------------
    // MARK: - add/removeRoute
    //--------------------------------------------------

    func testAddRoute_tryState()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 & 1 => 2
            // (NOTE: this is not chaining e.g. 0 => 1 => 2)
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

        }

        // tryState 0 => 1
        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)

        // tryState 1 => 2
        machine <- .state2
        XCTAssertEqual(machine.state, MyState.state2)

        // tryState 2 => 3
        machine <- .state3
        XCTAssertEqual(machine.state, MyState.state2, "2 => 3 is not registered.")
    }

    func testAddRoute_multiple()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

            // add 2 => 1 => 0
            machine.addRoutes(event: .event1, transitions: [
                .state2 => .state1,
                .state1 => .state0,
            ])
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

        // tryEvent
        machine <-! .event1
        XCTAssertEqual(machine.state, MyState.state0, "Event1 doesn't have 0 => Any.")

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2, "Event0 doesn't have 2 => Any.")

        // tryEvent
        machine <-! .event1
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event1
        XCTAssertEqual(machine.state, MyState.state0)
    }

    func testAddRoute_handler()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ], handler: { context in
                invokeCount += 1
                return
            })
        }

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2)

        XCTAssertEqual(invokeCount, 2)
    }

    func testRemoveRoute()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            let routeDisposable = machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

            machine.addHandler(event: .event0) { context in
                invokeCount += 1
                return
            }

            // removeRoute
            routeDisposable.dispose()

        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state0, "Route should be removed.")

        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")
    }

    //--------------------------------------------------
    // MARK: - add/removeHandler
    //--------------------------------------------------

    func testAddHandler()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

            machine.addHandler(event: .event0) { context in
                invokeCount += 1
                return
            }

        }

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2)

        XCTAssertEqual(invokeCount, 2)
    }

    func testRemoveHandler()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

            let handlerDisposable = machine.addHandler(event: .event0) { context in
                invokeCount += 1
                return
            }

            // remove handler
            handlerDisposable.dispose()

        }

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1, "0 => 1 should be succesful")

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2, "1 => 2 should be succesful")

        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")
    }

    //--------------------------------------------------
    // MARK: - addAnyHandler
    //--------------------------------------------------

    func testAddAnyHandler()
    {
        var invokeCounts = [0, 0, 0, 0, 0, 0]

        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2 (event-based)
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

            // add 2 => 3 (state-based)
            machine.addRoute(.state2 => .state3)

            //
            // addAnyHandler (for both event-based & state-based)
            //

            machine.addAnyHandler(.state0 => .state1) { context in
                invokeCounts[0] += 1
            }

            machine.addAnyHandler(.state1 => .state2) { context in
                invokeCounts[1] += 1
            }

            machine.addAnyHandler(.state2 => .state3) { context in
                invokeCounts[2] += 1
            }

            machine.addAnyHandler(.any => .state3) { context in
                invokeCounts[3] += 1
            }

            machine.addAnyHandler(.state0 => .any) { context in
                invokeCounts[4] += 1
            }

            machine.addAnyHandler(.any => .any) { context in
                invokeCounts[5] += 1
            }

        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)
        XCTAssertEqual(invokeCounts, [0, 0, 0, 0, 0, 0])

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertEqual(invokeCounts, [1, 0, 0, 0, 1, 1])

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2)
        XCTAssertEqual(invokeCounts, [1, 1, 0, 0, 1, 2])

        // tryState
        machine <- .state3
        XCTAssertEqual(machine.state, MyState.state3)
        XCTAssertEqual(invokeCounts, [1, 1, 1, 1, 1, 3])

    }

}
