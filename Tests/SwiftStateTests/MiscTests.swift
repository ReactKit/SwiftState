//
//  MiscTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

/// Unarranged tests.
class MiscTests: _TestCase
{
    func testREADME_string()
    {
        let machine = StateMachine<String, NoEvent>(state: ".State0") { machine in

            machine.addRoute(".State0" => ".State1")
            machine.addRoute(.any => ".State2") { context in print("Any => 2, msg=\(context.userInfo)") }
            machine.addRoute(".State2" => .any) { context in print("2 => Any, msg=\(context.userInfo)") }

            // add handler (handlerContext = (event, transition, order, userInfo))
            machine.addHandler(".State0" => ".State1") { context in
                print("0 => 1")
            }

            // add errorHandler
            machine.addErrorHandler { event, fromState, toState, userInfo in
                print("[ERROR] \(fromState) => \(toState)")
            }
        }

        // tryState 0 => 1 => 2 => 1 => 0

        machine <- ".State1"
        XCTAssertEqual(machine.state, ".State1")

        machine <- (".State2", "Hello")
        XCTAssertEqual(machine.state, ".State2")

        machine <- (".State1", "Bye")
        XCTAssertEqual(machine.state, ".State1")

        machine <- ".State0"  // fail: no 1 => 0
        XCTAssertEqual(machine.state, ".State1")

        print("machine.state = \(machine.state)")
    }

    // StateType + associated value
    func testREADME_associatedValue()
    {
        let machine = StateMachine<StrState, StrEvent>(state: .str("0")) { machine in

            machine.addRoute(.str("0") => .str("1"))
            machine.addRoute(.any => .str("2")) { context in print("Any => 2, msg=\(context.userInfo)") }
            machine.addRoute(.str("2") => .any) { context in print("2 => Any, msg=\(context.userInfo)") }

            // add handler (handlerContext = (event, transition, order, userInfo))
            machine.addHandler(.str("0") => .str("1")) { context in
                print("0 => 1")
            }

            // add errorHandler
            machine.addErrorHandler { event, fromState, toState, userInfo in
                print("[ERROR] \(fromState) => \(toState)")
            }
        }

        // tryState 0 => 1 => 2 => 1 => 0

        machine <- .str("1")
        XCTAssertEqual(machine.state, StrState.str("1"))

        machine <- (.str("2"), "Hello")
        XCTAssertEqual(machine.state, StrState.str("2"))

        machine <- (.str("1"), "Bye")
        XCTAssertEqual(machine.state, StrState.str("1"))

        machine <- .str("0")  // fail: no 1 => 0
        XCTAssertEqual(machine.state, StrState.str("1"))

        print("machine.state = \(machine.state)")
    }

    func testExample()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .state0) {

            // add 0 => 1
            $0.addRoute(.state0 => .state1) { context in
                print("[Transition 0=>1] \(context.fromState) => \(context.toState)")
            }
            // add 0 => 1 once more
            $0.addRoute(.state0 => .state1) { context in
                print("[Transition 0=>1b] \(context.fromState) => \(context.toState)")
            }
            // add 2 => Any
            $0.addRoute(.state2 => .any) { context in
                print("[Transition exit 2] \(context.fromState) => \(context.toState) (Any)")
            }
            // add Any => 2
            $0.addRoute(.any => .state2) { context in
                print("[Transition Entry 2] \(context.fromState) (Any) => \(context.toState)")
            }
            // add 1 => 0 (no handler)
            $0.addRoute(.state1 => .state0)

        }

        // 0 => 1
        XCTAssertTrue(machine.hasRoute(.state0 => .state1))

        // 1 => 0
        XCTAssertTrue(machine.hasRoute(.state1 => .state0))

        // 2 => Any
        XCTAssertTrue(machine.hasRoute(.state2 => .state0))
        XCTAssertTrue(machine.hasRoute(.state2 => .state1))
        XCTAssertTrue(machine.hasRoute(.state2 => .state2))
        XCTAssertTrue(machine.hasRoute(.state2 => .state3))

        // Any => 2
        XCTAssertTrue(machine.hasRoute(.state0 => .state2))
        XCTAssertTrue(machine.hasRoute(.state1 => .state2))
        XCTAssertTrue(machine.hasRoute(.state3 => .state2))

        // others
        XCTAssertFalse(machine.hasRoute(.state0 => .state0))
        XCTAssertFalse(machine.hasRoute(.state0 => .state3))
        XCTAssertFalse(machine.hasRoute(.state1 => .state1))
        XCTAssertFalse(machine.hasRoute(.state1 => .state3))
        XCTAssertFalse(machine.hasRoute(.state3 => .state0))
        XCTAssertFalse(machine.hasRoute(.state3 => .state1))
        XCTAssertFalse(machine.hasRoute(.state3 => .state3))

        machine.configure {

            // add error handlers
            $0.addErrorHandler { context in
                print("[ERROR 1] \(context.fromState) => \(context.toState)")
            }

            // add entry handlers
            $0.addHandler(.any => .state0) { context in
                print("[Entry 0] \(context.fromState) => \(context.toState)")   // NOTE: this should not be called
            }
            $0.addHandler(.any => .state1) { context in
                print("[Entry 1] \(context.fromState) => \(context.toState)")
            }
            $0.addHandler(.any => .state2) { context in
                print("[Entry 2] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
            $0.addHandler(.any => .state2) { context in
                print("[Entry 2b] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }

            // add exit handlers
            $0.addHandler(.state0 => .any) { context in
                print("[Exit 0] \(context.fromState) => \(context.toState)")
            }
            $0.addHandler(.state1 => .any) { context in
                print("[Exit 1] \(context.fromState) => \(context.toState)")
            }
            $0.addHandler(.state2 => .any) { context in
                print("[Exit 2] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
            $0.addHandler(.state2 => .any) { context in
                print("[Exit 2b] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
        }

        XCTAssertEqual(machine.state, MyState.state0)

        // tryState 0 => 1 => 2 => 1 => 0 => 3

        machine <- .state1
        XCTAssertEqual(machine.state, MyState.state1)

        machine <- (.state2, "State2 activate")
        XCTAssertEqual(machine.state, MyState.state2)

        machine <- (.state1, "State2 deactivate")
        XCTAssertEqual(machine.state, MyState.state1)

        machine <- .state0
        XCTAssertEqual(machine.state, MyState.state0)

        machine <- .state3
        XCTAssertEqual(machine.state, MyState.state0, "No 0 => 3.")
    }
}
