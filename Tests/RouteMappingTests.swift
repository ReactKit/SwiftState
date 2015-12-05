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
    case Pending
    case Loading(Int)
    
    var hashValue: Int
    {
        switch self {
            case .Pending:
                return "Pending".hashValue
            case let .Loading(x):
                return "Loading\(x)".hashValue
        }
    }
}

private func ==(lhs: _State, rhs: _State) -> Bool
{
    switch (lhs, rhs) {
        case (.Pending, .Pending):
            return true
        case let (.Loading(x1), .Loading(x2)):
            return x1 == x2
        default:
            return false
    }
}

private enum _Event: EventType, Hashable
{
    case CancelAction
    case LoadAction(Int)
    
    var hashValue: Int
    {
        switch self {
            case .CancelAction:
                return "CancelAction".hashValue
            case let .LoadAction(x):
                return "LoadAction\(x)".hashValue
        }
    }
}

private func ==(lhs: _Event, rhs: _Event) -> Bool
{
    switch (lhs, rhs) {
        case (.CancelAction, .CancelAction):
            return true
        case let (.LoadAction(x1), .LoadAction(x2)):
            return x1 == x2
        default:
            return false
    }
}

class RouteMappingTests: _TestCase
{
    func testEventWithAssociatedValue()
    {
        var count = 0
        
        let machine = StateMachine<_State, _Event>(state: .Pending) { machine in
            
            // add EventRouteMapping
            machine.addRouteMapping { event, fromState, userInfo in
                // no routes for no event
                guard let event = event else {
                    return nil
                }
                
                switch event {
                    case .CancelAction:
                        // can transit to `.Pending` if current state is not the same
                        return fromState == .Pending ? nil : .Pending
                    case .LoadAction(let actionId):
                        // can transit to `.Loading(actionId)` if current state is not the same
                        return fromState == .Loading(actionId) ? nil : .Loading(actionId)
                }
            }
            
            // increment `count` when any events i.e. `.CancelAction` and `.LoadAction(x)` succeed.
            machine.addHandler(event: .Any) { event, transition, order, userInfo in
                count++
            }
            
        }
        
        // initial
        XCTAssertEqual(machine.state, _State.Pending)
        XCTAssertEqual(count, 0)
        
        // CancelAction (to .Pending state, same as before)
        machine <-! .CancelAction
        XCTAssertEqual(machine.state, _State.Pending)
        XCTAssertEqual(count, 0, "`tryEvent()` failed, and `count` should not be incremented.")
        
        // LoadAction(1) (to .Loading(1) state)
        machine <-! .LoadAction(1)
        XCTAssertEqual(machine.state, _State.Loading(1))
        XCTAssertEqual(count, 1)
        
        // LoadAction(1) (same as before)
        machine <-! .LoadAction(1)
        XCTAssertEqual(machine.state, _State.Loading(1))
        XCTAssertEqual(count, 1, "`tryEvent()` failed, and `count` should not be incremented.")
        
        machine <-! .LoadAction(2)
        XCTAssertEqual(machine.state, _State.Loading(2))
        XCTAssertEqual(count, 2)
        
        machine <-! .CancelAction
        XCTAssertEqual(machine.state, _State.Pending)
        XCTAssertEqual(count, 3)
    }
    
    func testStateWithAssociatedValue()
    {
        var count = 0
        
        let machine = StateMachine<_State, _Event>(state: .Pending) { machine in
            
            // add StateRouteMapping
            machine.addRouteMapping { fromState, userInfo in
                switch fromState {
                    case .Pending:
                        return [.Loading(1)]
                    case .Loading(let actionId):
                        return [.Loading(actionId+10), .Loading(actionId+100)]
                }
            }
            
            // increment `count` when any events i.e. `.CancelAction` and `.LoadAction(x)` succeed.
            machine.addHandler(.Any => .Any) { event, transition, order, userInfo in
                count++
            }
            
        }
        
        // initial
        XCTAssertEqual(machine.state, _State.Pending)
        XCTAssertEqual(count, 0)
        
        // .Loading(999) (fails)
        machine <- .Loading(999)
        XCTAssertEqual(machine.state, _State.Pending)
        XCTAssertEqual(count, 0, "`tryState()` failed, and `count` should not be incremented.")
        
        // .Loading(1)
        machine <- .Loading(1)
        XCTAssertEqual(machine.state, _State.Loading(1))
        XCTAssertEqual(count, 1)
        
        // .Loading(999) (fails)
        machine <- .Loading(999)
        XCTAssertEqual(machine.state, _State.Loading(1))
        XCTAssertEqual(count, 1, "`tryState()` failed, and `count` should not be incremented.")
        
        machine <- .Loading(11)
        XCTAssertEqual(machine.state, _State.Loading(11))
        XCTAssertEqual(count, 2)
        
        machine <- .Loading(111)
        XCTAssertEqual(machine.state, _State.Loading(111))
        XCTAssertEqual(count, 3)
    }
}
