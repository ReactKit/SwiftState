//
//  StateRoute.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct StateRoute<S: StateType>
{
    public typealias Condition = ((transition: Transition) -> Bool)
    
    public typealias State = S
    public typealias Transition = StateTransition<State>
    
    public let transition: Transition
    public let condition: Condition?
    
    public init(transition: Transition, condition: Condition?)
    {
        self.transition = transition
        self.condition = condition
    }
    
    public init(transition: Transition, @autoclosure(escaping) condition: () -> Bool)
    {
        self.init(transition: transition, condition: { t in condition() })
    }
    
    public func toTransition() -> Transition
    {
        return self.transition
    }
    
    public func toRouteChain() -> StateRouteChain<State>
    {
        var routes: [StateRoute<State>] = []
        routes += [self]
        return StateRouteChain(routes: routes)
    }
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

/// e.g. [.State0, .State1] => .State2, allowing [0 => 2, 1 => 2]
public func => <S: StateType>(leftStates: [S], right: S) -> StateRoute<S>
{
    // NOTE: don't reuse "nil => nil + condition" for efficiency
    return StateRoute(transition: nil => right, condition: { transition -> Bool in
        return leftStates.contains(transition.fromState)
    })
}

/// e.g. .State0 => [.State1, .State2], allowing [0 => 1, 0 => 2]
public func => <S: StateType>(left: S, rightStates: [S]) -> StateRoute<S>
{
    return StateRoute(transition: left => nil, condition: { transition -> Bool in
        return rightStates.contains(transition.toState)
    })
}

/// e.g. [.State0, .State1] => [.State2, .State3], allowing [0 => 2, 0 => 3, 1 => 2, 1 => 3]
public func => <S: StateType>(leftStates: [S], rightStates: [S]) -> StateRoute<S>
{
    return StateRoute(transition: nil => nil, condition: { transition -> Bool in
        return leftStates.contains(transition.fromState) && rightStates.contains(transition.toState)
    })
}