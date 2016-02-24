//
//  StateType.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public protocol StateType: Hashable {}

// MARK: State

/// `StateType` wrapper for handling `.Any` state.
public enum State<S: StateType>
{
    case Some(S)
    case Any
}

extension State: Hashable
{
    public var hashValue: Int
    {
        switch self {
            case .Some(let x):  return x.hashValue
            case .Any:          return _hashValueForAny
        }
    }
}

extension State: RawRepresentable
{
    public init(rawValue: S?)
    {
        if let rawValue = rawValue {
            self = .Some(rawValue)
        }
        else {
            self = .Any
        }
    }

    public var rawValue: S?
    {
        switch self {
            case .Some(let x):  return x
            default:            return nil
        }
    }
}

public func == <S: StateType>(lhs: State<S>, rhs: State<S>) -> Bool
{
    switch (lhs, rhs) {
    case let (.Some(x1), .Some(x2)) where x1 == x2:
        return true
    case (.Any, .Any):
        return true
    default:
        return false
    }
}

public func == <S: StateType>(lhs: State<S>, rhs: S) -> Bool
{
    switch lhs {
    case .Some(let x):
        return x == rhs
    case .Any:
        return false
    }
}

public func == <S: StateType>(lhs: S, rhs: State<S>) -> Bool
{
    switch rhs {
    case .Some(let x):
        return x == lhs
    case .Any:
        return false
    }
}

// MARK: Private

internal let _hashValueForAny = Int.min/2
