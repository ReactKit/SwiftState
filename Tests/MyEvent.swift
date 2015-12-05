//
//  MyEvent.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState

enum MyEvent: EventType
{
    case Event0, Event1
}

enum MyEvent2: EventType
{
    case Event0(String)
    
    var hashValue: Int
    {
        switch self {
            case .Event0(let str):  return str.hashValue
        }
    }
}

func == (lhs: MyEvent2, rhs: MyEvent2) -> Bool
{
    switch (lhs, rhs) {
        case let (.Event0(str1), .Event0(str2)):
            return str1 == str2
//        default:
//            return false
    }
}