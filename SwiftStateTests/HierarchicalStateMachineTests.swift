//
//  HierarchicalStateMachineTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/10/13.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class HierarchicalStateMachineTests: _TestCase
{
    var mainMachine: HSM?
    var sub1Machine: HSM?
    var sub2Machine: HSM?
    
    //
    // set up hierarchical state machines as following:
    //
    // - mainMachine
    //   - sub1Machine
    //     - State1 (substate)
    //     - State2 (substate)
    //   - sub2Machine
    //     - State1 (substate)
    //     - State2 (substate)
    //   - MainState0 (state)
    //
    override func setUp()
    {
        super.setUp()
    
        let sub1Machine = HSM(name: "Sub1", state: "State1")
        let sub2Machine = HSM(name: "Sub2", state: "State1")
        
        // [sub1] add 1-1 => 1-2
        sub1Machine.addRoute("State1" => "State2")
        
        // [sub2] add 2-1 => 2-2
        sub2Machine.addRoute("State1" => "State2")
  
        // create mainMachine with configuring submachines
        // NOTE: accessing submachine's state will be of form: "\(submachine.name).\(substate)"
        let mainMachine = HSM(name: "Main", submachines:[sub1Machine, sub2Machine], state: "Sub1.State1")
        
        // [main] add '1-2 => 2-1' & '2-2 => 0' & '0 => 1-1' (switching submachine)
        // NOTE: MainState0 does not belong to any submachine's state
        mainMachine.addRoute("Sub1.State2" => "Sub2.State1")
        mainMachine.addRoute("Sub2.State2" => "MainState0")
        mainMachine.addRoute("MainState0" => "Sub1.State1")
        
        // add logging handlers
        sub1Machine.addHandler(nil => nil) { print("[Sub1] \($0.transition)") }
        sub1Machine.addErrorHandler { print("[ERROR][Sub1] \($0.transition)") }
        sub2Machine.addHandler(nil => nil) { print("[Sub2] \($0.transition)") }
        sub2Machine.addErrorHandler { print("[ERROR][Sub2] \($0.transition)") }
        mainMachine.addHandler(nil => nil) { print("[Main] \($0.transition)") }
        mainMachine.addErrorHandler { print("[ERROR][Main] \($0.transition)") }
        
        self.mainMachine = mainMachine
        self.sub1Machine = sub1Machine
        self.sub2Machine = sub2Machine
    }
    
    func testHasRoute_submachine_internal()
    {
        let mainMachine = self.mainMachine!
        
        // NOTE: mainMachine can check submachine's internal routes
        
        // sub1 internal routes
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State1" => "Sub1.State1"))
        XCTAssertTrue(mainMachine.hasRoute("Sub1.State1" => "Sub1.State2"))     // 1-1 => 1-2
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State2" => "Sub1.State1"))
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State2" => "Sub1.State2"))
        
        // sub2 internal routes
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State1" => "Sub2.State1"))
        XCTAssertTrue(mainMachine.hasRoute("Sub2.State1" => "Sub2.State2"))     // 2-1 => 2-2
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State2" => "Sub2.State1"))
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State2" => "Sub2.State2"))
    }
    
    func testHasRoute_submachine_switching()
    {
        let mainMachine = self.mainMachine!
        
        // NOTE: mainMachine can check switchable submachines
        // (external routes between submachines = Sub1, Sub2, or nil)
        
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State1" => "Sub2.State1"))
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State1" => "Sub2.State2"))
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State1" => "MainState0"))
        XCTAssertTrue(mainMachine.hasRoute("Sub1.State2" => "Sub2.State1"))     // 1-2 => 2-1
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State2" => "Sub2.State2"))
        XCTAssertFalse(mainMachine.hasRoute("Sub1.State2" => "MainState0"))
        
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State1" => "Sub1.State1"))
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State1" => "Sub1.State2"))
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State1" => "MainState0"))
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State2" => "Sub1.State1"))
        XCTAssertFalse(mainMachine.hasRoute("Sub2.State2" => "Sub1.State2"))
        XCTAssertTrue(mainMachine.hasRoute("Sub2.State2" => "MainState0"))      // 2-2 => 0
        
        XCTAssertTrue(mainMachine.hasRoute("MainState0" => "Sub1.State1"))      // 0 => 1-1
        XCTAssertFalse(mainMachine.hasRoute("MainState0" => "Sub1.State2"))
        XCTAssertFalse(mainMachine.hasRoute("MainState0" => "Sub2.State1"))
        XCTAssertFalse(mainMachine.hasRoute("MainState0" => "Sub2.State2"))
    }
    
    func testTryState()
    {
        let mainMachine = self.mainMachine!
        let sub1Machine = self.sub1Machine!
        
        XCTAssertEqual(mainMachine.state, "Sub1.State1")
        
        // 1-1 => 1-2 (sub1 internal transition)
        mainMachine <- "Sub1.State2"
        XCTAssertEqual(mainMachine.state, "Sub1.State2")
        
        // dummy
        mainMachine <- "DUMMY"
        XCTAssertEqual(mainMachine.state, "Sub1.State2", "mainMachine.state should not be updated because there is no 1-2 => DUMMY route.")
        
        // 1-2 => 2-1 (sub1 => sub2 external transition)
        mainMachine <- "Sub2.State1"
        XCTAssertEqual(mainMachine.state, "Sub2.State1")
        
        // dummy
        mainMachine <- "MainState0"
        XCTAssertEqual(mainMachine.state, "Sub2.State1", "mainMachine.state should not be updated because there is no 2-1 => 0 route.")
        
        // 2-1 => 2-2 (sub1 internal transition)
        mainMachine <- "Sub2.State2"
        XCTAssertEqual(mainMachine.state, "Sub2.State2")
        
        // 2-2 => 0 (sub2 => main external transition)
        mainMachine <- "MainState0"
        XCTAssertEqual(mainMachine.state, "MainState0")
        
        // 0 => 1-1 (fail)
        mainMachine <- "Sub1.State1"
        XCTAssertEqual(mainMachine.state, "MainState0", "mainMachine.state should not be updated because current sub1Machine.state is State2, not State1.")
        XCTAssertEqual(sub1Machine.state, "State2")
        
        // let's add resetting route for sub1Machine & reset to Sub1.State1
        sub1Machine.addRoute(nil => "State1")
        sub1Machine <- "State1"
        XCTAssertEqual(mainMachine.state, "MainState0")
        XCTAssertEqual(sub1Machine.state, "State1")
        
        // 0 => 1-1 (retry, succeed)
        mainMachine <- "Sub1.State1"
        XCTAssertEqual(mainMachine.state, "Sub1.State1")
        XCTAssertEqual(sub1Machine.state, "State1")
    }
    
    func testAddHandler()
    {
        let mainMachine = self.mainMachine!
        
        var didPass = false
        
        // NOTE: this handler is added to mainMachine and doesn't make submachines dirty
        mainMachine.addHandler("Sub1.State1" => "Sub1.State2") { context in
            print("[Main] 1-1 => 1-2 (specific)")
            didPass = true
        }
        
        XCTAssertEqual(mainMachine.state, "Sub1.State1")
        XCTAssertFalse(didPass)
        
        mainMachine <- "Sub1.State2"
        XCTAssertEqual(mainMachine.state, "Sub1.State2")
        XCTAssertTrue(didPass)
    }
}
