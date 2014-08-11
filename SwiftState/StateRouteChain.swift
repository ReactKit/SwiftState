//
//  StateRouteChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct StateRouteChain<S: StateType>
{
    private typealias State = S
    private typealias Transition = StateTransition<State>
    private typealias TransitionChain = StateTransitionChain<State>
    private typealias Route = StateRoute<State>
    private typealias Condition = Route.Condition
    
    internal var routes: [Route]
    
    public init(routes: [Route])
    {
        self.routes = routes
    }
    
    public init(transitionChain: TransitionChain, condition: Condition?)
    {
        var routes: [Route] = Array()
        for transition in transitionChain.transitions {
            routes.append(Route(transition: transition, condition: condition))
        }
        self.routes = routes
    }
    
    public var numberOfRoutes: Int
    {
        return self.routes.count
    }
    
    mutating public func prepend(state: State, condition: Condition?)
    {
        let firstFromState = self.routes.first!.transition.fromState
        let newRoute = StateRoute<State>(transition: state => firstFromState, condition: condition)
        
        self.routes.insert(newRoute, atIndex: 0)
    }
    
    mutating internal func append(state: State, condition: Condition?)
    {
        let lastToState = self.routes.last!.transition.toState
        let newRoute = StateRoute<State>(transition: lastToState => state, condition: condition)
        
        self.routes.append(newRoute)
    }
}