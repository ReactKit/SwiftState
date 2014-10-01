//
//  MyState.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState

enum MyState: Int, StateType, Printable
{
    case State0, State1, State2, State3
    case AnyState   // IMPORTANT: create case=Any & use it in convertFromNilLiteral()
    
    //
    // NOTE: enum + associated value is our future, but it won't conform to Equatable so easily
    // http://stackoverflow.com/questions/24339807/how-to-test-equality-of-swift-enums-with-associated-values
    //
    //case MyState(Int)
    
    init(nilLiteral: Void)
    {
        self = AnyState
    }
    
    var description: String
    {
        return "\(self.rawValue)"
    }
}