//
//  HierarchicalMachineTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-29.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

private enum _MainState: StateType
{
    case mainState0
    case subMachine1(_SubState)
    case subMachine2(_SubState)

    var hashValue: Int
    {
        switch self {
            case .mainState0:
                return "MainState0".hashValue
            case let .subMachine1(state):
                return "SubMachine1-\(state)".hashValue
            case let .subMachine2(state):
                return "SubMachine2-\(state)".hashValue
        }
    }
}

private enum _SubState: StateType
{
    case subState0, subState1, subState2
}

private func == (lhs: _MainState, rhs: _MainState) -> Bool
{
    switch (lhs, rhs) {
        case (.mainState0, .mainState0):
            return true
        case let (.subMachine1(state1), .subMachine1(state2)):
            return state1 == state2
        case let (.subMachine2(state1), .subMachine2(state2)):
            return state1 == state2
        default:
            return false
    }
}

class HierarchicalMachineTests: _TestCase
{
    ///
    /// Hierarchical state machine.
    ///
    /// - mainMachine
    ///   - MainState0 (initial)
    ///   - subMachine1
    ///     - subState0
    ///     - subState1
    ///   - subMachine2
    ///     - subState0
    ///     - subState1
    ///
    /// - Warning:
    /// This is a naive implementation and easily lose consistency when `subMachine.state` is changed directly, e.g. `subMachine1 <- .subState1`.
    ///
    private var mainMachine: StateMachine<_MainState, NoEvent>?

    private var subMachine1: StateMachine<_SubState, NoEvent>?
    private var subMachine2: StateMachine<_SubState, NoEvent>?

    override func setUp()
    {
        super.setUp()

        let subMachine1 = StateMachine<_SubState, NoEvent>(state: .subState0) { subMachine1 in
            // add Sub1-0 => Sub1-1
            subMachine1.addRoute(.subState0 => .subState1)

            subMachine1.addHandler(.any => .any) { print("[Sub1] \($0.fromState) => \($0.toState)") }
            subMachine1.addErrorHandler { print("[ERROR][Sub1] \($0.fromState) => \($0.toState)") }
        }

        let subMachine2 = StateMachine<_SubState, NoEvent>(state: .subState0) { subMachine2 in
            // add Sub2-0 => Sub2-1
            subMachine2.addRoute(.subState0 => .subState1)

            subMachine2.addHandler(.any => .any) { print("[Sub2] \($0.fromState) => \($0.toState)") }
            subMachine2.addErrorHandler { print("[ERROR][Sub2] \($0.fromState) => \($0.toState)") }
        }

        let mainMachine = StateMachine<_MainState, NoEvent>(state: .mainState0) { mainMachine in

            // add routes & handle for same-subMachine internal transitions
            mainMachine.addRoute(.any => .any, condition: { _, fromState, toState, userInfo in

                switch (fromState, toState) {
                    case let (.subMachine1(state1), .subMachine1(state2)):
                        return subMachine1.hasRoute(fromState: state1, toState: state2)
                    case let (.subMachine2(state1), .subMachine2(state2)):
                        return subMachine2.hasRoute(fromState: state1, toState: state2)
                    default:
                        return false
                }

            }, handler: { _, fromState, toState, userInfo in
                switch (fromState, toState) {
                    case let (.subMachine1, .subMachine1(state2)):
                        subMachine1 <- state2
                    case let (.subMachine2, .subMachine2(state2)):
                        subMachine2 <- state2
                    default:
                        break
                }
            })

            // add routes for mainMachine-state transitions (submachine switching)
            mainMachine.addRouteMapping { event, fromState, userInfo -> _MainState? in

                // NOTE: use external submachine's states only for evaluating `toState`, but not for `fromState`
                switch fromState {
                    // "Main0" => "Sub1-0"
                    case .mainState0 where subMachine1.state == .subState0:
                        return .subMachine1(.subState0)

                    // "Sub1-1" => "Sub2-0"
                    case let .subMachine1(state) where state == .subState1 && subMachine2.state == .subState0:
                        return .subMachine2(.subState0)

                    // "Sub2-1" => "Main0"
                    case let .subMachine2(state) where state == .subState1:
                        return .mainState0

                    default:
                        return nil
                }

            }

            mainMachine.addHandler(.any => .any) { print("[Main] \($0.fromState) => \($0.toState)") }
            mainMachine.addErrorHandler { print("[ERROR][Main] \($0.fromState) => \($0.toState)") }
        }

        self.mainMachine = mainMachine
        self.subMachine1 = subMachine1
        self.subMachine2 = subMachine2
    }

    /// `mainMachine.hasRoute()` test to check submachine's internal routes
    func testHasRoute_submachine_internal()
    {
        let mainMachine = self.mainMachine!
        let subMachine1 = self.subMachine1!
        let subMachine2 = self.subMachine2!

        // initial
        XCTAssertTrue(mainMachine.state == .mainState0)
        XCTAssertTrue(subMachine1.state == .subState0)
        XCTAssertTrue(subMachine2.state == .subState0)

        // subMachine1 internal routes
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState0) => .subMachine1(.subState0)))
        XCTAssertTrue(mainMachine.hasRoute(.subMachine1(.subState0) => .subMachine1(.subState1)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState1) => .subMachine1(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState1) => .subMachine1(.subState1)))

        // subMachine2 internal routes
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState0) => .subMachine2(.subState0)))
        XCTAssertTrue(mainMachine.hasRoute(.subMachine2(.subState0) => .subMachine2(.subState1)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState1) => .subMachine2(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState1) => .subMachine2(.subState1)))
    }

    /// `mainMachine.hasRoute()` test to check switchable submachines
    func testHasRoute_submachine_switching()
    {
        let mainMachine = self.mainMachine!
        let subMachine1 = self.subMachine1!
        let subMachine2 = self.subMachine2!

        // NOTE: mainMachine can check switchable submachines
        // (external routes between submachines = SubState1, SubState2, or nil)

        // initial
        XCTAssertTrue(mainMachine.state == .mainState0)
        XCTAssertTrue(subMachine1.state == .subState0)
        XCTAssertTrue(subMachine2.state == .subState0)

        // from Main0
        XCTAssertTrue(mainMachine.hasRoute(.mainState0 => .subMachine1(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.mainState0 => .subMachine1(.subState1)))
        XCTAssertFalse(mainMachine.hasRoute(.mainState0 => .subMachine2(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.mainState0 => .subMachine2(.subState1)))

        // from Sub1-0
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState0) => .subMachine2(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState0) => .subMachine2(.subState1)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState0) => .mainState0))

        // from Sub1-1
        XCTAssertTrue(mainMachine.hasRoute(.subMachine1(.subState1) => .subMachine2(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState1) => .subMachine2(.subState1)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine1(.subState1) => .mainState0))

        // from Sub2-0
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState0) => .subMachine1(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState0) => .subMachine1(.subState1)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState0) => .mainState0))

        // from Sub2-1
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState1) => .subMachine1(.subState0)))
        XCTAssertFalse(mainMachine.hasRoute(.subMachine2(.subState1) => .subMachine1(.subState1)))
        XCTAssertTrue(mainMachine.hasRoute(.subMachine2(.subState1) => .mainState0))

    }

    func testTryState()
    {
        let mainMachine = self.mainMachine!

        // initial
        XCTAssertTrue(mainMachine.state == .mainState0)

        // Main0 => Sub1-0
        mainMachine <- .subMachine1(.subState0)
        XCTAssertTrue(mainMachine.state == .subMachine1(.subState0))

        // Sub1-0 => Sub1-1 (Sub1 internal transition)
        mainMachine <- .subMachine1(.subState1)
        XCTAssertTrue(mainMachine.state == .subMachine1(.subState1))

        // Sub1-1 => Sub1-2 (Sub1 internal transition, but fails)
        mainMachine <- .subMachine1(.subState2)
        XCTAssertTrue(mainMachine.state == .subMachine1(.subState1), "No change.")

        // Sub1-1 => Sub2-2 (fails)
        mainMachine <- .subMachine2(.subState2)
        XCTAssertTrue(mainMachine.state == .subMachine1(.subState1), "No change.")

        // Sub1-1 => Sub2-0
        mainMachine <- .subMachine2(.subState0)
        XCTAssertTrue(mainMachine.state == .subMachine2(.subState0))

        // Sub2-0 => Main0 (fails)
        mainMachine <- .mainState0
        XCTAssertTrue(mainMachine.state == .subMachine2(.subState0), "No change.")

        // Sub2-0 => Sub2-1
        mainMachine <- .subMachine2(.subState1)
        XCTAssertTrue(mainMachine.state == .subMachine2(.subState1))

        // Sub2-1 => Main
        mainMachine <- .mainState0
        XCTAssertTrue(mainMachine.state == .mainState0)

    }

    func testAddHandler()
    {
        let mainMachine = self.mainMachine!

        var didPass = false

        // NOTE: this handler is added to mainMachine and doesn't make submachines dirty
        mainMachine.addHandler(.mainState0 => .subMachine1(.subState0)) { context in
            print("[Main] 1-1 => 1-2 (specific)")
            didPass = true
        }

        // initial
        XCTAssertTrue(mainMachine.state == .mainState0)
        XCTAssertFalse(didPass)

        // Main0 => Sub1-1 (fails)
        mainMachine <- .subMachine1(.subState1)
        XCTAssertTrue(mainMachine.state == .mainState0, "No change.")
        XCTAssertFalse(didPass)

        // Main0 => Sub1-0
        mainMachine <- .subMachine1(.subState0)
        XCTAssertTrue(mainMachine.state == .subMachine1(.subState0))
        XCTAssertTrue(didPass)
    }

}
