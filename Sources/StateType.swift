//
//  StateType.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public protocol StateType: Hashable {}

// MARK: State

/// `StateType` wrapper for handling `.any` state.
public enum State<S: StateType>
{
    case some(S)
    case any
}

extension State: Hashable
{
    public var hashValue: Int
    {
        switch self {
            case .some(let x):  return x.hashValue
            case .any:          return _hashValueForAny
        }
    }
}

extension State: RawRepresentable
{
    public init(rawValue: S?)
    {
        if let rawValue = rawValue {
            self = .some(rawValue)
        }
        else {
            self = .any
        }
    }

    public var rawValue: S?
    {
        switch self {
            case .some(let x):  return x
            default:            return nil
        }
    }
}

public func == <S>(lhs: State<S>, rhs: State<S>) -> Bool
{
    switch (lhs, rhs) {
    case let (.some(x1), .some(x2)) where x1 == x2:
        return true
    case (.any, .any):
        return true
    default:
        return false
    }
}

public func == <S>(lhs: State<S>, rhs: S) -> Bool
{
    switch lhs {
    case .some(let x):
        return x == rhs
    case .any:
        return false
    }
}

public func == <S>(lhs: S, rhs: State<S>) -> Bool
{
    switch rhs {
    case .some(let x):
        return x == lhs
    case .any:
        return false
    }
}

// MARK: Private

internal let _hashValueForAny = Int.min/2
