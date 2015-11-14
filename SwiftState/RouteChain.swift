//
//  RouteChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct RouteChain<S: StateType, E: EventType>
{
    internal var routes: [Route<S, E>]
    
    public init(routes: [Route<S, E>])
    {
        self.routes = routes
    }
    
    public init(transitionChain: TransitionChain<S>, condition: Machine<S, E>.Condition?)
    {
        var routes: [Route<S, E>] = []
        for transition in transitionChain.transitions {
            routes += [Route<S, E>(transition: transition, condition: condition)]
        }
        self.routes = routes
    }
    
    public var numberOfRoutes: Int
    {
        return self.routes.count
    }
    
    mutating public func prepend(state: State<S>, condition: Machine<S, E>.Condition?)
    {
        let firstfromState = self.routes.first!.transition.fromState
        let newRoute = Route<S, E>(transition: state => firstfromState, condition: condition)
        
        self.routes.insert(newRoute, atIndex: 0)
    }
    
    mutating internal func append(state: State<S>, condition: Machine<S, E>.Condition?)
    {
        let lasttoState = self.routes.last!.transition.toState
        let newRoute = Route<S, E>(transition: lasttoState => state, condition: condition)
        
        self.routes += [newRoute]
    }
    
    public func toTransitionChain() -> TransitionChain<S>
    {
        let transitions = self.routes.map { route in route.transition }
        return TransitionChain(transitions: transitions)
    }
    
    public func toRoutes() -> [Route<S, E>]
    {
        return self.routes
    }
}