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
        
        let machine = Machine<_State, _Event>(state: .Pending) { machine in
            
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
            machine.addEventHandler(.Any) { event, transition, order, userInfo in
                count++
            }
            
        }
        
        // initial
        XCTAssertTrue(machine.state == .Pending)
        XCTAssertEqual(count, 0)
        
        // CancelAction (to .Pending state, same as before)
        machine <-! .CancelAction
        XCTAssertTrue(machine.state == .Pending)
        XCTAssertEqual(count, 0, "`tryEvent()` failed, and `count` should not be incremented.")
        
        // LoadAction(1) (to .Loading(1) state)
        machine <-! .LoadAction(1)
        XCTAssertTrue(machine.state == .Loading(1))
        XCTAssertEqual(count, 1)
        
        // LoadAction(1) (same as before)
        machine <-! .LoadAction(1)
        print(machine.state)
        XCTAssertTrue(machine.state == .Loading(1))
        XCTAssertEqual(count, 1, "`tryEvent()` failed, and `count` should not be incremented.")
        
        machine <-! .LoadAction(2)
        XCTAssertTrue(machine.state == .Loading(2))
        XCTAssertEqual(count, 2)
        
        machine <-! .CancelAction
        XCTAssertTrue(machine.state == .Pending)
        XCTAssertEqual(count, 3)
    }
}
