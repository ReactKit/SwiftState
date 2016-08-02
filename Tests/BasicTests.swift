//
//  BasicTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/08.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class BasicTests: _TestCase
{
    func testREADME()
    {
        // setup state machine
        let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in

            machine.addRoute(.state0 => .state1)
            machine.addRoute(.any => .state2) { context in print("Any => 2, msg=\(context.userInfo)") }
            machine.addRoute(.state2 => .any) { context in print("2 => Any, msg=\(context.userInfo)") }

            // add handler (`context = (event, fromState, toState, userInfo)`)
            machine.addHandler(.state0 => .state1) { context in
                print("0 => 1")
            }

            // add errorHandler
            machine.addErrorHandler { event, fromState, toState, userInfo in
                print("[ERROR] \(fromState) => \(toState)")
            }
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

        // tryState 0 => 1 => 2 => 1 => 0

        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)

        machine <- (.state2, "Hello")
        XCTAssertEqual(machine.state, MyState.state2)

        machine <- (.state1, "Bye")
        XCTAssertEqual(machine.state, MyState.state1)

        machine <- .state0  // fail: no 1 => 0
        XCTAssertEqual(machine.state, MyState.state1)
    }

    func testREADME_tryEvent()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in

            // add 0 => 1 => 2
            machine.addRoutes(event: .event0, transitions: [
                .state0 => .state1,
                .state1 => .state2,
            ])

            // add event handler
            machine.addHandler(event: .event0) { context in
                print(".Event0 triggered!")
            }
        }

        // initial
        XCTAssertEqual(machine.state, MyState.state0)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state1)

        // tryEvent
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2)

        // tryEvent (fails)
        machine <-! .event0
        XCTAssertEqual(machine.state, MyState.state2, "Event0 doesn't have 2 => Any")
    }

    func testREADME_routeMapping()
    {
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

        }

        // initial
        XCTAssertEqual(machine.state, StrState.str("initial"))

        // tryEvent (fails)
        machine <-! .str("go?")
        XCTAssertEqual(machine.state, StrState.str("initial"), "No change.")

        // tryEvent
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 1"))

        // tryEvent (fails)
        machine <-! .str("finish")
        XCTAssertEqual(machine.state, StrState.str("Phase 1"), "No change.")

        // tryEvent
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 2"))

        // tryEvent (fails)
        machine <-! .str("gogogo")
        XCTAssertEqual(machine.state, StrState.str("Phase 2"), "No change.")

        // tryEvent
        machine <-! .str("finish")
        XCTAssertEqual(machine.state, StrState.str("end"))
    }
}
