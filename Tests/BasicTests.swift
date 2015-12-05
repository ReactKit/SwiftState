//
//  BasicTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/08.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class BasicTests: _TestCase
{
    func testREADME()
    {
        // setup state machine
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            
            machine.addRoute(.State0 => .State1)
            machine.addRoute(.Any => .State2) { context in print("Any => 2, msg=\(context.userInfo)") }
            machine.addRoute(.State2 => .Any) { context in print("2 => Any, msg=\(context.userInfo)") }
            
            // add handler (`context = (event, fromState, toState, userInfo)`)
            machine.addHandler(.State0 => .State1) { context in
                print("0 => 1")
            }
            
            // add errorHandler
            machine.addErrorHandler { event, fromState, toState, userInfo in
                print("[ERROR] \(fromState) => \(toState)")
            }
        }
        
        // initial
        XCTAssertEqual(machine.state, MyState.State0)
        
        // tryState 0 => 1 => 2 => 1 => 0
        
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1)
        
        machine <- (.State2, "Hello")
        XCTAssertEqual(machine.state, MyState.State2)
        
        machine <- (.State1, "Bye")
        XCTAssertEqual(machine.state, MyState.State1)
        
        machine <- .State0  // fail: no 1 => 0
        XCTAssertEqual(machine.state, MyState.State1)
    }
    
    func testREADME_tryEvent()
    {
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            
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
}