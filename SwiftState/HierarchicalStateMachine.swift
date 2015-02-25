//
//  HierarchicalStateMachine.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/10/13.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import Foundation

public typealias HSM = HierarchicalStateMachine<String, String>

//
// NOTE:
// When subclassing StateMachine<StateType, StateEventType>,
// don't directly set String as a replacement of StateType (generic type)
// due to Xcode6.1-GM2 generics bug(?) causing EXC_I386_GPFLT when overriding method e.g. `hasRoute()`.
//
// Ideally, class `HierarchicalStateMachine` should be declared as following:
//
//   `public class HierarchicalStateMachine: StateMachine<String, String>`
//
// To avoid above issue, we use `typealias HSM` instead.
//

/// nestable StateMachine with StateType as String
public class HierarchicalStateMachine<S: StateType, E: StateEventType>: StateMachine<S, E>, Printable
{
    private var _submachines = [String : HSM]()
    
    public let name: String
    
    /// init with submachines
    public init(name: String, submachines: [HSM]? = nil, state: State, initClosure: (StateMachine<State, Event> -> Void)? = nil)
    {
        self.name = name
        
        if let submachines = submachines {
            for submachine in submachines {
                self._submachines[submachine.name] = submachine
            }
        }
        
        super.init(state: state, initClosure: initClosure)
    }
    
    public var description: String
    {
        return self.name
    }
    
    ///
    /// Converts dot-chained state sent from mainMachine into (submachine, substate) tuple.
    /// e.g.
    ///
    /// - state="MainState1" will return (nil, "MainState1")
    /// - state="SubMachine1.State1" will return (submachine1, "State1")
    /// - state="" (nil) will return (nil, nil)
    ///
    private func _submachineTupleForState(state: State) -> (HSM?, HSM.State)
    {
        assert(state is HSM.State, "HSM state must be String.")
        
        let components = split(state as HSM.State, { $0 == "." }, maxSplit: 1)
        
        switch components.count {
            case 2:
                let submachineName = components[0]
                let substate = components[1]
                return (self._submachines[submachineName], substate)
                
            case 1:
                let state = components[0]
                return (nil, state)
                
            default:
                // NOTE: reaches here when state="" (empty) as AnyState
                return (nil, nil)
        }
    }
    
    public override var state: State
    {
        // NOTE: returning `substate` is not reliable (as a spec), so replace it with actual `submachine.state` instead
        let (submachine, substate) = self._submachineTupleForState(self._state)
        
        if let submachine = submachine {
            self._state = "\(submachine.name).\(submachine.state)" as State
        }
        
        return self._state
    }
    
    public override func hasRoute(transition: Transition, forEvent event: Event = nil) -> Bool
    {
        let (fromSubmachine, fromSubstate) = self._submachineTupleForState(transition.fromState)
        let (toSubmachine, toSubstate) = self._submachineTupleForState(transition.toState)
        
        // check submachine-internal routes
        if fromSubmachine != nil && toSubmachine != nil && fromSubmachine === toSubmachine {
            return fromSubmachine!.hasRoute(fromSubstate => toSubstate, forEvent: nil)
        }
        
        return super.hasRoute(transition, forEvent: event)
    }
    
    internal override func _addRoute(var route: Route, forEvent event: Event = nil) -> RouteID
    {
        let originalCondition = route.condition
        
        let condition: Condition = { transition -> Bool in
            
            let (fromSubmachine, fromSubstate) = self._submachineTupleForState(route.transition.fromState)
            let (toSubmachine, toSubstate) = self._submachineTupleForState(route.transition.toState)
            
            //
            // For external-route, don't let mainMachine switch to submachine.state=toSubstate 
            // when current submachine.state is not toSubstate.
            //
            // e.g. ignore `"MainState0" => "Sub1.State1"` transition when 
            // `mainMachine.state="MainState0"` but `submachine.state="State2"` (not "State1")
            //
            if toSubmachine != nil && toSubmachine!.state != toSubstate && fromSubmachine !== toSubmachine {
                return false
            }
            
            return originalCondition?(transition: transition) ?? true
        }
        
        route = Route(transition: route.transition, condition: condition)
        
        return super._addRoute(route, forEvent: event)
    }
    
    // TODO: apply mainMachine's events to submachines
    internal override func _tryState(state: State, userInfo: Any? = nil, forEvent event: Event) -> Bool
    {
        assert(state is HSM.State, "HSM state must be String.")
        
        let fromState = self.state
        let toState = state
        let transition = fromState => toState
        
        let (fromSubmachine, fromSubstate) = self._submachineTupleForState(fromState)
        let (toSubmachine, toSubstate) = self._submachineTupleForState(toState)
        
        // try changing submachine-internal state
        if fromSubmachine != nil && toSubmachine != nil && fromSubmachine === toSubmachine {
            
            if toSubmachine!.canTryState(toSubstate, forEvent: event as HSM.Event) {
                
                //
                // NOTE:
                // Change mainMachine's state first to invoke its handlers
                // before changing toSubmachine's state because mainMachine.state relies on it.
                //
                super._tryState(toState, userInfo: userInfo, forEvent: event)
                
                toSubmachine! <- (toSubstate as HSM.State)
                
                return true
            }
            
        }
        
        return super._tryState(toState, userInfo: userInfo, forEvent: event)
    }
}