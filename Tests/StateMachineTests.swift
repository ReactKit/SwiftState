//
//  StateMachineTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateMachineTests: _TestCase
{
    func testInit()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0)
        
        XCTAssertEqual(machine.state, MyState.State0)
    }
    
    //--------------------------------------------------
    // MARK: - tryState a.k.a `<-`
    //--------------------------------------------------
    
    // machine <- state
    func testTryState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0)
        
        // tryState 0 => 1, without registering any transitions
        machine <- .State1
        
        XCTAssertEqual(machine.state, MyState.State0, "0 => 1 should fail because transition is not added yet.")
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        // tryState 0 => 1
        machine <- .State1
        XCTAssertEqual(machine.state, MyState.State1)
    }
    
    func testTryState_string()
    {
        let machine = StateMachine<String, NoEvent>(state: "0")
        
        // tryState 0 => 1, without registering any transitions
        machine <- "1"
        
        XCTAssertEqual(machine.state, "0", "0 => 1 should fail because transition is not added yet.")
        
        // add 0 => 1
        machine.addRoute("0" => "1")
        
        // tryState 0 => 1
        machine <- "1"
        XCTAssertEqual(machine.state, "1")
    }
    
    //--------------------------------------------------
    // MARK: - addRoute
    //--------------------------------------------------
    
    // add state1 => state2
    func testAddRoute()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            machine.addRoute(.State0 => .State1)
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))     // true
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
    }
    
    // add .Any => state
    func testAddRoute_fromAnyState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            machine.addRoute(.Any => .State1) // Any => State1
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))     // true
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertTrue(machine.hasRoute(.State1 => .State1))     // true
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
    }
    
    // add state => .Any
    func testAddRoute_toAnyState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            machine.addRoute(.State1 => .Any) // State1 => Any
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State1 => .State0))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State1))     // true
        XCTAssertTrue(machine.hasRoute(.State1 => .State2))     // true
    }
    
    // add .Any => .Any
    func testAddRoute_bothAnyState()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            machine.addRoute(.Any => .Any) // Any => Any
        }
        
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
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            machine.addRoute(.State0 => .State0)
        }
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State0))
    }
    
    // add route + condition
    func testAddRoute_condition()
    {
        var flag = false
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            // add 0 => 1
            machine.addRoute(.State0 => .State1, condition: { _ in flag })
        
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        
        flag = true
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
    }
    
    // add route + condition + blacklist
    func testAddRoute_condition_blacklist()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            // add 0 => Any, except 0 => 2
            machine.addRoute(.State0 => .Any, condition: { context in
                return context.toState != .State2
            })
        }
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State0 => .State3))
    }
    
    // add route + handler
    func testAddRoute_handler()
    {
        var invokedCount = 0
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            
            machine.addRoute(.State0 => .State1) { context in
                XCTAssertEqual(context.fromState, MyState.State0)
                XCTAssertEqual(context.toState, MyState.State1)
                
                invokedCount++
            }
            
        }
        
        XCTAssertEqual(invokedCount, 0, "Transition has not started yet.")
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertEqual(invokedCount, 1)
    }
    
    // add route + conditional handler
    func testAddRoute_conditionalHandler()
    {
        var invokedCount = 0
        var flag = false
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1 without condition to guarantee 0 => 1 transition
            machine.addRoute(.State0 => .State1)
            
            // add 0 => 1 with condition + conditionalHandler
            machine.addRoute(.State0 => .State1, condition: { _ in flag }) { context in
                XCTAssertEqual(context.fromState, MyState.State0)
                XCTAssertEqual(context.toState, MyState.State1)
                
                invokedCount++
            }
            
            // add 1 => 0 for resetting state
            machine.addRoute(.State1 => .State0)
            
        }
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertEqual(machine.state, MyState.State1)
        XCTAssertEqual(invokedCount, 0, "Conditional handler should NOT be performed because flag=false.")
        
        // tryState 1 => 0 (resetting to 0)
        machine <- .State0
        
        XCTAssertEqual(machine.state, MyState.State0)
        
        flag = true
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertEqual(machine.state, MyState.State1)
        XCTAssertEqual(invokedCount, 1)
        
    }
    
    // MARK: addRoute using array
    
    func testAddRoute_array_left()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            // add 0 => 2 or 1 => 2
            machine.addRoute([.State0, .State1] => .State2)
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        XCTAssertTrue(machine.hasRoute(.State0 => .State2))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertTrue(machine.hasRoute(.State1 => .State2))
    }
    
    func testAddRoute_array_right()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            // add 0 => 1 or 0 => 2
            machine.addRoute(.State0 => [.State1, .State2])
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        XCTAssertTrue(machine.hasRoute(.State0 => .State2))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
    }
    
    func testAddRoute_array_both()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            // add 0 => 2 or 0 => 3 or 1 => 2 or 1 => 3
            machine.addRoute([MyState.State0, MyState.State1] => [MyState.State2, MyState.State3])
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        XCTAssertTrue(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State0 => .State3))
        XCTAssertFalse(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertTrue(machine.hasRoute(.State1 => .State2))
        XCTAssertTrue(machine.hasRoute(.State1 => .State3))
        XCTAssertFalse(machine.hasRoute(.State2 => .State0))
        XCTAssertFalse(machine.hasRoute(.State2 => .State1))
        XCTAssertFalse(machine.hasRoute(.State2 => .State2))
        XCTAssertFalse(machine.hasRoute(.State2 => .State3))
        XCTAssertFalse(machine.hasRoute(.State3 => .State0))
        XCTAssertFalse(machine.hasRoute(.State3 => .State1))
        XCTAssertFalse(machine.hasRoute(.State3 => .State2))
        XCTAssertFalse(machine.hasRoute(.State3 => .State3))
    }
    
    //--------------------------------------------------
    // MARK: - removeRoute
    //--------------------------------------------------
    
    func testRemoveRoute()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0)
        
        let routeDisposable = machine.addRoute(.State0 => .State1)
        
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        
        // remove route
        routeDisposable.dispose()
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
    }
    
    //--------------------------------------------------
    // MARK: - addHandler
    //--------------------------------------------------
    
    func testAddHandler()
    {
        var invokedCount = 0
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1
            machine.addRoute(.State0 => .State1)
            
            machine.addHandler(.State0 => .State1) { context in
                XCTAssertEqual(context.fromState, MyState.State0)
                XCTAssertEqual(context.toState, MyState.State1)
                
                invokedCount++
            }
        
        }
        
        // not tried yet
        XCTAssertEqual(invokedCount, 0, "Transition has not started yet.")
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertEqual(invokedCount, 1)
    }

    func testAddHandler_order()
    {
        var invokedCount = 0
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1
            machine.addRoute(.State0 => .State1)
            
            // order = 100 (default)
            machine.addHandler(.State0 => .State1) { context in
                XCTAssertEqual(invokedCount, 1)
                
                XCTAssertEqual(context.fromState, MyState.State0)
                XCTAssertEqual(context.toState, MyState.State1)
                
                invokedCount++
            }
            
            // order = 99
            machine.addHandler(.State0 => .State1, order: 99) { context in
                XCTAssertEqual(invokedCount, 0)
                
                XCTAssertEqual(context.fromState, MyState.State0)
                XCTAssertEqual(context.toState, MyState.State1)
                
                invokedCount++
            }
        
        }
        
        XCTAssertEqual(invokedCount, 0)
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertEqual(invokedCount, 2)
    }

    
    func testAddHandler_multiple()
    {
        var passed1 = false
        var passed2 = false
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1
            machine.addRoute(.State0 => .State1)
            
            machine.addHandler(.State0 => .State1) { context in
                passed1 = true
            }
            
            // add 0 => 1 once more
            machine.addRoute(.State0 => .State1)
            
            machine.addHandler(.State0 => .State1) { context in
                passed2 = true
            }
        
        }
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(passed1)
        XCTAssertTrue(passed2)
    }
    
    func testAddHandler_overload()
    {
        var passed = false
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            machine.addRoute(.State0 => .State1)
            
            machine.addHandler(.State0 => .State1) { context in
                // empty
            }
            
            machine.addHandler(.State0 => .State1) { context in
                passed = true
            }

        }
        
        XCTAssertFalse(passed)

        machine <- .State1

        XCTAssertTrue(passed)
    }
    
    //--------------------------------------------------
    // MARK: - removeHandler
    //--------------------------------------------------
    
    func testRemoveHandler()
    {
        var passed = false
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 0 => 1
            machine.addRoute(.State0 => .State1)
            
            let handlerDisposable = machine.addHandler(.State0 => .State1) { context in
                XCTFail("Should never reach here")
            }
            
            // add 0 => 1 once more
            machine.addRoute(.State0 => .State1)
            
            machine.addHandler(.State0 => .State1) { context in
                passed = true
            }
            
            // remove handler
            handlerDisposable.dispose()
        
        }
        
        XCTAssertFalse(passed)
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(passed)
    }
    
    func testRemoveHandler_unregistered()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0)
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        let handlerDisposable = machine.addHandler(.State0 => .State1) { context in
            // empty
        }
        
        XCTAssertFalse(handlerDisposable.disposed)
        
        // remove handler
        handlerDisposable.dispose()
        
        // remove already unregistered handler
        XCTAssertTrue(handlerDisposable.disposed, "removeHandler should fail because handler is already removed.")
    }
    
    func testRemoveErrorHandler()
    {
        var passed = false
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
        
            // add 2 => 1
            machine.addRoute(.State2 => .State1)
            
            let handlerDisposable = machine.addErrorHandler { context in
                XCTFail("Should never reach here")
            }
            
            // add 2 => 1 once more
            machine.addRoute(.State2 => .State1)
            
            machine.addErrorHandler { context in
                passed = true
            }
            
            // remove handler
            handlerDisposable.dispose()
        
        }
        
        // tryState 0 => 1
        machine <- .State1
        
        XCTAssertTrue(passed)
    }
    
    func testRemoveErrorHandler_unregistered()
    {
        let machine = StateMachine<MyState, NoEvent>(state: .State0)
        
        // add 0 => 1
        machine.addRoute(.State0 => .State1)
        
        let handlerDisposable = machine.addErrorHandler { context in
            // empty
        }
        
        XCTAssertFalse(handlerDisposable.disposed)
        
        // remove handler
        handlerDisposable.dispose()
        
        // remove already unregistered handler
        XCTAssertTrue(handlerDisposable.disposed, "removeHandler should fail because handler is already removed.")
    }
    
    //--------------------------------------------------
    // MARK: - StateRouteMapping
    //--------------------------------------------------
    
    func testStateRouteMapping()
    {
        var routeMappingDisposable: Disposable?
        
        let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
            
            // add 0 => 1 & 0 => 2 (using `StateRouteMapping` closure)
            routeMappingDisposable = machine.addRouteMapping { fromState, userInfo -> [MyState]? in
                if fromState == .State0 {
                    return [.State1, .State2]
                }
                else {
                    return nil
                }
            }
            
            // add 1 => 0 (can also use `EventRouteMapping` closure for single-`toState`)
            machine.addRouteMapping { event, fromState, userInfo -> MyState? in
                guard event == nil else { return nil }
                
                if fromState == .State1 {
                    return .State0
                }
                else {
                    return nil
                }
            }
        }
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertTrue(machine.hasRoute(.State0 => .State1))
        XCTAssertTrue(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
        XCTAssertFalse(machine.hasRoute(.State2 => .State0))
        XCTAssertFalse(machine.hasRoute(.State2 => .State1))
        XCTAssertFalse(machine.hasRoute(.State2 => .State2))
        
        // remove routeMapping
        routeMappingDisposable?.dispose()
        
        XCTAssertFalse(machine.hasRoute(.State0 => .State0))
        XCTAssertFalse(machine.hasRoute(.State0 => .State1))
        XCTAssertFalse(machine.hasRoute(.State0 => .State2))
        XCTAssertTrue(machine.hasRoute(.State1 => .State0))
        XCTAssertFalse(machine.hasRoute(.State1 => .State1))
        XCTAssertFalse(machine.hasRoute(.State1 => .State2))
        XCTAssertFalse(machine.hasRoute(.State2 => .State0))
        XCTAssertFalse(machine.hasRoute(.State2 => .State1))
        XCTAssertFalse(machine.hasRoute(.State2 => .State2))
    }
}
