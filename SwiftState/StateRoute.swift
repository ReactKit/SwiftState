//
//  StateRoute.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

public struct StateRoute<S: StateType>
{
    internal typealias Condition = ((transition: Transition) -> Bool)
    
    private typealias State = S
    private typealias Transition = StateTransition<State>
    
    public let transition: Transition
    public let condition: Condition?
    
    public init(transition: Transition, condition: Condition?)
    {
        self.transition = transition
        self.condition = condition
    }
    
    public init(transition: Transition, condition: @autoclosure () -> Bool)
    {
        // TODO: Xcode6-beta bug? (EXC_BAD_ACCESS)
//        self.init(transition: transition, condition: { t in condition() })
        
        self.transition = transition
        self.condition = { t in condition() }
    }
}