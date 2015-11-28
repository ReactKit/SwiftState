//
//  EventType.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public protocol EventType: Hashable {}

// MARK: Event (public)

/// `EventType` wrapper for handling`.Any` event.
public enum Event<E: EventType>: Equatable
{
    case Some(E)
    case Any
    
    public var value: E?
    {
        switch self {
            case .Some(let x):  return x
            default:            return nil
        }
    }
    
    internal func _toInternal() -> _Event<E>
    {
        switch self {
            case .Some(let x):  return .Some(x)
            case .Any:          return .Any
        }
    }
}

public func == <E: EventType>(lhs: Event<E>, rhs: Event<E>) -> Bool
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

// MARK: NoEvent

/// Useful for creating StateMachine without events, i.e. `Machine<MyState, NoEvent>`.
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

// MARK: _Event (internal)

/// Internal `EventType` wrapper for `Event` + `Optional` + `Hashable`.
internal enum _Event<E: EventType>: Hashable
{
    case Some(E)
    case Any        // represents any `Some(E)` events but not `.None`, for `addRouteEvent(.Any)`
    case None       // default internal value for `addRoute()` without event
    
    internal var hashValue: Int
    {
        switch self {
            case .Some(let x):  return x.hashValue
            case .Any:          return -4611686018427387904
            case .None:         return -4611686018427387905
        }
    }
    
    internal var value: E?
    {
        switch self {
            case .Some(let x):  return x
            default:            return nil
        }
    }
}

internal func == <E: Hashable>(lhs: _Event<E>, rhs: _Event<E>) -> Bool
{
    return lhs.hashValue == rhs.hashValue
}

internal func == <E: Hashable>(lhs: _Event<E>, rhs: E) -> Bool
{
    return lhs.hashValue == rhs.hashValue
}

internal func == <E: Hashable>(lhs: E, rhs: _Event<E>) -> Bool
{
    return lhs.hashValue == rhs.hashValue
}
