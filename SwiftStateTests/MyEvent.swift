//
//  MyEvent.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState

enum MyEvent: StateEventType
{
    case Event0, Event1
    case AnyEvent   // IMPORTANT: create case=Any & use it in convertFromNilLiteral()
    
    static func convertFromNilLiteral() -> MyEvent
    {
        return AnyEvent
    }
}