//
//  MiscTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

/// Unarranged tests.
class MiscTests: _TestCase
{
    func testREADME_string()
    {
        let machine = StateMachine<String, NoEvent>(state: ".State0") { machine in
            
            machine.addRoute(".State0" => ".State1")
            machine.addRoute(.Any => ".State2") { context in print("Any => 2, msg=\(context.userInfo)") }
            machine.addRoute(".State2" => .Any) { context in print("2 => Any, msg=\(context.userInfo)") }
            
            // add handler (handlerContext = (event, transition, order, userInfo))
            machine.addHandler(".State0" => ".State1") { context in
                print("0 => 1")
            }
            
            // add errorHandler
            machine.addErrorHandler { event, fromState, toState, userInfo in
                print("[ERROR] \(fromState) => \(toState)")
            }
        }
        
        // tryState 0 => 1 => 2 => 1 => 0
        
        machine <- ".State1"
        XCTAssertEqual(machine.state, ".State1")
        
        machine <- (".State2", "Hello")
        XCTAssertEqual(machine.state, ".State2")
        
        machine <- (".State1", "Bye")
        XCTAssertEqual(machine.state, ".State1")
        
        machine <- ".State0"  // fail: no 1 => 0
        XCTAssertEqual(machine.state, ".State1")
        
        print("machine.state = \(machine.state)")
    }
    
    // StateType + associated value
    func testREADME_associatedValue()
    {
        let machine = StateMachine<StrState, StrEvent>(state: .Str("0")) { machine in
            
            machine.addRoute(.Str("0") => .Str("1"))
            machine.addRoute(.Any => .Str("2")) { context in print("Any => 2, msg=\(context.userInfo)") }
            machine.addRoute(.Str("2") => .Any) { context in print("2 => Any, msg=\(context.userInfo)") }
            
            // add handler (handlerContext = (event, transition, order, userInfo))
            machine.addHandler(.Str("0") => .Str("1")) { context in
                print("0 => 1")
            }
            
            // add errorHandler
            machine.addErrorHandler { event, fromState, toState, userInfo in
                print("[ERROR] \(fromState) => \(toState)")
            }
        }
        
        // tryState 0 => 1 => 2 => 1 => 0
        
        machine <- .Str("1")
        XCTAssertEqual(machine.state, StrState.Str("1"))
        
        machine <- (.Str("2"), "Hello")
        XCTAssertEqual(machine.state, StrState.Str("2"))
        
        machine <- (.Str("1"), "Bye")
        XCTAssertEqual(machine.state, StrState.Str("1"))
        
        machine <- .Str("0")  // fail: no 1 => 0
        XCTAssertEqual(machine.state, StrState.Str("1"))
        
        print("machine.state = \(machine.state)")
    }
    
    func testExample()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) {
            
            // add 0 => 1
            $0.addRoute(.State0 => .State1) { context in
                print("[Transition 0=>1] \(context.fromState) => \(context.toState)")
            }
            // add 0 => 1 once more
            $0.addRoute(.State0 => .State1) { context in
                print("[Transition 0=>1b] \(context.fromState) => \(context.toState)")
            }
            // add 2 => Any
            $0.addRoute(.State2 => .Any) { context in
                print("[Transition exit 2] \(context.fromState) => \(context.toState) (Any)")
            }
            // add Any => 2
            $0.addRoute(.Any => .State2) { context in
                print("[Transition Entry 2] \(context.fromState) (Any) => \(context.toState)")
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
            
            // add error handlers
            $0.addErrorHandler { context in
                print("[ERROR 1] \(context.fromState) => \(context.toState)")
            }
            
            // add entry handlers
            $0.addHandler(.Any => .State0) { context in
                print("[Entry 0] \(context.fromState) => \(context.toState)")   // NOTE: this should not be called
            }
            $0.addHandler(.Any => .State1) { context in
                print("[Entry 1] \(context.fromState) => \(context.toState)")
            }
            $0.addHandler(.Any => .State2) { context in
                print("[Entry 2] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
            $0.addHandler(.Any => .State2) { context in
                print("[Entry 2b] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
            
            // add exit handlers
            $0.addHandler(.State0 => .Any) { context in
                print("[Exit 0] \(context.fromState) => \(context.toState)")
            }
            $0.addHandler(.State1 => .Any) { context in
                print("[Exit 1] \(context.fromState) => \(context.toState)")
            }
            $0.addHandler(.State2 => .Any) { context in
                print("[Exit 2] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
            $0.addHandler(.State2 => .Any) { context in
                print("[Exit 2b] \(context.fromState) => \(context.toState), userInfo = \(context.userInfo)")
            }
        }
        
        XCTAssertEqual(machine.state, MyState.State0)
        
        // tryState 0 => 1 => 2 => 1 => 0 => 3
        
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1)
        
        machine <- (.State2, "State2 activate")
        XCTAssertEqual(machine.state, MyState.State2)
        
        machine <- (.State1, "State2 deactivate")
        XCTAssertEqual(machine.state, MyState.State1)
        
        machine <- .State0
        XCTAssertEqual(machine.state, MyState.State0)
        
        machine <- .State3
        XCTAssertEqual(machine.state, MyState.State0, "No 0 => 3.")
    }
}