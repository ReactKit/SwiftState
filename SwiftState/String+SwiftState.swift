//
//  String+SwiftState.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/16.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

// for usage of String as StateType and/or StateEventType
extension String: StateType, StateEventType
{
    public init(nilLiteral: Void)
    {
        self = ""
    }
}