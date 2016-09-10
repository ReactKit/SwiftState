//
//  _HandlerInfo.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

internal final class _HandlerInfo<S: StateType, E: EventType>
{
    internal let order: HandlerOrder
    internal let key: String
    internal let handler: Machine<S, E>.Handler

    internal init(order: HandlerOrder, key: String, handler: @escaping Machine<S, E>.Handler)
    {
        self.order = order
        self.key = key
        self.handler = handler
    }
}
