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

enum StrState: StateType
{
    case Str(String)
    
    var hashValue: Int
    {
        switch self {
            case .Str(let str):  return str.hashValue
        }
    }
}

func == (lhs: StrState, rhs: StrState) -> Bool
{
    switch (lhs, rhs) {
        case let (.Str(str1), .Str(str2)):
            return str1 == str2
    }
}