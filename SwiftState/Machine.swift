//
//  Machine.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import Darwin

public typealias HandlerOrder = UInt8
private let _defaultOrder: HandlerOrder = 100

public class Machine<S: StateType, E: EventType>
{
    // NOTE: `event = nil` is equivalent to `_Event.None`, which happens when non-event-based transition e.g. `tryState()` occurs.
    public typealias Context = (event: E?, fromState: S, toState: S, userInfo: Any?)
    
    public typealias Condition = (Context -> Bool)
    
    public typealias Handler = Context -> ()
    
    public typealias Mapping = (event: E?, fromState: S, userInfo: Any?) -> S?
    
    private var _routes: [_Event<E> : [Transition<S> : [String : Condition?]]] = [:]
    
    private var _routeMappings: [String : Mapping] = [:]
    
    private var _handlers: [Transition<S> : [_HandlerInfo<S, E>]] = [:]
    private var _errorHandlers: [_HandlerInfo<S, E>] = []
    
    internal var _state: S
    
    //--------------------------------------------------
    // MARK: - Init
    //--------------------------------------------------
    
    public init(state: S, initClosure: (Machine -> ())? = nil)
    {
        self._state = state
        
        initClosure?(self)
    }
    
    public func configure(closure: Machine -> ())
    {
        closure(self)
    }
    
    //--------------------------------------------------
    // MARK: - State/Event/Transition
    //--------------------------------------------------
    
    public var state: S
    {
        return self._state
    }
    
    public func hasRoute(transition: Transition<S>, forEvent event: E? = nil, userInfo: Any? = nil) -> Bool
    {
        guard let fromState = transition.fromState.value,
            toState = transition.toState.value else
        {
            assertionFailure("State = `.Any` is not supported for `hasRoute()` (always returns `false`)")
            return false
        }
        
        return self.hasRoute(fromState: fromState, toState: toState, forEvent: event, userInfo: userInfo)
    }
    
    public func hasRoute(fromState fromState: S, toState: S, forEvent event: E? = nil, userInfo: Any? = nil) -> Bool
    {
        if _hasRoute(fromState: fromState, toState: toState, forEvent: event, userInfo: userInfo) {
            return true
        }
        
        if _hasRouteMapping(fromState: fromState, toState: .Some(toState), forEvent: event, userInfo: userInfo) != nil {
            return true
        }
        
        return false
    }
    
    public func hasRoute(fromState fromState: S, toState: S, forEvent event: E, userInfo: Any? = nil) -> Bool
    {
        return self.hasRoute(fromState: fromState, toState: toState, forEvent: .Some(event), userInfo: userInfo)
    }
    
    ///
    /// Check for `_routes`.
    ///
    /// - Parameter event:
    ///   If `event` is nil, all registered routes will be examined.
    ///   Otherwise, only routes for `event` and `.Any` will be examined.
    ///
    private func _hasRoute(fromState fromState: S, toState: S, forEvent event: E? = nil, userInfo: Any? = nil) -> Bool
    {
        let validTransitions = _validTransitions(fromState: fromState, toState: toState)
        
        for validTransition in validTransitions {
            
            var transitionDicts: [[Transition<S> : [String : Condition?]]] = []
            
            if let event = event {
                for (ev, transitionDict) in self._routes {
                    if ev.value == event || ev == .Any {    // NOTE: no .Default
                        transitionDicts += [transitionDict]
                    }
                }
            }
            else {
                transitionDicts += self._routes.values.lazy
            }
            
            // check for `_routes
            for transitionDict in transitionDicts {
                if let keyConditionDict = transitionDict[validTransition] {
                    for (_, condition) in keyConditionDict {
                        if _canPassCondition(condition, forEvent: event, fromState: fromState, toState: toState, userInfo: userInfo) {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    ///
    /// Check for `_routeMappings`.
    ///
    /// - Returns: Preferred `mapped-toState` in case of `toState = .Any`.
    ///
    private func _hasRouteMapping(fromState fromState: S, toState: State<S>, forEvent event: E? = nil, userInfo: Any? = nil) -> S?
    {
        for mapping in self._routeMappings.values {
            if let mappedToState = mapping(event: event, fromState: fromState, userInfo: userInfo)
                where mappedToState == toState.value || toState == .Any
            {
                return mappedToState
            }
        }
        
        return nil
    }
    
    public func canTryState(toState: S, forEvent event: E? = nil) -> Bool
    {
        let fromState = self.state
        
        return self.hasRoute(fromState: fromState, toState: toState, forEvent: event)
    }
    
    public func canTryState(toState: S, forEvent event: E) -> Bool
    {
        return self.canTryState(toState, forEvent: .Some(event))
    }
    
    public func tryState(toState: S, userInfo: Any? = nil) -> Bool
    {
        return self._tryState(toState, userInfo: userInfo, forEvent: nil)
    }
    
    internal func _tryState(toState: S, userInfo: Any? = nil, forEvent event: E?) -> Bool
    {
        var didTransit = false
        
        let fromState = self.state
        
        if self.canTryState(toState, forEvent: event) {
            
            // collect valid handlers before updating state
            let validHandlerInfos = self._validHandlerInfosForTransition(fromState: fromState, toState: toState)
            
            // update state
            self._state = toState
            
            //
            // Perform validHandlers after updating state.
            //
            // NOTE:
            // Instead of using before/after handlers as seen in many other Machine libraries,
            // SwiftState uses `order` value to perform handlers in 'fine-grained' order,
            // only after state has been updated. (Any problem?)
            //
            for handlerInfo in validHandlerInfos {
                handlerInfo.handler(Context(event: event, fromState: fromState, toState: toState, userInfo: userInfo))
            }
            
            didTransit = true
        }
        else {
            for handlerInfo in self._errorHandlers {
                handlerInfo.handler(Context(event: event, fromState: fromState, toState: toState, userInfo: userInfo))
            }
        }
        
        return didTransit
    }
    
    private func _validHandlerInfosForTransition(fromState fromState: S, toState: S) -> [_HandlerInfo<S, E>]
    {
        var validHandlerInfos: [_HandlerInfo<S, E>] = []
        
        let validTransitions = _validTransitions(fromState: fromState, toState: toState)
        
        for validTransition in validTransitions {
            if let handlerInfos = self._handlers[validTransition] {
                for handlerInfo in handlerInfos {
                    validHandlerInfos += [handlerInfo]
                }
            }
        }
        
        validHandlerInfos.sortInPlace { info1, info2 in
            return info1.order < info2.order
        }
        
        return validHandlerInfos
    }
    
    public func canTryEvent(event: E, userInfo: Any? = nil) -> S?
    {
        if let transitionDict = self._routes[_Event.Some(event)] {
            for (transition, keyConditionDict) in transitionDict {
                if transition.fromState == .Some(self.state) || transition.fromState == .Any {
                    for (_, condition) in keyConditionDict {
                        // if toState is `.Any`, it means identity transition
                        let toState = transition.toState.value ?? self.state
                        
                        if _canPassCondition(condition, forEvent: .Some(event), fromState: self.state, toState: toState, userInfo: userInfo) {
                            return toState
                        }
                    }
                }
            }
        }
        
        if let toState = _hasRouteMapping(fromState: self.state, toState: .Any, forEvent: event, userInfo: userInfo) {
            return toState
        }
        
        return nil
    }
    
    public func tryEvent(event: E, userInfo: Any? = nil) -> Bool
    {
        if let toState = self.canTryEvent(event, userInfo: userInfo) {
            self._tryState(toState, userInfo: userInfo, forEvent: .Some(event))
            return true
        }
        
        return false
    }
    
    //--------------------------------------------------
    // MARK: - Route
    //--------------------------------------------------
    
    // MARK: addRoute
    
    public func addRoute(transition: Transition<S>, condition: Condition? = nil) -> RouteID<S, E>
    {
        let route = Route(transition: transition, condition: condition)
        return self.addRoute(route)
    }
    
    public func addRoute(route: Route<S, E>) -> RouteID<S, E>
    {
        return self._addRoute(route)
    }
    
    internal func _addRoute(route: Route<S, E>, forEvent event: _Event<E> = .None) -> RouteID<S, E>
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
        
        let key = _createUniqueString()
        
        var keyConditionDict = transitionDict[transition]!
        keyConditionDict[key] = condition
        transitionDict[transition] = keyConditionDict
        
        self._routes[event] = transitionDict
        
        let routeID = RouteID(event: event, transition: transition, key: key)
        
        return routeID
    }
    
    // MARK: addRoute + conditional handler
    
    public func addRoute(transition: Transition<S>, condition: Condition? = nil, handler: Handler) -> (RouteID<S, E>, HandlerID<S, E>)
    {
        let route = Route(transition: transition, condition: condition)
        return self.addRoute(route, handler: handler)
    }
    
    public func addRoute(route: Route<S, E>, handler: Handler) -> (RouteID<S, E>, HandlerID<S, E>)
    {
        let transition = route.transition
        let condition = route.condition
        
        let routeID = self.addRoute(transition, condition: condition)
        
        let handlerID = self.addHandler(transition) { context in
            if _canPassCondition(condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                handler(context)
            }
        }
        
        return (routeID, handlerID)
    }
    
    // MARK: removeRoute
    
    public func removeRoute(routeID: RouteID<S, E>) -> Bool
    {
        let event = routeID.event
        let transition = routeID.transition
        
        if var transitionDict = self._routes[event] {
            if var keyConditionDict = transitionDict[transition] {
                keyConditionDict[routeID.key] = nil
                if keyConditionDict.count > 0 {
                    transitionDict[transition] = keyConditionDict
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
        
        return false
    }
    
    //--------------------------------------------------
    // MARK: - Handler
    //--------------------------------------------------

    public func addHandler(transition: Transition<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        if self._handlers[transition] == nil {
            self._handlers[transition] = []
        }
        
        let key = _createUniqueString()
        
        var handlerInfos = self._handlers[transition]!
        let newHandlerInfo = _HandlerInfo<S, E>(order: order, key: key, handler: handler)
        _insertHandlerIntoArray(&handlerInfos, newHandlerInfo: newHandlerInfo)
        
        self._handlers[transition] = handlerInfos
        
        let handlerID = HandlerID<S, E>(transition: transition, key: key)
        
        return handlerID
    }
    
    // MARK: addEntryHandler
    
    public func addEntryHandler(state: State<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        return self.addHandler(.Any => state, handler: handler)
    }
    
    public func addEntryHandler(state: S, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        return self.addHandler(.Any => .Some(state), handler: handler)
    }
    
    // MARK: addExitHandler
    
    public func addExitHandler(state: State<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        return self.addHandler(state => .Any, handler: handler)
    }
    
    public func addExitHandler(state: S, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        return self.addHandler(.Some(state) => .Any, handler: handler)
    }
    
    // MARK: removeHandler
    
    public func removeHandler(handlerID: HandlerID<S, E>) -> Bool
    {
        if let transition = handlerID.transition {
            if var handlerInfos = self._handlers[transition] {
                
                if _removeHandlerFromArray(&handlerInfos, removingHandlerID: handlerID) {
                    self._handlers[transition] = handlerInfos
                    return true
                }
            }
        }
        // `transition = nil` means errorHandler
        else {
            if _removeHandlerFromArray(&self._errorHandlers, removingHandlerID: handlerID) {
                return true
            }
            return false
        }
        
        return false
    }
    
    // MARK: addErrorHandler
    
    public func addErrorHandler(order order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        let key = _createUniqueString()
        
        let newHandlerInfo = _HandlerInfo<S, E>(order: order, key: key, handler: handler)
        _insertHandlerIntoArray(&self._errorHandlers, newHandlerInfo: newHandlerInfo)
        
        let handlerID = HandlerID<S, E>(transition: nil, key: key)
        
        return handlerID
    }
    
    //--------------------------------------------------
    // MARK: - RouteChain
    //--------------------------------------------------
    // NOTE: handler is required for addRouteChain
    
    // MARK: addRouteChain + conditional handler
    
    public func addRouteChain(chain: TransitionChain<S>, condition: Condition? = nil, handler: Handler) -> (RouteChainID<S, E>, ChainHandlerID<S, E>)
    {
        let routeChain = RouteChain(transitionChain: chain, condition: condition)
        return self.addRouteChain(routeChain, handler: handler)
    }
    
    public func addRouteChain(chain: RouteChain<S, E>, handler: Handler) -> (RouteChainID<S, E>, ChainHandlerID<S, E>)
    {
        var routeIDs: [RouteID<S, E>] = []
        
        for route in chain.routes {
            let routeID = self.addRoute(route)
            routeIDs += [routeID]
        }
        
        let chainHandlerID = self.addChainHandler(chain, handler: handler)
        
        let routeChainID = RouteChainID<S, E>(bundledRouteIDs: routeIDs)
        
        return (routeChainID, chainHandlerID)
    }
    
    // MARK: addChainHandler
    
    public func addChainHandler(chain: TransitionChain<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> ChainHandlerID<S, E>
    {
        return self.addChainHandler(chain.toRouteChain(), order: order, handler: handler)
    }
    
    public func addChainHandler(chain: RouteChain<S, E>, order: HandlerOrder = _defaultOrder, handler: Handler) -> ChainHandlerID<S, E>
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: false)
    }
    
    // MARK: addChainErrorHandler
    
    public func addChainErrorHandler(chain: TransitionChain<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> ChainHandlerID<S, E>
    {
        return self.addChainErrorHandler(chain.toRouteChain(), order: order, handler: handler)
    }
    
    public func addChainErrorHandler(chain: RouteChain<S, E>, order: HandlerOrder = _defaultOrder, handler: Handler) -> ChainHandlerID<S, E>
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: true)
    }
    
    private func _addChainHandler(chain: RouteChain<S, E>, order: HandlerOrder, handler: Handler, isError: Bool) -> ChainHandlerID<S, E>
    {
        var handlerIDs: [HandlerID<S, E>] = []
        
        var shouldStop = true
        var shouldIncrementChainingCount = true
        var chainingCount = 0
        var allCount = 0
        
        // reset count on 1st route
        let firstRoute = chain.routes.first!
        var handlerID = self.addHandler(firstRoute.transition) { context in
            if _canPassCondition(firstRoute.condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                if shouldStop {
                    shouldStop = false
                    chainingCount = 0
                    allCount = 0
                }
            }
        }
        handlerIDs += [handlerID]
        
        // increment chainingCount on every route
        for route in chain.routes {
            
            handlerID = self.addHandler(route.transition) { context in
                // skip duplicated transition handlers e.g. chain = 0 => 1 => 0 => 1 & transiting 0 => 1
                if !shouldIncrementChainingCount { return }
                
                if _canPassCondition(route.condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                    if !shouldStop {
                        chainingCount++
                        
                        shouldIncrementChainingCount = false
                    }
                }
            }
            handlerIDs += [handlerID]
        }
        
        // increment allCount (+ invoke chainErrorHandler) on any routes
        handlerID = self.addHandler(.Any => .Any, order: 150) { context in
            
            shouldIncrementChainingCount = true
            
            if !shouldStop {
                allCount++
            }
            
            if chainingCount < allCount {
                shouldStop = true
                if isError {
                    handler(context)
                }
            }
        }
        handlerIDs += [handlerID]
        
        // invoke chainHandler on last route
        let lastRoute = chain.routes.last!
        handlerID = self.addHandler(lastRoute.transition, order: 200) { context in
            if _canPassCondition(lastRoute.condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                if chainingCount == allCount && chainingCount == chain.routes.count && chainingCount == chain.routes.count {
                    shouldStop = true
                    
                    if !isError {
                        handler(context)
                    }
                }
            }
        }
        handlerIDs += [handlerID]
        
        let chainHandlerID = ChainHandlerID<S, E>(bundledHandlerIDs: handlerIDs)
        
        return chainHandlerID
    }
    
    // MARK: removeRouteChain
    
    public func removeRouteChain(routeChainID: RouteChainID<S, E>) -> Bool
    {
        var success = false
        for bundledRouteID in routeChainID.bundledRouteIDs! {
            success = self.removeRoute(bundledRouteID) || success
        }
        return success
    }
    
    // MARK: removeChainHandler
    
    public func removeChainHandler(chainHandlerID: ChainHandlerID<S, E>) -> Bool
    {
        var success = false
        for bundledHandlerID in chainHandlerID.bundledHandlerIDs {
            success = self.removeHandler(bundledHandlerID) || success
        }
        return success
    }
    
    //--------------------------------------------------
    // MARK: - RouteEvent
    //--------------------------------------------------
    
    public func addRouteEvent(event: Event<E>, transitions: [Transition<S>], condition: Condition? = nil) -> [RouteID<S, E>]
    {
        var routes: [Route<S, E>] = []
        for transition in transitions {
            let route = Route(transition: transition, condition: condition)
            routes += [route]
        }
        
        return self.addRouteEvent(event, routes: routes)
    }
    
    public func addRouteEvent(event: E, transitions: [Transition<S>], condition: Condition? = nil) -> [RouteID<S, E>]
    {
        return self.addRouteEvent(.Some(event), transitions: transitions, condition: condition)
    }
    
    public func addRouteEvent(event: Event<E>, routes: [Route<S, E>]) -> [RouteID<S, E>]
    {
        var routeIDs: [RouteID<S, E>] = []
        for route in routes {
            let routeID = self._addRoute(route, forEvent: event._toInternal())
            routeIDs += [routeID]
        }
        
        return routeIDs
    }
    
    public func addRouteEvent(event: E, routes: [Route<S, E>]) -> [RouteID<S, E>]
    {
        return self.addRouteEvent(.Some(event), routes: routes)
    }
    
    // MARK: addRouteEvent + conditional handler
    
    public func addRouteEvent(event: Event<E>, transitions: [Transition<S>], condition: Condition? = nil, handler: Handler) -> ([RouteID<S, E>], HandlerID<S, E>)
    {
        let routeIDs = self.addRouteEvent(event, transitions: transitions, condition: condition)
        
        let handlerID = self.addEventHandler(event, handler: handler)
        
        return (routeIDs, handlerID)
    }
    
    public func addRouteEvent(event: E, transitions: [Transition<S>], condition: Condition? = nil, handler: Handler) -> ([RouteID<S, E>], HandlerID<S, E>)
    {
        return self.addRouteEvent(.Some(event), transitions: transitions, condition: condition, handler: handler)
    }
    
    public func addRouteEvent(event: Event<E>, routes: [Route<S, E>], handler: Handler) -> ([RouteID<S, E>], HandlerID<S, E>)
    {
        let routeIDs = self.addRouteEvent(event, routes: routes)
        
        let handlerID = self.addEventHandler(event, handler: handler)
        
        return (routeIDs, handlerID)
    }
    
    public func addRouteEvent(event: E, routes: [Route<S, E>], handler: Handler) -> ([RouteID<S, E>], HandlerID<S, E>)
    {
        return self.addRouteEvent(.Some(event), routes: routes, handler: handler)
    }
    
    // MARK: addEventHandler
    
    public func addEventHandler(event: Event<E>, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        let handlerID = self.addHandler(.Any => .Any, order: order) { context in
            // skip if not event-based transition
            guard let triggeredEvent = context.event else {
                return
            }
            
            if triggeredEvent == event.value || event == .Any {
                handler(context)
            }
        }
        
        return handlerID
    }
    
    public func addEventHandler(event: E, order: HandlerOrder = _defaultOrder, handler: Handler) -> HandlerID<S, E>
    {
        return self.addEventHandler(.Some(event), order: order, handler: handler)
    }
    
    //--------------------------------------------------
    // MARK: - RouteMapping
    //--------------------------------------------------
    
    // MARK: addRouteMapping
    
    public func addRouteMapping(routeMapping: Mapping) -> RouteMappingID
    {
        let key = _createUniqueString()
        
        self._routeMappings[key] = routeMapping
        
        let routeID = RouteMappingID(key: key)
        
        return routeID
    }
    
    // MARK: addRouteMapping + conditional handler
    
    public func addRouteMapping(routeMapping: Mapping, handler: Handler) -> (RouteMappingID, HandlerID<S, E>)
    {
        let routeMappingID = self.addRouteMapping(routeMapping)
        
        let handlerID = self.addHandler(.Any => .Any) { context in
            if self._hasRouteMapping(fromState: context.fromState, toState: .Some(context.toState), forEvent: context.event, userInfo: context.userInfo) != nil {
                
                handler(context)
            }
        }
        
        return (routeMappingID, handlerID)
    }
    
    // MARK: removeRouteMapping
    
    public func removeRouteMapping(routeMappingID: RouteMappingID) -> Bool
    {
        if self._routeMappings[routeMappingID.key] != nil {
            self._routeMappings[routeMappingID.key] = nil
            return true
        }
        else {
            return false
        }
    }
    
    //--------------------------------------------------
    // MARK: - Remove All
    //--------------------------------------------------
    
    public func removeAllRoutes() -> Bool
    {
        let removingCount = self._routes.count + self._routeMappings.count
        
        self._routes = [:]
        self._routeMappings = [:]
        
        return removingCount > 0
    }
    
    public func removeAllHandlers() -> Bool
    {
        let removingCount = self._handlers.count + self._errorHandlers.count
        
        self._handlers = [:]
        self._errorHandlers = []
        
        return removingCount > 0
    }
    
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

// MARK: <- (tryState)

infix operator <- { associativity right }

public func <- <S: StateType, E: EventType>(machine: Machine<S, E>, state: S) -> Bool
{
    return machine.tryState(state)
}

public func <- <S: StateType, E: EventType>(machine: Machine<S, E>, tuple: (S, Any?)) -> Bool
{
    return machine.tryState(tuple.0, userInfo: tuple.1)
}

// MARK: <-! (tryEvent)

infix operator <-! { associativity right }

public func <-! <S: StateType, E: EventType>(machine: Machine<S, E>, event: E) -> Bool
{
    return machine.tryEvent(event)
}

public func <-! <S: StateType, E: EventType>(machine: Machine<S, E>, tuple: (E, Any?)) -> Bool
{
    return machine.tryEvent(tuple.0, userInfo: tuple.1)
}

//--------------------------------------------------
// MARK: - Private
//--------------------------------------------------

// generate approx 126bit random string
private func _createUniqueString() -> String
{
    var uniqueString: String = ""
    for _ in 1...8 {
        uniqueString += String(UnicodeScalar(arc4random_uniform(0xD800))) // 0xD800 = 55296 = 15.755bit
    }
    return uniqueString
}


private func _validTransitions<S: StateType>(fromState fromState: S, toState: S) -> [Transition<S>]
{
    return [
        fromState => toState,
        fromState => .Any,
        .Any => toState,
        .Any => .Any
    ]
}

private func _canPassCondition<S: StateType, E: EventType>(condition: Machine<S, E>.Condition?, forEvent event: E?, fromState: S, toState: S, userInfo: Any?) -> Bool
{
    return condition?((event, fromState, toState, userInfo)) ?? true
}

private func _insertHandlerIntoArray<S: StateType, E: EventType>(inout handlerInfos: [_HandlerInfo<S, E>], newHandlerInfo: _HandlerInfo<S, E>)
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

private func _removeHandlerFromArray<S: StateType, E: EventType>(inout handlerInfos: [_HandlerInfo<S, E>], removingHandlerID: HandlerID<S, E>) -> Bool
{
    for i in 0..<handlerInfos.count {
        if handlerInfos[i].key == removingHandlerID.key {
            handlerInfos.removeAtIndex(i)
            return true
        }
    }
    
    return false
}

private class _HandlerInfo<S: StateType, E: EventType>
{
    private let order: HandlerOrder
    private let key: String
    private let handler: Machine<S, E>.Handler
    
    private init(order: HandlerOrder, key: String, handler: Machine<S, E>.Handler)
    {
        self.order = order
        self.key = key
        self.handler = handler
    }
}
