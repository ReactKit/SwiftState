//
//  StateMachineTests.swift
//  StateMachineTests
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

extension String: StateType, NilLiteralConvertible
{
    public static func convertFromNilLiteral() -> String
    {
        return self.anyState()
    }
}

class StateMachineTests: _TestCase
{
    func testInit()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        XCTAssertEqual(machine.state, MyState.State0)
    }
    
    //--------------------------------------------------
    // MARK: - addRoute
    //--------------------------------------------------
    
    // add state1 => state2
    func testAddRoute()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        machine.addRoute(.State0 => .State1)
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))     // true
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
    }
    
    // add nil => state
    func testAddRoute_fromAnyState()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        machine.addRoute(nil => .State1) // Any => State1
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))     // true
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertTrue(machine.hasRoute(.State1 => .State1))     // true
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
    }
    
    // add state => nil
    func testAddRoute_toAnyState()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        machine.addRoute(.State1 => nil) // State1 => Any
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State1 => .State0))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State1))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State2))     // true
    }
    
    // add nil => nil
    func testAddRoute_bothAnyState()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        machine.addRoute(nil => nil) // Any => Any
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State0))     // true
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))     // true
        XCTAssertTrue(machine.hasRoute(.State0 => .State2))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State0))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State1))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State2))     // true
    }
    
    // add state0 => state0
    func testAddRoute_sameState()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        machine.addRoute(.State0 => .State0)
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State0))
        
        // tryState 0 => 0
        XCTAssertTrue(machine <- .State0)
    }
    
    // add route + condition
    func testAddRoute_condition()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var flag = false
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1, condition: flag)
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        
        flag = true
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
    }
    
    // add route + condition + blacklist
    func testAddRoute_condition_blacklist()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        // add 0 => Any, except 0 => 2
        machine.addRoute(.State0 => nil, condition: { transition in
            return transition.toState != .State2
        })
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State0 => .State3))
    }
    
    // add route + handler
    func testAddRoute_handler()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        
        machine.addRoute(.State0 => .State1) { context in
            returnedTransition = context.transition
        }
        
        XCTAssertTrue(returnedTransition == nil, "Transition has not started yet.")
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition != nil)
        XCTAssertEqual(returnedTransition!.fromState, MyState.State0)
        XCTAssertEqual(returnedTransition!.toState, MyState.State1)
    }
    
    // add route + conditional handler
    func testAddRoute_conditionalHandler()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var flag = false
        var returnedTransition: StateTransition<MyState>?
        
        // add 0 => 1 without condition to guarantee 0 => 1 transition
        machine.addRoute(.State0 => .State1)
        
        // add 0 => 1 with condition + conditionalHandler
        machine.addRoute(.State0 => .State1, condition: flag) { context in
            returnedTransition = context.transition
        }
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertEqual(machine.state, MyState.State1 , "0 => 1 transition should be performed.")
        XCTAssertTrue(returnedTransition == nil, "Conditional handler should NOT be performed because flag=false.")
        
        // add 1 => 0 for resetting state
        machine.addRoute(.State1 => .State0)
        
        // tryState 1 => 0
        machine <- .State0
        
        flag = true
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition != nil)
        XCTAssertEqual(returnedTransition!.fromState, MyState.State0)
        XCTAssertEqual(returnedTransition!.toState, MyState.State1)
    }
    
    //--------------------------------------------------
    // MARK: - removeRoute
    //--------------------------------------------------
    
    func testRemoveRoute()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        let routeID = machine.addRoute(.State0 => .State1)
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        
        var success: Bool
        success = machine.removeRoute(routeID)
        
        XCTAssertTrue(success)
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        
        // fails removing already unregistered route
        success = machine.removeRoute(routeID)
        
        XCTAssertFalse(success)
    }
    
    //--------------------------------------------------
    // MARK: - tryState a.k.a <-
    //--------------------------------------------------
    
    // machine <- state
    func testTryState()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        // tryState 0 => 1, without registering any transitions
        machine <- .State1
        
        XCTAssertEqual(machine.state, MyState.State0, "0 => 1 should fail because transition is not added yet.")
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        // tryState 0 => 1, returning flag
        let success = machine <- .State1
        
        XCTAssertTrue(success)
        XCTAssertEqual(machine.state, MyState.State1)
    }
    
    func testTryState_string()
    {
        let machine = StateMachine<String, String>(state: "0")
        
        // tryState 0 => 1, without registering any transitions
        machine <- "1"
        
        XCTAssertEqual(machine.state, "0", "0 => 1 should fail because transition is not added yet.")
        
        // add 0 => 1
        machine.addRoute("0" => "1")
        
        // tryState 0 => 1, returning flag
        let success = machine <- "1"
        
        XCTAssertTrue(success)
        XCTAssertEqual(machine.state, "1")
    }
    
    //--------------------------------------------------
    // MARK: - addHandler
    //--------------------------------------------------
    
    func testAddHandler()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        machine.addHandler(.State0 => .State1) { context in
//            returnedTransition = context.transition
            }
        
        machine.addHandler(.State0 => .State1) { context in
            returnedTransition = context.transition
        }
        
        // not tried yet
        XCTAssertTrue(returnedTransition == nil, "Transition has not started yet.")
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition != nil)
        XCTAssertEqual(returnedTransition!.fromState, MyState.State0)
        XCTAssertEqual(returnedTransition!.toState, MyState.State1)
    }

    func testAddHandler_order()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        // order = 100 (default)
        machine.addHandler(.State0 => .State1) { context in
            XCTAssertEqual(context.order, 100)
            XCTAssertTrue(returnedTransition != nil, "returnedTransition should already be set.")
            
            returnedTransition = context.transition
        }
        
        // order = 99
        machine.addHandler(.State0 => .State1, order: 99) { context in
            XCTAssertEqual(context.order, 99)
            XCTAssertTrue(returnedTransition == nil, "returnedTransition should NOT be set at this point.")
            
            returnedTransition = context.transition // set returnedTransition for first time
        }
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition != nil)
        XCTAssertEqual(returnedTransition!.fromState, MyState.State0)
        XCTAssertEqual(returnedTransition!.toState, MyState.State1)
    }

    
    func testAddHandler_multiple()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        var returnedTransition2: StateTransition<MyState>?
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        let handlerID = machine.addHandler(.State0 => .State1) { context in
            returnedTransition = context.transition
        }
        
        // add 0 => 1 once more
        machine.addRoute(.State0 => .State1)
        
        let handlerID2 = machine.addHandler(.State0 => .State1) { context in
            returnedTransition2 = context.transition
        }
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition != nil)
        XCTAssertTrue(returnedTransition2 != nil)
    }
    
    func testAddHandler_overload()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        
        machine.addRoute(.State0 => .State1)
        
        machine.addHandler(.State0 => .State1) { context in
            // empty
        }
        
        machine.addHandler(.State0 => .State1) { context in
            returnedTransition = context.transition
        }
    }
    
    //--------------------------------------------------
    // MARK: - removeHandler
    //--------------------------------------------------
    
    func testRemoveHandler()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        var returnedTransition2: StateTransition<MyState>?
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        let handlerID = machine.addHandler(.State0 => .State1) { context in
            returnedTransition = context.transition
            XCTFail("Should never reach here")
        }
        
        // add 0 => 1 once more
        machine.addRoute(.State0 => .State1)
        
        let handlerID2 = machine.addHandler(.State0 => .State1) { context in
            returnedTransition2 = context.transition
        }
        
        machine.removeHandler(handlerID)
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition == nil, "Handler should be removed and never performed.")
        XCTAssertTrue(returnedTransition2 != nil)
    }
    
    func testRemoveHandler_unregistered()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        let handlerID = machine.addHandler(.State0 => .State1) { context in
            // empty
        }
        
        // remove handler
        XCTAssertTrue(machine.removeHandler(handlerID))
        
        // remove already unregistered handler
        XCTAssertFalse(machine.removeHandler(handlerID), "removeHandler should fail because handler is already removed.")
    }
    
    func testRemoveErrorHandler()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var returnedTransition: StateTransition<MyState>?
        var returnedTransition2: StateTransition<MyState>?
        
        // add 2 => 1
        machine.addRoute(.State2 => .State1)
        
        let handlerID = machine.addErrorHandler { context in
            returnedTransition = context.transition
            XCTFail("Should never reach here")
        }
        
        // add 2 => 1 once more
        machine.addRoute(.State2 => .State1)
        
        let handlerID2 = machine.addErrorHandler { context in
            returnedTransition2 = context.transition
        }
        
        machine.removeHandler(handlerID)
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(returnedTransition == nil, "Handler should be removed and never performed.")
        XCTAssertTrue(returnedTransition2 != nil)
    }
    
    func testRemoveErrorHandler_unregistered()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        let handlerID = machine.addErrorHandler { context in
            // empty
        }
        
        // remove handler
        XCTAssertTrue(machine.removeHandler(handlerID))
        
        // remove already unregistered handler
        XCTAssertFalse(machine.removeHandler(handlerID), "removeHandler should fail because handler is already removed.")
    }
}
