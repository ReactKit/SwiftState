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
    case MainState0
    case SubMachine1(_SubState)
    case SubMachine2(_SubState)

    var hashValue: Int
    {
        switch self {
            case .MainState0:
                return "MainState0".hashValue
            case let .SubMachine1(state):
                return "SubMachine1-\(state)".hashValue
            case let .SubMachine2(state):
                return "SubMachine2-\(state)".hashValue
        }
    }
}

private enum _SubState: StateType
{
    case SubState0, SubState1, SubState2
}

private func == (lhs: _MainState, rhs: _MainState) -> Bool
{
    switch (lhs, rhs) {
        case (.MainState0, .MainState0):
            return true
        case let (.SubMachine1(state1), .SubMachine1(state2)):
            return state1 == state2
        case let (.SubMachine2(state1), .SubMachine2(state2)):
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
    ///     - SubState0
    ///     - SubState1
    ///   - subMachine2
    ///     - SubState0
    ///     - SubState1
    ///
    /// - Warning:
    /// This is a naive implementation and easily lose consistency when `subMachine.state` is changed directly, e.g. `subMachine1 <- .SubState1`.
    ///
    private var mainMachine: StateMachine<_MainState, NoEvent>?

    private var subMachine1: StateMachine<_SubState, NoEvent>?
    private var subMachine2: StateMachine<_SubState, NoEvent>?

    override func setUp()
    {
        super.setUp()

        let subMachine1 = StateMachine<_SubState, NoEvent>(state: .SubState0) { subMachine1 in
            // add Sub1-0 => Sub1-1
            subMachine1.addRoute(.SubState0 => .SubState1)

            subMachine1.addHandler(.Any => .Any) { print("[Sub1] \($0.fromState) => \($0.toState)") }
            subMachine1.addErrorHandler { print("[ERROR][Sub1] \($0.fromState) => \($0.toState)") }
        }

        let subMachine2 = StateMachine<_SubState, NoEvent>(state: .SubState0) { subMachine2 in
            // add Sub2-0 => Sub2-1
            subMachine2.addRoute(.SubState0 => .SubState1)

            subMachine2.addHandler(.Any => .Any) { print("[Sub2] \($0.fromState) => \($0.toState)") }
            subMachine2.addErrorHandler { print("[ERROR][Sub2] \($0.fromState) => \($0.toState)") }
        }

        let mainMachine = StateMachine<_MainState, NoEvent>(state: .MainState0) { mainMachine in

            // add routes & handle for same-subMachine internal transitions
            mainMachine.addRoute(.Any => .Any, condition: { _, fromState, toState, userInfo in

                switch (fromState, toState) {
                    case let (.SubMachine1(state1), .SubMachine1(state2)):
                        return subMachine1.hasRoute(fromState: state1, toState: state2)
                    case let (.SubMachine2(state1), .SubMachine2(state2)):
                        return subMachine2.hasRoute(fromState: state1, toState: state2)
                    default:
                        return false
                }

            }, handler: { _, fromState, toState, userInfo in
                switch (fromState, toState) {
                    case let (.SubMachine1, .SubMachine1(state2)):
                        subMachine1 <- state2
                    case let (.SubMachine2, .SubMachine2(state2)):
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
                    case .MainState0 where subMachine1.state == .SubState0:
                        return .SubMachine1(.SubState0)

                    // "Sub1-1" => "Sub2-0"
                    case let .SubMachine1(state) where state == .SubState1 && subMachine2.state == .SubState0:
                        return .SubMachine2(.SubState0)

                    // "Sub2-1" => "Main0"
                    case let .SubMachine2(state) where state == .SubState1:
                        return .MainState0

                    default:
                        return nil
                }

            }

            mainMachine.addHandler(.Any => .Any) { print("[Main] \($0.fromState) => \($0.toState)") }
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
        XCTAssertTrue(mainMachine.state == .MainState0)
        XCTAssertTrue(subMachine1.state == .SubState0)
        XCTAssertTrue(subMachine2.state == .SubState0)

        // subMachine1 internal routes
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState0) => .SubMachine1(.SubState0)))
        XCTAssertTrue(mainMachine.hasRoute(.SubMachine1(.SubState0) => .SubMachine1(.SubState1)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState1) => .SubMachine1(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState1) => .SubMachine1(.SubState1)))

        // subMachine2 internal routes
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState0) => .SubMachine2(.SubState0)))
        XCTAssertTrue(mainMachine.hasRoute(.SubMachine2(.SubState0) => .SubMachine2(.SubState1)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState1) => .SubMachine2(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState1) => .SubMachine2(.SubState1)))
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
        XCTAssertTrue(mainMachine.state == .MainState0)
        XCTAssertTrue(subMachine1.state == .SubState0)
        XCTAssertTrue(subMachine2.state == .SubState0)

        // from Main0
        XCTAssertTrue(mainMachine.hasRoute(.MainState0 => .SubMachine1(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.MainState0 => .SubMachine1(.SubState1)))
        XCTAssertFalse(mainMachine.hasRoute(.MainState0 => .SubMachine2(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.MainState0 => .SubMachine2(.SubState1)))

        // from Sub1-0
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState0) => .SubMachine2(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState0) => .SubMachine2(.SubState1)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState0) => .MainState0))

        // from Sub1-1
        XCTAssertTrue(mainMachine.hasRoute(.SubMachine1(.SubState1) => .SubMachine2(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState1) => .SubMachine2(.SubState1)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine1(.SubState1) => .MainState0))

        // from Sub2-0
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState0) => .SubMachine1(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState0) => .SubMachine1(.SubState1)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState0) => .MainState0))

        // from Sub2-1
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState1) => .SubMachine1(.SubState0)))
        XCTAssertFalse(mainMachine.hasRoute(.SubMachine2(.SubState1) => .SubMachine1(.SubState1)))
        XCTAssertTrue(mainMachine.hasRoute(.SubMachine2(.SubState1) => .MainState0))

    }

    func testTryState()
    {
        let mainMachine = self.mainMachine!

        // initial
        XCTAssertTrue(mainMachine.state == .MainState0)

        // Main0 => Sub1-0
        mainMachine <- .SubMachine1(.SubState0)
        XCTAssertTrue(mainMachine.state == .SubMachine1(.SubState0))

        // Sub1-0 => Sub1-1 (Sub1 internal transition)
        mainMachine <- .SubMachine1(.SubState1)
        XCTAssertTrue(mainMachine.state == .SubMachine1(.SubState1))

        // Sub1-1 => Sub1-2 (Sub1 internal transition, but fails)
        mainMachine <- .SubMachine1(.SubState2)
        XCTAssertTrue(mainMachine.state == .SubMachine1(.SubState1), "No change.")

        // Sub1-1 => Sub2-2 (fails)
        mainMachine <- .SubMachine2(.SubState2)
        XCTAssertTrue(mainMachine.state == .SubMachine1(.SubState1), "No change.")

        // Sub1-1 => Sub2-0
        mainMachine <- .SubMachine2(.SubState0)
        XCTAssertTrue(mainMachine.state == .SubMachine2(.SubState0))

        // Sub2-0 => Main0 (fails)
        mainMachine <- .MainState0
        XCTAssertTrue(mainMachine.state == .SubMachine2(.SubState0), "No change.")

        // Sub2-0 => Sub2-1
        mainMachine <- .SubMachine2(.SubState1)
        XCTAssertTrue(mainMachine.state == .SubMachine2(.SubState1))

        // Sub2-1 => Main
        mainMachine <- .MainState0
        XCTAssertTrue(mainMachine.state == .MainState0)

    }

    func testAddHandler()
    {
        let mainMachine = self.mainMachine!

        var didPass = false

        // NOTE: this handler is added to mainMachine and doesn't make submachines dirty
        mainMachine.addHandler(.MainState0 => .SubMachine1(.SubState0)) { context in
            print("[Main] 1-1 => 1-2 (specific)")
            didPass = true
        }

        // initial
        XCTAssertTrue(mainMachine.state == .MainState0)
        XCTAssertFalse(didPass)

        // Main0 => Sub1-1 (fails)
        mainMachine <- .SubMachine1(.SubState1)
        XCTAssertTrue(mainMachine.state == .MainState0, "No change.")
        XCTAssertFalse(didPass)

        // Main0 => Sub1-0
        mainMachine <- .SubMachine1(.SubState0)
        XCTAssertTrue(mainMachine.state == .SubMachine1(.SubState0))
        XCTAssertTrue(didPass)
    }

}
