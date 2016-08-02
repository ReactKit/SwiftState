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
    case state0, state1, state2, state3
}

enum StrState: StateType
{
    case str(String)

    var hashValue: Int
    {
        switch self {
            case .str(let str):  return str.hashValue
        }
    }
}

func == (lhs: StrState, rhs: StrState) -> Bool
{
    switch (lhs, rhs) {
        case let (.str(str1), .str(str2)):
            return str1 == str2
    }
}
