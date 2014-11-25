//
//  StateTransition.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct StateTransition<S: StateType>: Hashable
{
    private typealias State = S
    
    public let fromState: State
    public let toState: State
    
    public init(fromState: State, toState: State)
    {
        self.fromState = fromState
        self.toState = toState
    }
    
    public var hashValue: Int
    {
        return self.fromState.hashValue &+ self.toState.hashValue.byteSwapped
    }
    
    public func toTransitionChain() -> StateTransitionChain<State>
    {
        return StateTransitionChain(transition: self)
    }
    
    public func toRoute() -> StateRoute<State>
    {
        return StateRoute(transition: self, condition: nil)
    }
}

// for StateTransition Equatable
public func == <S: StateType>(left: StateTransition<S>, right: StateTransition<S>) -> Bool
{
    return left.hashValue == right.hashValue
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

infix operator => { associativity left }

/// e.g. .State0 => .State1
// NOTE: argument types (S) don't need to be optional because it automatically converts nil to Any via NilLiteralConvertible
public func => <S: StateType>(left: S, right: S) -> StateTransition<S>
{
    return StateTransition(fromState: left, toState: right)
}

//--------------------------------------------------
// MARK: - Printable
//--------------------------------------------------

extension StateTransition: Printable
{
    public var description: String
    {
        return "\(self.fromState) => \(self.toState) (\(self.hashValue))"
    }
}