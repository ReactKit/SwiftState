//
//  Transition.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

///
/// "From-" and "to-" states represented as `.state1 => .state2`.
/// Also, `.any` can be used to represent _any state_.
///
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
        self.init(fromState: .some(fromState), toState: toState)
    }

    public init(fromState: State<S>, toState: S)
    {
        self.init(fromState: fromState, toState: .some(toState))
    }

    public init(fromState: S, toState: S)
    {
        self.init(fromState: .some(fromState), toState: .some(toState))
    }

    public var hashValue: Int
    {
        return self.fromState.hashValue &+ self.toState.hashValue.byteSwapped
    }
}

// for Transition Equatable
public func == <S>(left: Transition<S>, right: Transition<S>) -> Bool
{
    return left.fromState == right.fromState && left.toState == right.toState
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

infix operator => : AdditionPrecedence

/// e.g. .state0 => .state1
public func => <S>(left: State<S>, right: State<S>) -> Transition<S>
{
    return Transition(fromState: left, toState: right)
}

public func => <S>(left: State<S>, right: S) -> Transition<S>
{
    return left => .some(right)
}

public func => <S>(left: S, right: State<S>) -> Transition<S>
{
    return .some(left) => right
}

public func => <S>(left: S, right: S) -> Transition<S>
{
    return .some(left) => .some(right)
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
