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

/// e.g. [.state0, .state1] => .state, allowing [0 => 2, 1 => 2]
public func => <S, E>(leftStates: [S], right: State<S>) -> Route<S, E>
{
    // NOTE: don't reuse ".any => .any + condition" for efficiency
    return Route(transition: .any => right, condition: { context -> Bool in
        return leftStates.contains(context.fromState)
    })
}

public func => <S, E>(leftStates: [S], right: S) -> Route<S, E>
{
    return leftStates => .some(right)
}

/// e.g. .state0 => [.state1, .state], allowing [0 => 1, 0 => 2]
public func => <S, E>(left: State<S>, rightStates: [S]) -> Route<S, E>
{
    return Route(transition: left => .any, condition: { context -> Bool in
        return rightStates.contains(context.toState)
    })
}

public func => <S, E>(left: S, rightStates: [S]) -> Route<S, E>
{
    return .some(left) => rightStates
}

/// e.g. [.state0, .state1] => [.state, .state3], allowing [0 => 2, 0 => 3, 1 => 2, 1 => 3]
public func => <S, E>(leftStates: [S], rightStates: [S]) -> Route<S, E>
{
    return Route(transition: .any => .any, condition: { context -> Bool in
        return leftStates.contains(context.fromState) && rightStates.contains(context.toState)
    })
}
