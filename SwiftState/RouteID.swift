//
//  RouteID.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-10.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

public final class RouteID<S: StateType, E: EventType>
{
    internal let event: _Event<E>
    internal let transition: Transition<S>
    internal let key: String
    
    internal init(event: _Event<E>, transition: Transition<S>, key: String)
    {
        self.transition = transition
        self.event = event
        self.key = key
    }
}