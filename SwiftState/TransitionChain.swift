//
//  TransitionChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct TransitionChain<S: StateType>
{
    public private(set) var states: [State<S>]
    
    public init(states: [State<S>])
    {
        self.states = states
    }
    
    public init(transition: Transition<S>)
    {
        self.init(states: [transition.fromState, transition.toState])
    }
    
    public var transitions: [Transition<S>]
    {
        var transitions: [Transition<S>] = []
        
        for i in 0..<states.count-1 {
            transitions += [states[i] => states[i+1]]
        }
        
        return transitions
    }
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

// e.g. (.State0 => .State1) => .State
public func => <S: StateType>(left: Transition<S>, right: State<S>) -> TransitionChain<S>
{
    return TransitionChain(states: [left.fromState, left.toState]) => right
}

public func => <S: StateType>(left: Transition<S>, right: S) -> TransitionChain<S>
{
    return left => .Some(right)
}

public func => <S: StateType>(left: TransitionChain<S>, right: State<S>) -> TransitionChain<S>
{
    return TransitionChain(states: left.states + [right])
}

public func => <S: StateType>(left: TransitionChain<S>, right: S) -> TransitionChain<S>
{
    return left => .Some(right)
}

// e.g. .State0 => (.State1 => .State)
public func => <S: StateType>(left: State<S>, right:Transition<S>) -> TransitionChain<S>
{
    return left => TransitionChain(states: [right.fromState, right.toState])
}

public func => <S: StateType>(left: S, right:Transition<S>) -> TransitionChain<S>
{
    return .Some(left) => right
}

public func => <S: StateType>(left: State<S>, right: TransitionChain<S>) -> TransitionChain<S>
{
    return TransitionChain(states: [left] + right.states)
}

public func => <S: StateType>(left: S, right: TransitionChain<S>) -> TransitionChain<S>
{
    return .Some(left) => right
}
