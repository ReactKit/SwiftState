//
//  SwiftState+StringType.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/15.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

extension String: StateType, StateEventType
{
    public static func anyState() -> String
    {
        return ""
    }
    
    public static func anyStateEvent() -> String
    {
        return ""
    }
}