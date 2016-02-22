//
//  StateMachineEventTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateMachineEventTests: _TestCase
{
    func testCanTryEvent()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 & 1 => 2
        // (NOTE: this is not chaining e.g. 0 => 1 => 2)
        machine.addRoutes(event: .Event0, transitions: [
            .State0 => .State1,
            .State1 => .State2,
        ])
        
        XCTAssertTrue(machine.canTryEvent(.Event0) != nil)
    }
    
    //--------------------------------------------------
    // MARK: - tryEvent a.k.a `<-!`
    //--------------------------------------------------
    
    func testTryEvent()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0)
        
        // add 0 => 1 => 2
        machine.addRoutes(event: .Event0, transitions: [
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
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2, "Event0 doesn't have 2 => Any")
    }
    
    func testTryEvent_string()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
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
        let machine = StateMachine<MyState, MyEvent>(state: MyState.State2) { machine in
            machine.addRoutes(event: .Event0, transitions: [.Any => .State0])
        }
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State0)
    }
    
    // https://github.com/ReactKit/SwiftState/issues/28
    func testTryEvent_issue28()
    {
        var eventCount = 0
        
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            machine.addRoute(.State0 => .State1)
            machine.addRoutes(event: .Event0, transitions: [.Any => .Any]) { _ in
                eventCount++
            }
        }
        
        XCTAssertEqual(eventCount, 0)
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(eventCount, 1)
        XCTAssertEqual(machine.state, MyState.State0, "State should NOT be changed")
        
        // tryEvent
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1, "State should be changed")
        
        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(eventCount, 2)
        XCTAssertEqual(machine.state, MyState.State1, "State should NOT be changed")
    }
    
    // Fix for transitioning of routes w/ multiple from-states
    // https://github.com/ReactKit/SwiftState/pull/32
    func testTryEvent_issue32()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
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
    
    // MARK: hasRoute + event
    
    func testHasRoute_anyEvent()
    {
        ({
            let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
                machine.addRoute(.State0 => .State1)
                machine.addRoutes(event: .Any, transitions: [.State0 => .State1])
            }
            
            let hasRoute = machine.hasRoute(event: .Event0, transition: .State0 => .State1)
            XCTAssertTrue(hasRoute)
        })()
        
        ({
            let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
                machine.addRoute(.State0 => .State1)
                machine.addRoutes(event: .Any, transitions: [.State2 => .State3])
            }
            
            let hasRoute = machine.hasRoute(event: .Event0, transition: .State0 => .State1)
            XCTAssertFalse(hasRoute)
        })()
    }
    
    // Fix hasRoute() bug when there are routes for no-event & with-event.
    // https://github.com/ReactKit/SwiftState/pull/19
    func testHasRoute_issue19()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            machine.addRoute(.State0 => .State1)    // no-event
            machine.addRoutes(event: .Event0, transitions: [.State1 => .State2])   // with-event
        }
        
        let hasRoute = machine.hasRoute(event: .Event0, transition: .State1 => .State2)
        XCTAssertTrue(hasRoute)
    }
    
    //--------------------------------------------------
    // MARK: - add/removeRoute
    //--------------------------------------------------
    
    func testAddRoute_tryState()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
        
            // add 0 => 1 & 1 => 2
            // (NOTE: this is not chaining e.g. 0 => 1 => 2)
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])
        
        }
        
        // tryState 0 => 1
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1)
        
        // tryState 1 => 2
        machine <- .State2
        XCTAssertEqual(machine.state, MyState.State2)
        
        // tryState 2 => 3
        machine <- .State3
        XCTAssertEqual(machine.state, MyState.State2, "2 => 3 is not registered.")
    }
    
    func testAddRoute_multiple()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            
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
        
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            
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
        
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
        
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
        
        // initial
        XCTAssertEqual(machine.state, MyState.State0)
        
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
        
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            
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
        
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
        
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
    // MARK: - addAnyHandler
    //--------------------------------------------------

    func testAddAnyHandler()
    {
        var invokeCount = 0

        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in

            // add 0 => 1 => 2 (event-based)
            machine.addRoutes(event: .Event0, transitions: [
                .State0 => .State1,
                .State1 => .State2,
            ])

            // add 2 => 3 (state-based)
            machine.addRoute(.State2 => .State3)

            // addAnyHandler (for both event-based & state-based)
            machine.addAnyHandler { context in
                invokeCount++
                return
            }

        }

        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State1)
        XCTAssertEqual(invokeCount, 1)

        // tryEvent
        machine <-! .Event0
        XCTAssertEqual(machine.state, MyState.State2)
        XCTAssertEqual(invokeCount, 2)

        // tryState
        machine <- .State3
        XCTAssertEqual(machine.state, MyState.State3)
        XCTAssertEqual(invokeCount, 3)
        
    }

}
