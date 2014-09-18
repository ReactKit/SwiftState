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
        let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
            
            machine.addRoute(.State0 => .State1)
            machine.addRoute(nil => .State2) { context in println("Any => 2, msg=\(context.userInfo!)") }
            machine.addRoute(.State2 => nil) { context in println("2 => Any, msg=\(context.userInfo!)") }
            
            // add handler (handlerContext = (event, transition, order, userInfo))
            machine.addHandler(.State0 => .State1) { context in
                println("0 => 1")
            }
            
            // add errorHandler
            machine.addErrorHandler { (event, transition, order, userInfo) in
                println("[ERROR] \(transition.fromState) => \(transition.toState)")
            }
        }
        
        // tryState 0 => 1 => 2 => 1 => 0
        machine <- .State1
        machine <- (.State2, "Hello")
        machine <- (.State1, "Bye")
        machine <- .State0  // fail: no 1 => 0
        
        println("machine.state = \(machine.state)")
    }
    
    func testExample()
    {
        let machine = StateMachine<MyState, String>(state: .State0) {
        
            // add 0 => 1
            $0.addRoute(.State0 => .State1) { context in
                println("[Transition 0=>1] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")
            }
            // add 0 => 1 once more
            $0.addRoute(.State0 => .State1) { context in
                println("[Transition 0=>1b] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")
            }
            // add 2 => Any
            $0.addRoute(.State2 => nil) { context in
                println("[Transition exit 2] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue) (Any)")
            }
            // add Any => 2
            $0.addRoute(nil => .State2) { context in
                println("[Transition Entry 2] \(context.transition.fromState.rawValue) (Any) => \(context.transition.toState.rawValue)")
            }
            // add 1 => 0 (no handler)
            $0.addRoute(.State1 => .State0)
            
        }
        
        // 0 => 1
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        
        // 1 => 0
        XCTAssertTrue(machine.hasRoute(.State1 => .State0))
        
        // 2 => Any
        XCTAssertTrue(machine.hasRoute(.State2 => .State0))
        XCTAssertTrue(machine.hasRoute(.State2 => .State1))
        XCTAssertTrue(machine.hasRoute(.State2 => .State2))
        XCTAssertTrue(machine.hasRoute(.State2 => .State3))
        
        // Any => 2
        XCTAssertTrue(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State1 => .State2))
        XCTAssertTrue(machine.hasRoute(.State3 => .State2))
        
        // others
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertFalse(machine.hasRoute(.State0 => .State3))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertFalse(machine.hasRoute(.State1 => .State3))
        XCTAssertFalse(machine.hasRoute(.State3 => .State0))
        XCTAssertFalse(machine.hasRoute(.State3 => .State1))
        XCTAssertFalse(machine.hasRoute(.State3 => .State3))
        
        machine.configure {
            
            // error
            $0.addErrorHandler { context in
                println("[ERROR 1] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")
            }
            
            // entry
            $0.addEntryHandler(.State0) { context in
                println("[Entry 0] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")   // NOTE: this should not be called
            }
            $0.addEntryHandler(.State1) { context in
                println("[Entry 1] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")
            }
            $0.addEntryHandler(.State2) { context in
                println("[Entry 2] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue), userInfo = \(context.userInfo)")
            }
            $0.addEntryHandler(.State2) { context in
                println("[Entry 2b] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue), userInfo = \(context.userInfo)")
            }
            
            // exit
            $0.addExitHandler(.State0) { context in
                println("[Exit 0] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")
            }
            $0.addExitHandler(.State1) { context in
                println("[Exit 1] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue)")
            }
            $0.addExitHandler(.State2) { context in
                println("[Exit 2] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue), userInfo = \(context.userInfo)")
            }
            $0.addExitHandler(.State2) { context in
                println("[Exit 2b] \(context.transition.fromState.rawValue) => \(context.transition.toState.rawValue), userInfo = \(context.userInfo)")
            }
        }
        
        // tryState 0 => 1 => 2 => 1 => 0 => 3
        XCTAssertTrue(machine <- .State1)
        XCTAssertTrue(machine <- (.State2, "State2 activate"))
        XCTAssertTrue(machine <- (.State1, "State2 deactivate"))
        XCTAssertTrue(machine <- .State0)
        XCTAssertFalse(machine <- .State3)
        
        XCTAssertEqual(machine.state, MyState.State0)
    }
}