//
//  MyState.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState

enum MyState: StateType
{
    case State0, State1, State2, State3
}

enum MyState2: StateType
{
    case State0(String)
    
    var hashValue: Int
    {
        switch self {
            case .State0(let str):  return str.hashValue
        }
    }
}

func == (lhs: MyState2, rhs: MyState2) -> Bool
{
    switch (lhs, rhs) {
        case let (.State0(str1), .State0(str2)):
            return str1 == str2
    }
}