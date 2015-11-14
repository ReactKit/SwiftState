//
//  RasmusTest.swift
//  SwiftState
//
//  Created by Rasmus Taulborg Hummelmose on 20/08/15.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

enum RasmusTestState: StateType {
    case State1, State2, State3, State4
}

enum RasmusTestEvent: EventType {
    case State2fromState1
    case State4fromState2OrState3
}

class RasmusTest: _TestCase {
    func testRoute() {
        let stateMachine = Machine<RasmusTestState, RasmusTestEvent>(state: .State1)
        stateMachine.addRouteEvent(.State2fromState1, transitions: [ .State1 => .State2 ])
        stateMachine.addRouteEvent(.State4fromState2OrState3, routes: [ [ .State2, .State3 ] => .State4 ])
        XCTAssertEqual(stateMachine.state, RasmusTestState.State1)
        stateMachine <-! .State2fromState1
        XCTAssertEqual(stateMachine.state, RasmusTestState.State2)
        stateMachine <-! .State4fromState2OrState3
        XCTAssertEqual(stateMachine.state, RasmusTestState.State4)
    }
}
