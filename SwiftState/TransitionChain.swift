//
//  TransitionChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct TransitionChain<S: StateType>
{
    public var states: [State<S>]
    
    public init(transition: Transition<S>)
    {
        self.init(transitions: [transition])
    }
    
    public init(transitions: [Transition<S>])
    {
        assert(transitions.count > 0, "TransitionChain must be initialized with at least 1 transition.")
        
        var states: [State<S>] = []
        for i in 0..<transitions.count {
            if i == 0 {
                states += [transitions[i].fromState]
            }
            states += [transitions[i].toState]
        }
        self.states = states
    }
    
    public var transitions: [Transition<S>]
    {
        var transitions: [Transition<S>] = []
        
        for i in 0..<states.count-1 {
            transitions += [states[i] => states[i+1]]
        }
        
        return transitions
    }
    
    public var firstState: State<S>
    {
        return self.states.first!
    }
    
    public var lastState: State<S>
    {
        return self.states.last!
    }
    
    public var numberOfTransitions: Int
    {
        return self.states.count-1
    }
    
    mutating public func prepend(state: State<S>)
    {
        self.states.insert(state, atIndex: 0)
    }
    
    mutating public func prepend(state: S)
    {
        self.states.insert(.Some(state), atIndex: 0)
    }
    
    mutating public func append(state: State<S>)
    {
        self.states += [state]
    }
    
    mutating public func append(state: S)
    {
        self.states += [.Some(state)]
    }
    
    public func toRouteChain<E: EventType>() -> RouteChain<S, E>
    {
        return RouteChain(transitionChain: self, condition: nil)
    }
    
    public func toTransitions() -> [Transition<S>]
    {
        return self.transitions
    }
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

// e.g. (.State0 => .State1) => .State
public func => <S: StateType>(left: Transition<S>, right: State<S>) -> TransitionChain<S>
{
    return left.toTransitionChain() => right
}

public func => <S: StateType>(left: Transition<S>, right: S) -> TransitionChain<S>
{
    return left => .Some(right)
}

public func => <S: StateType>(var left: TransitionChain<S>, right: State<S>) -> TransitionChain<S>
{
    left.append(right)
    return left
}

public func => <S: StateType>(left: TransitionChain<S>, right: S) -> TransitionChain<S>
{
    return left => .Some(right)
}

// e.g. .State0 => (.State1 => .State)
public func => <S: StateType>(left: State<S>, right:Transition<S>) -> TransitionChain<S>
{
    return left => right.toTransitionChain()
}

public func => <S: StateType>(left: S, right:Transition<S>) -> TransitionChain<S>
{
    return .Some(left) => right
}

public func => <S: StateType>(left: State<S>, var right: TransitionChain<S>) -> TransitionChain<S>
{
    right.prepend(left)
    return right
}

public func => <S: StateType>(left: S, right: TransitionChain<S>) -> TransitionChain<S>
{
    return .Some(left) => right
}
