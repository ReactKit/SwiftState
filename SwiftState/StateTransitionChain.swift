//
//  StateTransitionChain.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct StateTransitionChain<S: StateType>
{
    private typealias State = S
    private typealias Transition = StateTransition<State>
    
    private var states: [State]
    
    public init(transition: Transition)
    {
        self.init(transitions: [transition])
    }
    
    public init(transitions: [Transition])
    {
        assert(transitions.count > 0, "StateTransitionChain must be initialized with at least 1 transition.")
        
        var states: [State] = []
        for i in 0..<transitions.count {
            if i == 0 {
                states += [transitions[i].fromState]
            }
            states += [transitions[i].toState]
        }
        self.states = states
    }
    
    public var transitions: [Transition]
    {
        var transitions: [Transition] = []
        
        for i in 0..<states.count-1 {
            transitions += [states[i] => states[i+1]]
        }
        
        return transitions
    }
    
    public var firstState: State
    {
        return self.states.first!
    }
    
    public var lastState: State
    {
        return self.states.last!
    }
    
    public var numberOfTransitions: Int
    {
        return self.states.count-1
    }
    
    mutating public func prepend(state: State)
    {
        self.states.insert(state, atIndex: 0)
    }
    
    mutating public func append(state: State)
    {
        self.states += [state]
    }
    
    public func toRouteChain() -> StateRouteChain<State>
    {
        return StateRouteChain(transitionChain: self, condition: nil)
    }
    
    public func toTransitions() -> [Transition]
    {
        return self.transitions
    }
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

// e.g. (.State0 => .State1) => .State2
public func => <S: StateType>(left: StateTransition<S>, right: S) -> StateTransitionChain<S>
{
    return left.toTransitionChain() => right
}
public func => <S: StateType>(var left: StateTransitionChain<S>, right: S) -> StateTransitionChain<S>
{
    left.append(right)
    return left
}

// e.g. .State0 => (.State1 => .State2)
public func => <S: StateType>(left:  S, right:StateTransition<S>) -> StateTransitionChain<S>
{
    return left => right.toTransitionChain()
}
public func => <S: StateType>(left: S, var right: StateTransitionChain<S>) -> StateTransitionChain<S>
{
    right.prepend(left)
    return right
}
