//
//  MachineTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class MachineTests: _TestCase
{
    func testConfigure()
    {
        let machine = Machine<MyState, MyEvent>(state: .state0)

        machine.configure {
            $0.addRoutes(event: .event0, transitions: [ .state0 => .state1 ])
        }

        XCTAssertTrue(machine.canTryEvent(.event0) != nil)
    }

    //--------------------------------------------------
    // MARK: - tryEvent a.k.a `<-!`
    //--------------------------------------------------

    func testCanTryEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .state0)

        // add 0 => 1 & 1 => 2
        // (NOTE: this is not chaining e.g. 0 => 1 => 2)
        machine.addRoutes(event: .event0, transitions: [
            .state0 => .state1,
            .state1 => .state2,
        ])

        XCTAssertTrue(machine.canTryEvent(.event0) != nil)
    }

    func testTryEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in
            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

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

    func testTryEvent_userInfo()
    {
        var userInfo: Any? = nil

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in
            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ], handler: { context in
                userInfo = context.userInfo
            })
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)
        XCTAssertNil(userInfo)

        // tryEvent
        machine <-! (.event0, "gogogo")
        XCTAssertEqual(machine.state, MyState.state1)
        XCTAssertTrue(userInfo as? String == "gogogo")

        // tryEvent
        machine <-! (.event0, "done")
        XCTAssertEqual(machine.state, MyState.state2)
        XCTAssertTrue(userInfo as? String == "done")
    }

    func testTryEvent_twice()
    {
        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in
            // add 0 => 1
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
            ])
            // add 0 => 1
            machine.addRoutes(event: .event1, transitions: [
                .state1 => .state2,
            ])
        }

        // tryEvent (twice)
        machine <-! .event0 <-! .event1
        XCTAssertEqual(machine.state, MyState.state2)
    }

    func testTryEvent_string()
    {
        let machine = Machine<MyState, String>(state: .state0)

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
        let machine = Machine<MyState, MyEvent>(state: MyState.state2) { machine in
            machine.addRoutes(event: .event0, transitions: [.any => .state0])
        }

        XCTAssertEqual(machine.state, MyState.state2)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state0)
    }

    // Fix for transitioning of routes w/ multiple from-states
    // https://github.com/ReactKit/SwiftState/pull/32
    func testTryEvent_issue32()
    {
        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in
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

    //--------------------------------------------------
    // MARK: - add/removeRoute
    //--------------------------------------------------

    func testAddRoute_multiple()
    {
        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in

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

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in
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

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in

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

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state0, "Route should be removed.")

        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")
    }

    func testRemoveRoute_handler()
    {
        var invokeCount = 0

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            let routeDisposable = machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ], handler: { context in
                invokeCount += 1
                return
            })

            // removeRoute
            routeDisposable.dispose()

        }

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

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in

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

    func testAddErrorHandler()
    {
        var invokeCount = 0

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in
            machine.addRoutes(event: .event0, transitions: [ .state0 => .state1 ])
            machine.addErrorHandler { event, fromState, toState, userInfo in
                invokeCount += 1
            }
        }

        XCTAssertEqual(invokeCount, 0)

        // tryEvent (fails)
        machine <-! .event1

        XCTAssertEqual(invokeCount, 1, "Error handler should be called.")

    }

    func testRemoveHandler()
    {
        var invokeCount = 0

        let machine = Machine<MyState, MyEvent>(state: .state0) { machine in

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
    // MARK: - RouteMapping
    //--------------------------------------------------

    func testAddRouteMapping()
    {
        var invokeCount = 0

        let machine = Machine<StrState, StrEvent>(state: .str("initial")) { machine in

            machine.addRouteMapping { event, fromState, userInfo -> StrState? in
                // no route for no-event
                guard let event = event else { return nil }

                switch (event, fromState) {
                    case (.str("gogogo"), .str("initial")):
                        return .str("Phase 1")
                    case (.str("gogogo"), .str("Phase 1")):
                        return .str("Phase 2")
                    case (.str("finish"), .str("Phase 2")):
                        return .str("end")
                    default:
                        return nil
                }
            }

            machine.addHandler(event: .str("gogogo")) { context in
                invokeCount += 1
                return
            }

        }

        // initial
        XCTAssertEqual(machine.state, StrState.str("initial"))

        // tryEvent (fails)
        machine <-! .str("go?")
        XCTAssertEqual(machine.state, StrState.str("initial"), "No change.")
        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")

        // tryEvent
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 1"))
        XCTAssertEqual(invokeCount, 1)

        // tryEvent (fails)
        machine <-! .str("finish")
        XCTAssertEqual(machine.state, StrState.str("Phase 1"), "No change.")
        XCTAssertEqual(invokeCount, 1, "Handler should NOT be performed")

        // tryEvent
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 2"))
        XCTAssertEqual(invokeCount, 2)

        // tryEvent (fails)
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 2"), "No change.")
        XCTAssertEqual(invokeCount, 2, "Handler should NOT be performed")

        // tryEvent
        machine <-! .str("finish")
        XCTAssertEqual(machine.state, StrState.str("end"))
        XCTAssertEqual(invokeCount, 2, "gogogo-Handler should NOT be performed")

    }

    func testAddRouteMapping_handler()
    {
        var invokeCount1 = 0
        var invokeCount2 = 0
        var disposables = [Disposable]()

        let machine = Machine<StrState, StrEvent>(state: .str("initial")) { machine in

            let d = machine.addRouteMapping({ event, fromState, userInfo -> StrState? in
                // no route for no-event
                guard let event = event else { return nil }

                switch (event, fromState) {
                    case (.str("gogogo"), .str("initial")):
                        return .str("Phase 1")
                    default:
                        return nil
                }
            }, handler: { context in
                invokeCount1 += 1
            })

            disposables += [d]

            let d2 = machine.addRouteMapping({ event, fromState, userInfo -> StrState? in
                // no route for no-event
                guard let event = event else { return nil }

                switch (event, fromState) {
                    case (.str("finish"), .str("Phase 1")):
                        return .str("end")
                    default:
                        return nil
                }
            }, handler: { context in
                invokeCount2 += 1
            })

            disposables += [d2]

        }

        // initial
        XCTAssertEqual(machine.state, StrState.str("initial"))

        // tryEvent (fails)
        machine <-! .str("go?")
        XCTAssertEqual(machine.state, StrState.str("initial"), "No change.")
        XCTAssertEqual(invokeCount1, 0)
        XCTAssertEqual(invokeCount2, 0)

        // tryEvent
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 1"))
        XCTAssertEqual(invokeCount1, 1)
        XCTAssertEqual(invokeCount2, 0)

        // tryEvent (fails)
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 1"), "No change.")
        XCTAssertEqual(invokeCount1, 1)
        XCTAssertEqual(invokeCount2, 0)

        // tryEvent
        machine <-! .str("finish")
        XCTAssertEqual(machine.state, StrState.str("end"))
        XCTAssertEqual(invokeCount1, 1)
        XCTAssertEqual(invokeCount2, 1)

        // hasRoute (before dispose)
        XCTAssertEqual(machine.hasRoute(event: .str("gogogo"), transition: .str("initial") => .str("Phase 1")), true)
        XCTAssertEqual(machine.hasRoute(event: .str("finish"), transition: .str("Phase 1") => .str("end")), true)

        disposables.forEach { $0.dispose() }

        // hasRoute (after dispose)
        XCTAssertEqual(machine.hasRoute(event: .str("gogogo"), transition: .str("initial") => .str("Phase 1")), false, "Routes & handlers should be disposed.")
        XCTAssertEqual(machine.hasRoute(event: .str("finish"), transition: .str("Phase 1") => .str("end")), false, "Routes & handlers should be disposed.")

    }

}
