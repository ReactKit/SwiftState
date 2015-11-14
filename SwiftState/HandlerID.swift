//
//  HandlerID.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-10.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

public class HandlerID<S: StateType, E: EventType>
{
    /// - Note: `nil` is used for error-handlerID
    internal let transition: Transition<S>?
    
    internal let key: String
    
    internal init(transition: Transition<S>?, key: String)
    {
        self.transition = transition
        self.key = key
    }
}

public class ChainHandlerID<S: StateType, E: EventType>
{
    internal let bundledHandlerIDs: [HandlerID<S, E>]
    
    internal init(bundledHandlerIDs: [HandlerID<S, E>])
    {
        self.bundledHandlerIDs = bundledHandlerIDs
    }
}