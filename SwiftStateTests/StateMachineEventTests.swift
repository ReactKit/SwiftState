//
//  MachineEventTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class MachineEventTests: _TestCase
{
    func testCanTryEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 & 1 => 2
        // (NOTE: this is not chaining e.g. 0 => 1 => 2)
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        XCTAssertTrue(machine.canTryEvent(.Event0) != nil)
    }
    
    func testTryState()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 & 1 => 2
        // (NOTE: this is not chaining e.g. 0 => 1 => 2)
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        // tryState 0 => 1
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryState 1 => 2
        machine <- .State2
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryState 2 => 3
        let success = machine <- .State3
        XCTAssertEqual(machine.state, MyState.State2)
        XCTAssertFalse(success, "2 => 3 is not registered.")
    }
    
    func testTryEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 => 2
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryEvent
        let success = machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        XCTAssertFalse(success, "Event0 doesn't have 2 => Any")
    }
    
    /// https://github.com/ReactKit/SwiftState/issues/20
    func testTryEvent_issue20()
    {
        let machine = Machine<MyState, MyEvent>(state: MyState.State2) { machine in
            machine.addRouteEvent(.Event0, transitions: [.Any => .State0])
        }
        
        XCTAssertTrue(machine <-! .Event0)
        XCTAssertEqual(machine.state, MyState.State0)
    }
    
    /// https://github.com/ReactKit/SwiftState/issues/28
    func testTryEvent_issue28()
    {
        var eventCount = 0
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            machine.addRoute(.State0 => .State1)
            machine.addRouteEvent(.Event0, transitions: [.Any => .Any]) { _ in
                eventCount++
            }
        }
        
        XCTAssertEqual(eventCount, 0)
        
        machine <-! .Event0
        XCTAssertEqual(eventCount, 1)
        XCTAssertEqual(machine.state, MyState.State0, "State should NOT be changed")
        
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1, "State should be changed")
        
        machine <-! .Event0
        XCTAssertEqual(eventCount, 2)
        XCTAssertEqual(machine.state, MyState.State1, "State should NOT be changed")
    }
    
    func testTryEvent_string()
    {
        let machine = Machine<MyState, String>(state: .State0)
        
        // add 0 => 1 => 2
        machine.addRouteEvent("Run", transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        // tryEvent
        machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryEvent
        let success = machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.State2)
        XCTAssertFalse(success, "Event=Run doesn't have 2 => Any")
    }
    
    func testAddRouteEvent_multiple()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 => 2
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        // add 2 => 1 => 0
        machine.addRouteEvent(.Event1, transitions: [
            .State2 => .State1,
            .State1 => .State0,
        ])
        
        var success: Bool
        
        // tryEvent
        success = machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State0)
        XCTAssertFalse(success, "Event1 doesn't have 0 => Any.")
        
        // tryEvent
        success = machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        XCTAssertTrue(success)
        
        // tryEvent
        success = machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        XCTAssertTrue(success)
        
        // tryEvent
        success = machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        XCTAssertFalse(success, "Event0 doesn't have 2 => Any.")
        
        // tryEvent
        success = machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State1)
        XCTAssertTrue(success)
        
        // tryEvent
        success = machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State0)
        XCTAssertTrue(success)
    }
    
    func testAddRouteEvent_handler()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ], handler: { context in
            invokeCount++
            return 
        })
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        XCTAssertEqual(invokeCount, 2)
    }
    
    func testAddEventHandler()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        machine.addEventHandler(.Event0) { context in
            invokeCount++
            return
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        XCTAssertEqual(invokeCount, 2)
    }
    
    func testRemoveRouteEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        let routeIDs = machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
            ])
        
        machine.addEventHandler(.Event0) { context in
            invokeCount++
            return
        }
        
        // removeRoute
        for routeID in routeIDs {
            machine.removeRoute(routeID)
        }
        
        // tryEvent
        var success = machine <-! .Event0
        XCTAssertFalse(success, "RouteEvent should be removed.")
        
        // tryEvent
        success = machine <-! .Event0
        XCTAssertFalse(success, "RouteEvent should be removed.")
        
        XCTAssertEqual(invokeCount, 0, "EventHandler should NOT be performed")
    }
    
    func testRemoveEventHandler()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteEvent(.Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
            ])
        
        let handlerID = machine.addEventHandler(.Event0) { context in
            invokeCount++
            return
        }
        
        // removeHandler
        machine.removeHandler(handlerID)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1, "0 => 1 should be succesful")
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2, "1 => 2 should be succesful")
        
        XCTAssertEqual(invokeCount, 0, "EventHandler should NOT be performed")
    }
}