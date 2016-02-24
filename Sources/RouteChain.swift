//
//  RouteChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

/// Group of continuous `Route`s.
public struct RouteChain<S: StateType, E: EventType>
{
    public private(set) var routes: [Route<S, E>]

    public init(routes: [Route<S, E>])
    {
        self.routes = routes
    }

    public init(transitionChain: TransitionChain<S>, condition: Machine<S, E>.Condition? = nil)
    {
        var routes: [Route<S, E>] = []
        for transition in transitionChain.transitions {
            routes += [Route<S, E>(transition: transition, condition: condition)]
        }
        self.init(routes: routes)
    }
}
