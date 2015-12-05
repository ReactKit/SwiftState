//
//  MachineTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class MachineTests: _TestCase
{
    //--------------------------------------------------
    // MARK: - tryEvent a.k.a `<-!`
    //--------------------------------------------------
    
    func testCanTryEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 & 1 => 2
        // (NOTE: this is not chaining e.g. 0 => 1 => 2)
        machine.addRoutes(event: .Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        XCTAssertTrue(machine.canTryEvent(.Event0) != nil)
    }
    
    func testTryEvent()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            // add 0 => 1 => 2
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2, "Event0 doesn't have 2 => Any")
    }
    
    func testTryEvent_customOperator()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            // add 0 => 1
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
            ])
            // add 0 => 1
            machine.addRoutes(event: .Event1, transitions: [
                .State1 => .State2,
            ])
        }
        
        // tryEvent (twice)
        machine <-! .Event0 <-! .Event1
        XCTAssertEqual(machine.state, MyState.State2)
    }
    
    func testTryEvent_string()
    {
        let machine = Machine<MyState, String>(state: .State0)
        
        // add 0 => 1 => 2
        machine.addRoutes(event: "Run", transitions: [
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
        machine <-! "Run"
        XCTAssertEqual(machine.state, MyState.State2, "Event=Run doesn't have 2 => Any")
    }
    
    // https://github.com/ReactKit/SwiftState/issues/20
    func testTryEvent_issue20()
    {
        let machine = Machine<MyState, MyEvent>(state: MyState.State2) { machine in
            machine.addRoutes(event: .Event0, transitions: [.Any => .State0])
        }
        
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State0)
    }
    
    // Fix for transitioning of routes w/ multiple from-states
    // https://github.com/ReactKit/SwiftState/pull/32
    func testTryEvent_issue32()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            machine.addRoutes(event: .Event0, transitions: [ .State0 => .State1 ])
            machine.addRoutes(event: .Event1, routes: [ [ .State1, .State2 ] => .State3 ])
        }
        
        XCTAssertEqual(machine.state, MyState.State0)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State3)
    }
    
    //--------------------------------------------------
    // MARK: - add/removeRoute
    //--------------------------------------------------
    
    func testAddRoute_multiple()
    {
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            
            // add 0 => 1 => 2
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])
            
            // add 2 => 1 => 0
            machine.addRoutes(event: .Event1, transitions: [
                .State2 => .State1,
                .State1 => .State0,
            ])
        }
        
        // initial
        XCTAssertEqual(machine.state, MyState.State0)
        
        // tryEvent
        machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State0, "Event1 doesn't have 0 => Any.")
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2, "Event0 doesn't have 2 => Any.")
        
        // tryEvent
        machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event1
        XCTAssertEqual(machine.state, MyState.State0)
    }
    
    func testAddRoute_handler()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            // add 0 => 1 => 2
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ], handler: { context in
                invokeCount++
                return 
            })
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        XCTAssertEqual(invokeCount, 2)
    }
    
    func testRemoveRoute()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            let routeDisposable = machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])
            
            machine.addHandler(event: .Event0) { context in
                invokeCount++
                return
            }
            
            // removeRoute
            routeDisposable.dispose()
            
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State0, "Route should be removed.")
        
        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")
    }
    
    //--------------------------------------------------
    // MARK: - add/removeHandler
    //--------------------------------------------------
    
    func testAddHandler()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
            
            // add 0 => 1 => 2
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])
            
            machine.addHandler(event: .Event0) { context in
                invokeCount++
                return
            }
            
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        
        XCTAssertEqual(invokeCount, 2)
    }
    
    func testRemoveHandler()
    {
        var invokeCount = 0
        
        let machine = Machine<MyState, MyEvent>(state: .State0) { machine in
        
            // add 0 => 1 => 2
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])
            
            let handlerDisposable = machine.addHandler(event: .Event0) { context in
                invokeCount++
                return
            }
        
            // remove handler
            handlerDisposable.dispose()
            
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1, "0 => 1 should be succesful")
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2, "1 => 2 should be succesful")
        
        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")
    }
    
    //--------------------------------------------------
    // MARK: - EventRouteMapping
    //--------------------------------------------------
    
    func testAddEventRouteMapping()
    {
        var invokeCount = 0
        
        let machine = Machine<StrState, StrEvent>(state: .Str("initial")) { machine in
            
            // add EventRouteMapping
            machine.addRouteMapping { event, fromState, userInfo -> StrState? in
                // no route for no-event
                guard let event = event else { return nil }
                
                switch (event, fromState) {
                    case (.Str("gogogo"), .Str("initial")):
                        return .Str("Phase 1")
                    case (.Str("gogogo"), .Str("Phase 1")):
                        return .Str("Phase 2")
                    case (.Str("finish"), .Str("Phase 2")):
                        return .Str("end")
                    default:
                        return nil
                }
            }
            
            machine.addHandler(event: .Str("gogogo")) { context in
                invokeCount++
                return
            }
            
        }
        
        // initial
        XCTAssertEqual(machine.state, StrState.Str("initial"))
        
        // tryEvent (fails)
        machine <-! .Str("go?")
        XCTAssertEqual(machine.state, StrState.Str("initial"), "No change.")
        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed")
        
        // tryEvent
        machine <-! .Str("gogogo")
        XCTAssertEqual(machine.state, StrState.Str("Phase 1"))
        XCTAssertEqual(invokeCount, 1)
        
        // tryEvent (fails)
        machine <-! .Str("finish")
        XCTAssertEqual(machine.state, StrState.Str("Phase 1"), "No change.")
        XCTAssertEqual(invokeCount, 1, "Handler should NOT be performed")
        
        // tryEvent
        machine <-! .Str("gogogo")
        XCTAssertEqual(machine.state, StrState.Str("Phase 2"))
        XCTAssertEqual(invokeCount, 2)
        
        // tryEvent (fails)
        machine <-! .Str("gogogo")
        XCTAssertEqual(machine.state, StrState.Str("Phase 2"), "No change.")
        XCTAssertEqual(invokeCount, 2, "Handler should NOT be performed")
        
        // tryEvent
        machine <-! .Str("finish")
        XCTAssertEqual(machine.state, StrState.Str("end"))
        XCTAssertEqual(invokeCount, 2, "gogogo-Handler should NOT be performed")
        
    }
    
}