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

enum StrEvent: EventType
{
    case Str(String)
    
    var hashValue: Int
    {
        switch self {
            case .Str(let str):  return str.hashValue
        }
    }
}

func == (lhs: StrEvent, rhs: StrEvent) -> Bool
{
    switch (lhs, rhs) {
        case let (.Str(str1), .Str(str2)):
            return str1 == str2
//        default:
//            return false
    }
}