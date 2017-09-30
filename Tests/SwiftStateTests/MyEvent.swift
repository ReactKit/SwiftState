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
    case event0, event1
}

enum StrEvent: EventType
{
    case str(String)

    var hashValue: Int
    {
        switch self {
            case .str(let str):  return str.hashValue
        }
    }
}

func == (lhs: StrEvent, rhs: StrEvent) -> Bool
{
    switch (lhs, rhs) {
        case let (.str(str1), .str(str2)):
            return str1 == str2
//        default:
//            return false
    }
}
