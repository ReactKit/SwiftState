//
//  FrogcjnTest.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-02.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

// https://github.com/ReactKit/SwiftState/issues/34

private enum _State: StateType, Hashable
{
    case Pending
    case Loading(Int)
    case AnyState
    
    init(nilLiteral: ())
    {
        self = AnyState
    }
    
    var hashValue: Int
    {
        switch self {
            case .Pending:
                return "Pending".hashValue
            case let .Loading(x):
                return "Loading\(x)".hashValue
            case .AnyState:
                return "AnyState".hashValue
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
        case (.AnyState, .AnyState):
            return true
        default:
            return false
    }
}

private enum _Event: StateEventType, Hashable
{
    case CancelAction
    case LoadAction(Int)
    case AnyEvent
    
    init(nilLiteral: ())
    {
        self = AnyEvent
    }
    
    var hashValue: Int
    {
        switch self {
            case .CancelAction:
                return "CancelAction".hashValue
            case let .LoadAction(x):
                return "LoadAction\(x)".hashValue
            case .AnyEvent:
                return "AnyEvent".hashValue
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
        case (.AnyEvent, .AnyEvent):
            return true
        default:
            return false
    }
}

class FrogcjnTest: _TestCase
{
    func testEventWithAssociatedValue()
    {
        var count = 0
        
        let machine = StateMachine<_State, _Event>(state: .Pending) { machine in
            
            machine.addRouteEvent(.CancelAction, transitions: [ .AnyState => .Pending ], condition: { $0.fromState != .Pending })
            
            //
            // If you have **finite** number of `LoadActionId`s (let's say 1 to 100),
            // you can `addRouteEvent()` in finite number of times.
            // (In this case, `LoadActionId` should have enum type instead)
            //
            for actionId in 1...100 {
                machine.addRouteEvent(.LoadAction(actionId), transitions: [ .AnyState => .Loading(actionId) ], condition: { $0.fromState != .Loading(actionId) })
            }
            
            // increment `count` when any events i.e. `.CancelAction` and `.LoadAction(x)` succeed.
            machine.addEventHandler(.AnyEvent) { event, transition, order, userInfo in
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
