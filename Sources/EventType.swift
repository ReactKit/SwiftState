//
//  EventType.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/05.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public protocol EventType: Hashable {}

// MARK: Event

/// `EventType` wrapper for handling`.Any` event.
public enum Event<E: EventType>: Hashable
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
    
    public var hashValue: Int
    {
        switch self {
            case .Some(let x):  return x.hashValue
            case .Any:          return _hashValueForAny
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
