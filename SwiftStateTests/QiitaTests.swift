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

enum InputKey: StateType, NilLiteralConvertible
{
    case None
    case Key0, Key1, Key2, Key3, Key4, Key5, Key6, Key7, Key8, Key9
    case Any
    
    static func anyState() -> InputKey
    {
        return Any
    }
    
    static func convertFromNilLiteral() -> InputKey
    {
        return self.anyState()
    }
}

class QiitaTests: _TestCase
{
    func testQiita()
    {
        var success = false
        
        let machine = StateMachine<InputKey, String>(state: .None) { machine in
            
            // connect all states
            machine.addRoute(nil => nil)
            
            // success = true only when transitionChain 2 => 3 => 5 => 7 is fulfilled
            machine.addRouteChain(.Key2 => .Key3 => .Key5 => .Key7) { context in
                success = true
                return
            }
        }
        
        // tryState
        machine <- .Key2
        machine <- .Key3
        machine <- .Key4
        machine <- .Key5
        machine <- .Key6
        machine <- .Key7
        
        XCTAssertFalse(success)
        
        machine <- .Key2
        machine <- .Key3
        machine <- .Key5
        machine <- .Key7
        
        XCTAssertTrue(success)
    }
}