//
//  RouteMappingTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-02.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

//
// RouteMapping for StateType & EventType using associated values
//
// https://github.com/ReactKit/SwiftState/issues/34
// https://github.com/ReactKit/SwiftState/pull/36
//

private enum _State: StateType, Hashable
{
    case pending
    case loading(Int)

    var hashValue: Int
    {
        switch self {
            case .pending:
                return "Pending".hashValue
            case let .loading(x):
                return "Loading\(x)".hashValue
        }
    }
}

private func == (lhs: _State, rhs: _State) -> Bool
{
    switch (lhs, rhs) {
        case (.pending, .pending):
            return true
        case let (.loading(x1), .loading(x2)):
            return x1 == x2
        default:
            return false
    }
}

private enum _Event: SwiftState.EventType, Hashable
{
    case cancelAction
    case loadAction(Int)

    var hashValue: Int
    {
        switch self {
            case .cancelAction:
                return "CancelAction".hashValue
            case let .loadAction(x):
                return "LoadAction\(x)".hashValue
        }
    }
}

private func == (lhs: _Event, rhs: _Event) -> Bool
{
    switch (lhs, rhs) {
        case (.cancelAction, .cancelAction):
            return true
        case let (.loadAction(x1), .loadAction(x2)):
            return x1 == x2
        default:
            return false
    }
}

class RouteMappingTests: _TestCase
{
    /// Test for state & event with associated values
    func testAddRouteMapping()
    {
        var count = 0

        let machine = StateMachine<_State, _Event>(state: .pending) { machine in

            machine.addRouteMapping { event, fromState, userInfo in
                // no routes for no event
                guard let event = event else {
                    return nil
                }

                switch event {
                    case .cancelAction:
                        // can transit to `.pending` if current state is not the same
                        return fromState == .pending ? nil : .pending
                    case .loadAction(let actionId):
                        // can transit to `.loading(actionId)` if current state is not the same
                        return fromState == .loading(actionId) ? nil : .loading(actionId)
                }
            }

            // increment `count` when any events i.e. `.cancelAction` and `.loadAction(x)` succeed.
            machine.addHandler(event: .any) { event, transition, order, userInfo in
                count += 1
            }

        }

        // initial
        XCTAssertEqual(machine.state, _State.pending)
        XCTAssertEqual(count, 0)

        // CancelAction (to .pending state, same as before)
        machine <-! .cancelAction
        XCTAssertEqual(machine.state, _State.pending)
        XCTAssertEqual(count, 0, "`tryEvent()` failed, and `count` should not be incremented.")

        // LoadAction(1) (to .loading(1) state)
        machine <-! .loadAction(1)
        XCTAssertEqual(machine.state, _State.loading(1))
        XCTAssertEqual(count, 1)

        // LoadAction(1) (same as before)
        machine <-! .loadAction(1)
        XCTAssertEqual(machine.state, _State.loading(1))
        XCTAssertEqual(count, 1, "`tryEvent()` failed, and `count` should not be incremented.")

        machine <-! .loadAction(2)
        XCTAssertEqual(machine.state, _State.loading(2))
        XCTAssertEqual(count, 2)

        machine <-! .cancelAction
        XCTAssertEqual(machine.state, _State.pending)
        XCTAssertEqual(count, 3)
    }

    /// Test for state with associated values
    func testAddStateRouteMapping()
    {
        var count = 0

        let machine = StateMachine<_State, _Event>(state: .pending) { machine in

            // Add following routes:
            // - `.pending => .loading(1)`
            // - `.loading(x) => .loading(x+10)`
            // - `.loading(x) => .loading(x+100)`
            machine.addStateRouteMapping { fromState, userInfo in
                switch fromState {
                    case .pending:
                        return [.loading(1)]
                    case .loading(let actionId):
                        return [.loading(actionId+10), .loading(actionId+100)]
                }
            }

            // increment `count` when any events i.e. `.cancelAction` and `.loadAction(x)` succeed.
            machine.addHandler(.any => .any) { event, transition, order, userInfo in
                count += 1
            }

        }

        // initial
        XCTAssertEqual(machine.state, _State.pending)
        XCTAssertEqual(count, 0)

        // .loading(999) (fails)
        machine <- .loading(999)
        XCTAssertEqual(machine.state, _State.pending)
        XCTAssertEqual(count, 0, "`tryState()` failed, and `count` should not be incremented.")

        // .loading(1)
        machine <- .loading(1)
        XCTAssertEqual(machine.state, _State.loading(1))
        XCTAssertEqual(count, 1)

        // .loading(999) (fails)
        machine <- .loading(999)
        XCTAssertEqual(machine.state, _State.loading(1))
        XCTAssertEqual(count, 1, "`tryState()` failed, and `count` should not be incremented.")

        machine <- .loading(11)
        XCTAssertEqual(machine.state, _State.loading(11))
        XCTAssertEqual(count, 2)

        machine <- .loading(111)
        XCTAssertEqual(machine.state, _State.loading(111))
        XCTAssertEqual(count, 3)
    }
}
