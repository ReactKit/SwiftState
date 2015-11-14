//
//  Transition.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct Transition<S: StateType>: Hashable
{
    public let fromState: State<S>
    public let toState: State<S>
    
    public init(fromState: State<S>, toState: State<S>)
    {
        self.fromState = fromState
        self.toState = toState
    }
    
    public init(fromState: S, toState: State<S>)
    {
        self.init(fromState: .Some(fromState), toState: toState)
    }
    
    public init(fromState: State<S>, toState: S)
    {
        self.init(fromState: fromState, toState: .Some(toState))
    }
    
    public init(fromState: S, toState: S)
    {
        self.init(fromState: .Some(fromState), toState: .Some(toState))
    }
    
    public var hashValue: Int
    {
        return self.fromState.hashValue &+ self.toState.hashValue.byteSwapped
    }
    
    public func toTransitionChain() -> TransitionChain<S>
    {
        return TransitionChain(transition: self)
    }
    
    public func toRoute<E: EventType>() -> Route<S, E>
    {
        return Route(transition: self, condition: nil)
    }
}

// for Transition Equatable
public func == <S: StateType>(left: Transition<S>, right: Transition<S>) -> Bool
{
    return left.hashValue == right.hashValue
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

infix operator => { associativity left }

/// e.g. .State0 => .State1
public func => <S: StateType>(left: State<S>, right: State<S>) -> Transition<S>
{
    return Transition(fromState: left, toState: right)
}

public func => <S: StateType>(left: State<S>, right: S) -> Transition<S>
{
    return left => .Some(right)
}

public func => <S: StateType>(left: S, right: State<S>) -> Transition<S>
{
    return .Some(left) => right
}

public func => <S: StateType>(left: S, right: S) -> Transition<S>
{
    return .Some(left) => .Some(right)
}

//--------------------------------------------------
// MARK: - Printable
//--------------------------------------------------

extension Transition: CustomStringConvertible
{
    public var description: String
    {
        return "\(self.fromState) => \(self.toState) (\(self.hashValue))"
    }
}