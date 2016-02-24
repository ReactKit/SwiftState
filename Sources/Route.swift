//
//  Route.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

/// `Transition` + `Condition`.
public struct Route<S: StateType, E: EventType>
{
    public let transition: Transition<S>
    public let condition: Machine<S, E>.Condition?

    public init(transition: Transition<S>, condition: Machine<S, E>.Condition?)
    {
        self.transition = transition
        self.condition = condition
    }
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

/// e.g. [.State0, .State1] => .State, allowing [0 => 2, 1 => 2]
public func => <S: StateType, E: EventType>(leftStates: [S], right: State<S>) -> Route<S, E>
{
    // NOTE: don't reuse ".Any => .Any + condition" for efficiency
    return Route(transition: .Any => right, condition: { context -> Bool in
        return leftStates.contains(context.fromState)
    })
}

public func => <S: StateType, E: EventType>(leftStates: [S], right: S) -> Route<S, E>
{
    return leftStates => .Some(right)
}

/// e.g. .State0 => [.State1, .State], allowing [0 => 1, 0 => 2]
public func => <S: StateType, E: EventType>(left: State<S>, rightStates: [S]) -> Route<S, E>
{
    return Route(transition: left => .Any, condition: { context -> Bool in
        return rightStates.contains(context.toState)
    })
}

public func => <S: StateType, E: EventType>(left: S, rightStates: [S]) -> Route<S, E>
{
    return .Some(left) => rightStates
}

/// e.g. [.State0, .State1] => [.State, .State3], allowing [0 => 2, 0 => 3, 1 => 2, 1 => 3]
public func => <S: StateType, E: EventType>(leftStates: [S], rightStates: [S]) -> Route<S, E>
{
    return Route(transition: .Any => .Any, condition: { context -> Bool in
        return leftStates.contains(context.fromState) && rightStates.contains(context.toState)
    })
}
