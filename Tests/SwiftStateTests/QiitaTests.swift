//
//  QiitaTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/10.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

// blog post:
// Swiftで有限オートマトン（ステートマシン）を作る - Qiita
// http://qiita.com/inamiy/items/cd218144c90926f9a134

enum InputKey: StateType
{
    case none
    case key0, key1, key2, key3, key4, key5, key6, key7, key8, key9
}

class QiitaTests: _TestCase
{
    func testQiita()
    {
        var success = false

        let machine = StateMachine<InputKey, NoEvent>(state: .none) { machine in

            // connect all states
            machine.addRoute(.any => .any)

            // success = true only when transitionChain 2 => 3 => 5 => 7 is fulfilled
            machine.addRouteChain(.key2 => .key3 => .key5 => .key7) { context in
                success = true
                return
            }
        }

        // tryState
        machine <- .key2
        machine <- .key3
        machine <- .key4
        machine <- .key5
        machine <- .key6
        machine <- .key7

        XCTAssertFalse(success)

        machine <- .key2
        machine <- .key3
        machine <- .key5
        machine <- .key7

        XCTAssertTrue(success)
    }
}
