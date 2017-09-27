//
//  TransitionChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

/// Group of continuous `Transition`s represented as `.state1 => .state2 => .state3`.
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

// e.g. (.state0 => .state1) => .state
public func => <S>(left: Transition<S>, right: State<S>) -> TransitionChain<S>
{
    return TransitionChain(states: [left.fromState, left.toState]) => right
}

public func => <S>(left: Transition<S>, right: S) -> TransitionChain<S>
{
    return left => .some(right)
}

public func => <S>(left: TransitionChain<S>, right: State<S>) -> TransitionChain<S>
{
    return TransitionChain(states: left.states + [right])
}

public func => <S>(left: TransitionChain<S>, right: S) -> TransitionChain<S>
{
    return left => .some(right)
}

// e.g. .state0 => (.state1 => .state)
public func => <S>(left: State<S>, right: Transition<S>) -> TransitionChain<S>
{
    return left => TransitionChain(states: [right.fromState, right.toState])
}

public func => <S>(left: S, right: Transition<S>) -> TransitionChain<S>
{
    return .some(left) => right
}

public func => <S>(left: State<S>, right: TransitionChain<S>) -> TransitionChain<S>
{
    return TransitionChain(states: [left] + right.states)
}

public func => <S>(left: S, right: TransitionChain<S>) -> TransitionChain<S>
{
    return .some(left) => right
}
