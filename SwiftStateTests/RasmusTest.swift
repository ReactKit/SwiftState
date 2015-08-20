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
    case Any
    case State1, State2, State3, State4
    init(nilLiteral: Void) {
        self = Any
    }
}

enum RasmusTestEvent: StateEventType {
    case Any
    case State2FromState1
    case State4FromState2OrState3
    init(nilLiteral: Void) {
        self = Any
    }
}

class RasmusTest: _TestCase {
    func testStateRoute() {
        let stateMachine = StateMachine<RasmusTestState, RasmusTestEvent>(state: .State1)
        stateMachine.addRouteEvent(.State2FromState1, transitions: [ .State1 => .State2 ])
        stateMachine.addRouteEvent(.State4FromState2OrState3, routes: [ [ .State2, .State3 ] => .State4 ])
        XCTAssertEqual(stateMachine.state, RasmusTestState.State1)
        stateMachine <-! .State2FromState1
        XCTAssertEqual(stateMachine.state, RasmusTestState.State2)
        stateMachine <-! .State4FromState2OrState3
        XCTAssertEqual(stateMachine.state, RasmusTestState.State4)
    }
}
