//
//  EventType.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public protocol EventType: Hashable {}

// MARK: Event

/// `EventType` wrapper for handling `.any` event.
public enum Event<E: EventType>
{
    case some(E)
    case any
}

extension Event: Hashable
{
    public var hashValue: Int
    {
        switch self {
            case .some(let x):  return x.hashValue
            case .any:          return _hashValueForAny
        }
    }
}

extension Event: RawRepresentable
{
    public init(rawValue: E?)
    {
        if let rawValue = rawValue {
            self = .some(rawValue)
        }
        else {
            self = .any
        }
    }

    public var rawValue: E?
    {
        switch self {
            case .some(let x):  return x
            default:            return nil
        }
    }
}

public func == <E>(lhs: Event<E>, rhs: Event<E>) -> Bool
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

public func == <E>(lhs: Event<E>, rhs: E) -> Bool
{
    switch lhs {
    case .some(let x):
        return x == rhs
    case .any:
        return false
    }
}

public func == <E>(lhs: E, rhs: Event<E>) -> Bool
{
    switch rhs {
    case .some(let x):
        return x == lhs
    case .any:
        return false
    }
}

// MARK: NoEvent

/// Useful for creating StateMachine without events, i.e. `StateMachine<MyState, NoEvent>`.
public enum NoEvent: EventType
{
    public var hashValue: Int
    {
        return 0
    }
}

public func == (lhs: NoEvent, rhs: NoEvent) -> Bool
{
    return true
}
