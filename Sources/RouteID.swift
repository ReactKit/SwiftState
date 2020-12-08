//
//  _RouteID.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-10.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

internal final class _RouteID<S: StateType, E: EventType>
{
    internal let event: Event<E>?
    internal let transition: Transition<S>
    internal let key: String

    internal init(event: Event<E>?, transition: Transition<S>, key: String)
    {
        self.event = event
        self.transition = transition
        self.key = key
    }
}
