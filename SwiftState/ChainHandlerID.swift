//
//  ChainHandlerID.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-29.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

public final class ChainHandlerID<S: StateType, E: EventType>
{
    internal let bundledHandlerIDs: [HandlerID<S, E>]
    
    internal init(bundledHandlerIDs: [HandlerID<S, E>])
    {
        self.bundledHandlerIDs = bundledHandlerIDs
    }
}