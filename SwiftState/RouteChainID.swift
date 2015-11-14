//
//  RouteChainID.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-11-10.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

public class RouteChainID<S: StateType, E: EventType>
{
    internal let bundledRouteIDs: [RouteID<S, E>]?
    
    internal init(bundledRouteIDs: [RouteID<S, E>]?)
    {
        self.bundledRouteIDs = bundledRouteIDs
    }
}