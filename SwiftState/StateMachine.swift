//
//  StateMachine.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import Darwin

// NOTE: nested type inside generic StateMachine class is not allowed in Swift 1.1
// NOTE: 'public struct' didn't work since Xcode6-beta6
public class StateMachineRouteID<S: StateType, E: StateEventType>
{
    private typealias Transition = StateTransition<S>
    private typealias RouteKey = StateMachine<S, E>.RouteKey
    
    private let transition: Transition?
    private let routeKey: RouteKey?
    private let event: E?
    
    private let bundledRouteIDs: [StateMachineRouteID<S, E>]?
    
    private init(transition: Transition?, routeKey: RouteKey?, event: E?)
    {
        self.transition = transition
        self.routeKey = routeKey
        self.event = event
    }
    
    private init(bundledRouteIDs: [StateMachineRouteID<S, E>]?)
    {
        self.bundledRouteIDs = bundledRouteIDs
    }
}

public class StateMachineHandlerID<S: StateType, E: StateEventType>
{
    private typealias Transition = StateTransition<S>
    private typealias HandlerKey = StateMachine<S, E>.HandlerKey
    
    private let transition: Transition? // NOTE: nil is used for error-handlerID
    private let handlerKey: HandlerKey?
    
    private let bundledHandlerIDs: [StateMachineHandlerID<S, E>]?
    
    private init(transition: Transition?, handlerKey: HandlerKey?)
    {
        self.transition = transition
        self.handlerKey = handlerKey
    }
    
    private init(bundledHandlerIDs: [StateMachineHandlerID<S, E>]?)
    {
        self.bundledHandlerIDs = bundledHandlerIDs
    }
}

internal class _StateMachineHandlerInfo<S: StateType, E: StateEventType>
{
    private typealias HandlerOrder = StateMachine<S, E>.HandlerOrder
    private typealias HandlerKey = StateMachine<S, E>.HandlerKey
    private typealias Handler = StateMachine<S, E>.Handler
    
    private let order: HandlerOrder
    private let handlerKey: HandlerKey
    private let handler: Handler
    
    private init(order: HandlerOrder, handlerKey: HandlerKey, handler: Handler)
    {
        self.order = order
        self.handlerKey = handlerKey
        self.handler = handler
    }
}

public class StateMachine<S: StateType, E: StateEventType>
{
    public typealias HandlerOrder = UInt8
    public typealias Handler = ((context: HandlerContext) -> Void)
    public typealias HandlerContext = (event: Event, transition: Transition, order: HandlerOrder, userInfo: Any?)
    
    internal typealias State = S
    internal typealias Event = E
    internal typealias Transition = StateTransition<State>
    internal typealias TransitionChain = StateTransitionChain<State>
    
    internal typealias Route = StateRoute<State>
    internal typealias RouteKey = String
    internal typealias RouteID = StateMachineRouteID<State, Event>
    internal typealias RouteChain = StateRouteChain<State>
    
    internal typealias Condition = Route.Condition
    
    internal typealias HandlerKey = String
    internal typealias HandlerID = StateMachineHandlerID<State, Event>
    internal typealias HandlerInfo = _StateMachineHandlerInfo<State, Event>
    // NOTE: don't use tuple due to Array's copying behavior for closure
//    private typealias HandlerInfo = (order: HandlerOrder, handlerKey: HandlerKey, handler: Handler)
    
    private typealias TransitionRouteDictionary = [Transition : [RouteKey : Condition?]]
    
    private var _routes: [Event : TransitionRouteDictionary] = [:]
    private var _handlers: [Transition : [HandlerInfo]] = [:]
    private var _errorHandlers: [HandlerInfo] = []
    
    internal var _state: State
    
    private class var _defaultOrder: HandlerOrder { return 100 }
    
    //--------------------------------------------------
    // MARK: - Utility
    //--------------------------------------------------
    
    // generate approx 126bit random string
    private class func _createUniqueString() -> String
    {
        var uniqueString: String = ""
        for i in 1...8 {
            uniqueString += String(UnicodeScalar(arc4random_uniform(0xD800))) // 0xD800 = 55296 = 15.755bit
        }
        return uniqueString
    }
    
    //--------------------------------------------------
    // MARK: - Init
    //--------------------------------------------------
    
    public init(state: State, initClosure: (StateMachine -> Void)? = nil)
    {
        self._state = state
        
        initClosure?(self)
    }
    
    public func configure(closure: StateMachine -> Void)
    {
        closure(self)
    }
    
    //--------------------------------------------------
    // MARK: - State/Event/Transition
    //--------------------------------------------------
    
    public var state: State
    {
        return self._state
    }
    
    public func hasRoute(transition: Transition, forEvent event: Event = nil) -> Bool
    {
        let validTransitions = self._validTransitionsForTransition(transition)
        
        for validTransition in validTransitions {
            
            var transitionDicts: [TransitionRouteDictionary] = []
            
            if event == nil as Event {
                transitionDicts += self._routes.values.array
            }
            else {
                for (ev, transitionDict) in self._routes {
                    if ev == event || ev == nil as Event {
                        transitionDicts += [transitionDict]
                        break
                    }
                }
            }
            
            for transitionDict in transitionDicts {
                if let routeKeyDict = transitionDict[validTransition] {
                    for (_, condition) in routeKeyDict {
                        if self._canPassCondition(condition, transition: transition) {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private func _canPassCondition(condition: Condition?, transition: Transition) -> Bool
    {
        return condition == nil || condition!(transition: transition)
    }
    
    public func canTryState(state: State, forEvent event: Event = nil) -> Bool
    {
        let fromState = self.state
        let toState = state
        
        return self.hasRoute(fromState => toState, forEvent: event)
    }
    
    public func tryState(state: State, userInfo: Any? = nil) -> Bool
    {
        return self._tryState(state, userInfo: userInfo, forEvent: nil)
    }
    
    internal func _tryState(state: State, userInfo: Any? = nil, forEvent event: Event) -> Bool
    {
        var didTransit = false
        
        let fromState = self.state
        let toState = state
        let transition = fromState => toState
        
        if self.canTryState(state, forEvent: event) {
            
            // collect valid handlers before updating state
            let validHandlerInfos = self._validHandlerInfosForTransition(transition)
            
            // update state
            self._state = toState
            
            //
            // Perform validHandlers after updating state.
            //
            // NOTE:
            // Instead of using before/after handlers as seen in many other StateMachine libraries,
            // SwiftState uses `order` value to perform handlers in 'fine-grained' order,
            // only after state has been updated. (Any problem?)
            //
            for handlerInfo in validHandlerInfos {
                let order = handlerInfo.order
                let handler = handlerInfo.handler
                
                handler(context: HandlerContext(event: event, transition: transition, order: order, userInfo: userInfo))
            }
            
            didTransit = true
        }
        else {
            for handlerInfo in self._errorHandlers {
                let order = handlerInfo.order
                let handler = handlerInfo.handler
                
                handler(context: HandlerContext(event: event, transition: transition, order: order, userInfo: userInfo))
            }
        }
        
        return didTransit
    }
    
    private func _validHandlerInfosForTransition(transition: Transition) -> [HandlerInfo]
    {
        var validHandlerInfos: [HandlerInfo] = []
        
        let validTransitions = self._validTransitionsForTransition(transition)
        
        for validTransition in validTransitions {
            if let handlerInfos = self._handlers[validTransition] {
                for handlerInfo in handlerInfos {
                    validHandlerInfos += [handlerInfo]
                }
            }
        }
        
        validHandlerInfos.sort { info1, info2 in
            return info1.order < info2.order
        }
        
        return validHandlerInfos
    }
    
    private func _validTransitionsForTransition(transition: Transition) -> [Transition]
    {
        var transitions: [Transition] = []
        
        // anywhere
        transitions += [nil => nil]
        
        // exit
        if transition.fromState != nil as State {
            transitions += [transition.fromState => nil]
        }
        
        // entry
        if transition.toState != nil as State {
            transitions += [nil => transition.toState]
        }
        
        // specific
        if (transition.fromState != nil as State) && (transition.toState != nil as State) {
            transitions += [transition]
        }
        
        return transitions
    }
    
    public func canTryEvent(event: Event) -> State?
    {
        var validEvents: [Event] = []
        if event == nil as Event {
            validEvents += self._routes.keys.array
        }
        else {
            validEvents += [event]
        }
        
        for validEvent in validEvents {
            if let transitionDict = self._routes[validEvent] {
                for (transition, routeKeyDict) in transitionDict {
                    if transition.fromState == self.state {
                        for (_, condition) in routeKeyDict {
                            if self._canPassCondition(condition, transition: transition) {
                                return transition.toState
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    public func tryEvent(event: Event, userInfo: Any? = nil) -> Bool
    {
        if let toState = self.canTryEvent(event) {
            self._tryState(toState, userInfo: userInfo, forEvent: event)
            return true
        }
        
        return false
    }
    
    //--------------------------------------------------
    // MARK: - Route
    //--------------------------------------------------
    
    // MARK: addRoute
    
    public func addRoute(transition: Transition, condition: Condition? = nil) -> RouteID
    {
        let route = Route(transition: transition, condition: condition)
        return self.addRoute(route)
    }
    
    public func addRoute(transition: Transition, condition: @autoclosure () -> Bool) -> RouteID
    {
        return self.addRoute(transition, condition: { t in condition() })
    }
    
    public func addRoute(route: Route) -> RouteID
    {
        return self._addRoute(route)
    }
    
    internal func _addRoute(route: Route, forEvent event: Event = nil) -> RouteID
    {
        let transition = route.transition
        let condition = route.condition
        
        if self._routes[event] == nil {
            self._routes[event] = [:]
        }
        
        var transitionDict = self._routes[event]!
        if transitionDict[transition] == nil {
            transitionDict[transition] = [:]
        }
        
        let routeKey = self.dynamicType._createUniqueString()
        
        var routeKeyDict = transitionDict[transition]!
        routeKeyDict[routeKey] = condition
        transitionDict[transition] = routeKeyDict
        
        self._routes[event] = transitionDict
        
        let routeID = RouteID(transition: transition, routeKey: routeKey, event: event)
        
        return routeID
    }
    
    // MARK: addRoute + conditional handler
    
    public func addRoute(transition: Transition, handler: Handler) -> (RouteID, HandlerID)
    {
        return self.addRoute(transition, condition: nil, handler: handler)
    }
    
    public func addRoute(transition: Transition, condition: Condition?, handler: Handler) -> (RouteID, HandlerID)
    {
        let route = Route(transition: transition, condition: condition)
        return self.addRoute(route, handler: handler)
    }
    
    public func addRoute(transition: Transition, condition: @autoclosure () -> Bool, handler: Handler) -> (RouteID, HandlerID)
    {
        return self.addRoute(transition, condition: { t in condition() }, handler: handler)
    }
    
    public func addRoute(route: Route, handler: Handler) -> (RouteID, HandlerID)
    {
        let transition = route.transition
        let condition = route.condition
        
        let routeID = self.addRoute(transition, condition: condition)
        
        let handlerID = self.addHandler(transition) { [weak self] context in
            if let self_ = self {
                if self_._canPassCondition(condition, transition: context.transition) {
                    handler(context: context)
                }
            }
        }
        
        return (routeID, handlerID)
    }
    
    // MARK: removeRoute
    
    public func removeRoute(routeID: RouteID) -> Bool
    {
        if let routeKey = routeID.routeKey {
            let event = routeID.event!
            let transition = routeID.transition!
            
            if var transitionDict = self._routes[event] {
                if var routeKeyDict = transitionDict[transition] {
                    routeKeyDict[routeKey] = nil
                    if routeKeyDict.count > 0 {
                        transitionDict[transition] = routeKeyDict
                    }
                    else {
                        transitionDict[transition] = nil
                    }
                }
                
                if transitionDict.count > 0 {
                    self._routes[event] = transitionDict
                }
                else {
                    self._routes[event] = nil
                }
                
                return true
            }
        }
        else {
            var success = false
            for bundledRouteID in routeID.bundledRouteIDs! {
                success = self.removeRoute(bundledRouteID) || success
            }
            
            return success
        }
        
        return false
    }
    
    public func removeAllRoutes() -> Bool
    {
        let removingCount = self._routes.count
        
        self._routes = [:]
        
        return removingCount > 0
    }
    
    //--------------------------------------------------
    // MARK: - Handler
    //--------------------------------------------------

    public func addHandler(transition: Transition, handler: Handler) -> HandlerID
    {
        return self.addHandler(transition, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addHandler(transition: Transition, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        if self._handlers[transition] == nil {
            self._handlers[transition] = []
        }
        
        let handlerKey = self.dynamicType._createUniqueString()
        
        var handlerInfos = self._handlers[transition]!
        let newHandlerInfo = HandlerInfo(order: order, handlerKey: handlerKey, handler: handler)
        self._insertHandlerIntoArray(&handlerInfos, newHandlerInfo: newHandlerInfo)
        
        self._handlers[transition] = handlerInfos
        
        let handlerID = HandlerID(transition: transition, handlerKey: handlerKey)
        
        return handlerID
    }
    
    private func _insertHandlerIntoArray(inout handlerInfos: [HandlerInfo], newHandlerInfo: HandlerInfo)
    {
        var index = handlerInfos.count
        
        for i in Array(0..<handlerInfos.count).reverse() {
            if handlerInfos[i].order <= newHandlerInfo.order {
                break
            }
            index = i
        }
        
        handlerInfos.insert(newHandlerInfo, atIndex: index)
    }
    
    // MARK: addEntryHandler
    
    public func addEntryHandler(state: State, handler: Handler) -> HandlerID
    {
        return self.addHandler(nil => state, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addEntryHandler(state: State, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        return self.addHandler(nil => state, handler: handler)
    }
    
    // MARK: addExitHandler
    
    public func addExitHandler(state: State, handler: Handler) -> HandlerID
    {
        return self.addHandler(state => nil, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addExitHandler(state: State, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        return self.addHandler(state => nil, handler: handler)
    }
    
    // MARK: removeHandler
    
    public func removeHandler(handlerID: HandlerID) -> Bool
    {
        if handlerID.handlerKey != nil {
            if let transition = handlerID.transition {
                if var handlerInfos = self._handlers[transition] {
                    
                    if self._removeHandlerFromArray(&handlerInfos, removingHandlerID: handlerID) {
                        self._handlers[transition] = handlerInfos
                        return true
                    }
                }
            }
            // `transition = nil` means errorHandler
            else {
                if self._removeHandlerFromArray(&self._errorHandlers, removingHandlerID: handlerID) {
                    return true
                }
                return false
            }
        }
        else {
            var success = false
            for bundledHandlerID in handlerID.bundledHandlerIDs! {
                success = self.removeHandler(bundledHandlerID) || success
            }
            
            return success
        }
        
        return false
    }
    
    private func _removeHandlerFromArray(inout handlerInfos: [HandlerInfo], removingHandlerID: HandlerID) -> Bool
    {
        for i in 0..<handlerInfos.count {
            if handlerInfos[i].handlerKey == removingHandlerID.handlerKey {
                handlerInfos.removeAtIndex(i)
                return true
            }
        }
        
        return false
    }
    
    public func removeAllHandlers() -> Bool
    {
        let removingCount = self._handlers.count + self._errorHandlers.count
        
        self._handlers = [:]
        self._errorHandlers = []
        
        return removingCount > 0
    }
    
    // MARK: addErrorHandler
    
    public func addErrorHandler(handler: Handler) -> HandlerID
    {
        return self.addErrorHandler(order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addErrorHandler(#order: HandlerOrder, handler: Handler) -> HandlerID
    {
        let handlerKey = self.dynamicType._createUniqueString()
        
        let newHandlerInfo = HandlerInfo(order: order, handlerKey: handlerKey, handler: handler)
        self._insertHandlerIntoArray(&self._errorHandlers, newHandlerInfo: newHandlerInfo)
        
        let handlerID = HandlerID(transition: nil, handlerKey: handlerKey)
        
        return handlerID
    }
    
    //--------------------------------------------------
    // MARK: - RouteChain
    //--------------------------------------------------
    // NOTE: handler is required for addRouteChain
    
    // MARK: addRouteChain + conditional handler
    
    public func addRouteChain(chain: TransitionChain, handler: Handler) -> (RouteID, HandlerID)
    {
        return self.addRouteChain(chain, condition: nil, handler: handler)
    }
    
    public func addRouteChain(chain: TransitionChain, condition: Condition?, handler: Handler) -> (RouteID, HandlerID)
    {
        let routeChain = RouteChain(transitionChain: chain, condition: condition)
        return self.addRouteChain(routeChain, handler: handler)
    }
    
    public func addRouteChain(chain: TransitionChain, condition: @autoclosure () -> Bool, handler: Handler) -> (RouteID, HandlerID)
    {
        return self.addRouteChain(chain, condition: { t in condition() }, handler: handler)
    }
    
    public func addRouteChain(chain: RouteChain, handler: Handler) -> (RouteID, HandlerID)
    {
        var routeIDs: [RouteID] = []
        
        for route in chain.routes {
            let routeID = self.addRoute(route)
            routeIDs += [routeID]
        }
        
        let handlerID = self.addChainHandler(chain, handler: handler)
        
        let bundledRouteID = RouteID(bundledRouteIDs: routeIDs)
        
        return (bundledRouteID, handlerID)
    }
    
    // MARK: addChainHandler
    
    public func addChainHandler(chain: TransitionChain, handler: Handler) -> HandlerID
    {
        return self.addChainHandler(chain.toRouteChain(), handler: handler)
    }
    
    public func addChainHandler(chain: TransitionChain, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        return self.addChainHandler(chain.toRouteChain(), order: order, handler: handler)
    }
    
    public func addChainHandler(chain: RouteChain, handler: Handler) -> HandlerID
    {
        return self.addChainHandler(chain, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addChainHandler(chain: RouteChain, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: false)
    }
    
    // MARK: addChainErrorHandler
    
    public func addChainErrorHandler(chain: TransitionChain, handler: Handler) -> HandlerID
    {
        return self.addChainErrorHandler(chain.toRouteChain(), handler: handler)
    }
    
    public func addChainErrorHandler(chain: TransitionChain, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        return self.addChainErrorHandler(chain.toRouteChain(), order: order, handler: handler)
    }
    
    public func addChainErrorHandler(chain: RouteChain, handler: Handler) -> HandlerID
    {
        return self.addChainErrorHandler(chain, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addChainErrorHandler(chain: RouteChain, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: true)
    }
    
    private func _addChainHandler(chain: RouteChain, order: HandlerOrder, handler: Handler, isError: Bool) -> HandlerID
    {
        var handlerIDs: [HandlerID] = []
        
        var shouldStop = true
        var shouldIncrementChainingCount = true
        var chainingCount = 0
        var allCount = 0
        
        // reset count on 1st route
        let firstRoute = chain.routes.first!
        var handlerID = self.addHandler(firstRoute.transition) { [weak self] context in
            if let self_ = self {
                if self_._canPassCondition(firstRoute.condition, transition: context.transition) {
                    if shouldStop {
                        shouldStop = false
                        chainingCount = 0
                        allCount = 0
                    }
                }
            }
        }
        handlerIDs += [handlerID]
        
        // increment chainingCount on every route
        for route in chain.routes {
            
            handlerID = self.addHandler(route.transition) { [weak self] context in
                
                if let self_ = self {
                    
                    // skip duplicated transition handlers e.g. chain = 0 => 1 => 0 => 1 & transiting 0 => 1
                    if !shouldIncrementChainingCount { return }
                    
                    if self_._canPassCondition(route.condition, transition: context.transition) {
                        if !shouldStop {
                            chainingCount++
                            
                            shouldIncrementChainingCount = false
                        }
                    }
                }
            }
            handlerIDs += [handlerID]
        }
        
        // increment allCount (+ invoke chainErrorHandler) on any routes
        handlerID = self.addHandler(nil => nil, order: 150) { [weak self] context in
            
            shouldIncrementChainingCount = true
            
            if !shouldStop {
                allCount++
            }
            
            if chainingCount < allCount {
                shouldStop = true
                if isError {
                    handler(context: context)
                }
            }
        }
        handlerIDs += [handlerID]
        
        // invoke chainHandler on last route
        let lastRoute = chain.routes.last!
        handlerID = self.addHandler(lastRoute.transition, order: 200) { [weak self] context in
            if let self_ = self {
                if self_._canPassCondition(lastRoute.condition, transition: context.transition) {
                    if chainingCount == allCount && chainingCount == chain.routes.count && chainingCount == chain.routes.count {
                        shouldStop = true
                        
                        if !isError {
                            handler(context: context)
                        }
                    }
                }
            }
        }
        handlerIDs += [handlerID]
        
        let bundledHandlerID = HandlerID(bundledHandlerIDs: handlerIDs)
        
        return bundledHandlerID
    }
    
    //--------------------------------------------------
    // MARK: - RouteEvent
    //--------------------------------------------------
    
    public func addRouteEvent(event: Event, transitions: [Transition], condition: Condition? = nil) -> [RouteID]
    {
        var routes: [Route] = []
        for transition in transitions {
            let route = Route(transition: transition, condition: condition)
            routes += [route]
        }
        
        return self.addRouteEvent(event, routes: routes)
    }
    
    public func addRouteEvent(event: Event, transitions: [Transition], condition: @autoclosure () -> Bool) -> [RouteID]
    {
        return self.addRouteEvent(event, transitions: transitions, condition: { t in condition() })
    }
    
    public func addRouteEvent(event: Event, routes: [Route]) -> [RouteID]
    {
        var routeIDs: [RouteID] = []
        for route in routes {
            let routeID = self._addRoute(route, forEvent: event)
            routeIDs += [routeID]
        }
        
        return routeIDs
    }
    
    // MARK: addRouteEvent + conditional handler
    
    public func addRouteEvent(event: Event, transitions: [Transition], handler: Handler) -> ([RouteID], HandlerID)
    {
        return self.addRouteEvent(event, transitions: transitions, condition: nil, handler: handler)
    }
    
    public func addRouteEvent(event: Event, transitions: [Transition], condition: Condition?, handler: Handler) -> ([RouteID], HandlerID)
    {
        let routeIDs = self.addRouteEvent(event, transitions: transitions, condition: condition)
        
        let handlerID = self.addEventHandler(event, order: self.dynamicType._defaultOrder, handler: handler)
        
        return (routeIDs, handlerID)
    }

    public func addRouteEvent(event: Event, transitions: [Transition], condition: @autoclosure () -> Bool, handler: Handler) -> ([RouteID], HandlerID)
    {
        return self.addRouteEvent(event, transitions: transitions, condition: { t in condition() }, handler: handler)
    }
    
    public func addRouteEvent(event: Event, routes: [Route], handler: Handler) -> ([RouteID], HandlerID)
    {
        let routeIDs = self.addRouteEvent(event, routes: routes)
        
        let handlerID = self.addEventHandler(event, order: self.dynamicType._defaultOrder, handler: handler)
        
        return (routeIDs, handlerID)
    }
    
    // MARK: addEventHandler
    
    public func addEventHandler(event: Event, handler: Handler) -> HandlerID
    {
        return self.addEventHandler(event, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addEventHandler(event: Event, order: HandlerOrder, handler: Handler) -> HandlerID
    {
        let transitions = self._routes[event]?.keys
        
        let handlerID = self.addHandler(nil => nil, order: order) { [weak self] context in
            if context.event == event {
                handler(context: context)
            }
        }
        
        return handlerID
    }
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

infix operator <- { associativity right }

public func <- <S: StateType, E: StateEventType>(machine: StateMachine<S, E>, state: S) -> Bool
{
    return machine.tryState(state)
}

public func <- <S: StateType, E: StateEventType>(machine: StateMachine<S, E>, tuple: (S, Any?)) -> Bool
{
    return machine.tryState(tuple.0, userInfo: tuple.1)
}

infix operator <-! { associativity right }

public func <-! <S: StateType, E: StateEventType>(machine: StateMachine<S, E>, event: E) -> Bool
{
    return machine.tryEvent(event)
}

public func <-! <S: StateType, E: StateEventType>(machine: StateMachine<S, E>, tuple: (E, Any?)) -> Bool
{
    return machine.tryEvent(tuple.0, userInfo: tuple.1)
}
