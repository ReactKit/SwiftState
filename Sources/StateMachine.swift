//
//  StateMachine.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

///
/// State-machine which can `tryState()` (state-driven) as well as `tryEvent()` (event-driven).
///
/// - Note:
/// Use `NoEvent` type to ignore event-handlings whenever necessary.
///
public final class StateMachine<S: StateType, E: EventType>: Machine<S, E>
{
    /// Closure-based routes for `tryState()`.
    /// - Returns: Multiple `toState`s from single `fromState`, similar to `.State0 => [.State1, .State2]`
    public typealias StateRouteMapping = (fromState: S, userInfo: Any?) -> [S]?
    
    private lazy var _routes: _RouteDict = [:]
    private lazy var _routeMappings: [String : StateRouteMapping] = [:] // NOTE: `StateRouteMapping`, not `RouteMapping`
    
    /// `tryState()`-based handler collection.
    private lazy var _handlers: [Transition<S> : [_HandlerInfo<S, E>]] = [:]
    
    //--------------------------------------------------
    // MARK: - Init
    //--------------------------------------------------
    
    public override init(state: S, initClosure: (StateMachine -> ())? = nil)
    {
        super.init(state: state, initClosure: { machine in
            initClosure?(machine as! StateMachine<S, E>)
            return
        })
    }
    
    public override func configure(closure: StateMachine -> ())
    {
        closure(self)
    }
    
    //--------------------------------------------------
    // MARK: - hasRoute
    //--------------------------------------------------
    
    /// Check for added routes & routeMappings.
    /// - Note: This method also checks for event-based-routes.
    public func hasRoute(transition: Transition<S>, userInfo: Any? = nil) -> Bool
    {
        guard let fromState = transition.fromState.rawValue,
            toState = transition.toState.rawValue else
        {
            assertionFailure("State = `.Any` is not supported for `hasRoute()` (always returns `false`)")
            return false
        }
        
        return self.hasRoute(fromState: fromState, toState: toState, userInfo: userInfo)
    }
    
    /// Check for added routes & routeMappings.
    /// - Note: This method also checks for event-based-routes.
    public func hasRoute(fromState fromState: S, toState: S, userInfo: Any? = nil) -> Bool
    {
        if self._hasRouteInDict(fromState: fromState, toState: toState, userInfo: userInfo) {
            return true
        }
        
        if self._hasRouteMappingInDict(fromState: fromState, toState: toState, userInfo: userInfo) != nil {
            return true
        }
        
        // look for all event-based-routes
        return super._hasRoute(event: nil, fromState: fromState, toState: toState, userInfo: userInfo)
    }
    
    /// Check for `_routes`.
    private func _hasRouteInDict(fromState fromState: S, toState: S, userInfo: Any? = nil) -> Bool
    {
        let validTransitions = _validTransitions(fromState: fromState, toState: toState)
        
        for validTransition in validTransitions {
            
            // check for `_routes
            if let keyConditionDict = self._routes[validTransition] {
                for (_, condition) in keyConditionDict {
                    if _canPassCondition(condition, forEvent: nil, fromState: fromState, toState: toState, userInfo: userInfo) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Check for `_routeMappings`.
    private func _hasRouteMappingInDict(fromState fromState: S, toState: S, userInfo: Any? = nil) -> S?
    {
        for mapping in self._routeMappings.values {
            if let preferredToStates = mapping(fromState: fromState, userInfo: userInfo) {
                return preferredToStates.contains(toState) ? toState : nil
            }
        }
        
        return nil
    }
    
    //--------------------------------------------------
    // MARK: - tryState
    //--------------------------------------------------
    
    /// - Note: This method also checks for event-based-routes.
    public func canTryState(toState: S, userInfo: Any? = nil) -> Bool
    {
        return self.hasRoute(fromState: self.state, toState: toState, userInfo: userInfo)
    }
    
    /// - Note: This method also tries state-change for event-based-routes.
    public func tryState(toState: S, userInfo: Any? = nil) -> Bool
    {
        let fromState = self.state
        
        if self.canTryState(toState, userInfo: userInfo) {
            
            // collect valid handlers before updating state
            let validHandlerInfos = self._validHandlerInfos(fromState: fromState, toState: toState)
            
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
                handlerInfo.handler(Context(event: nil, fromState: fromState, toState: toState, userInfo: userInfo))
            }
            
            return true
            
        }
        else {
            for handlerInfo in self._errorHandlers {
                handlerInfo.handler(Context(event: nil, fromState: fromState, toState: toState, userInfo: userInfo))
            }
        }
        
        return false
    }
    
    private func _validHandlerInfos(fromState fromState: S, toState: S) -> [_HandlerInfo<S, E>]
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
    
    //--------------------------------------------------
    // MARK: - Route
    //--------------------------------------------------
    
    // MARK: addRoute (no-event)
    
    public func addRoute(transition: Transition<S>, condition: Condition? = nil) -> Disposable
    {
        let route = Route(transition: transition, condition: condition)
        return self.addRoute(route)
    }
    
    public func addRoute(route: Route<S, E>) -> Disposable
    {
        let transition = route.transition
        let condition = route.condition
        
        if self._routes[transition] == nil {
            self._routes[transition] = [:]
        }
        
        let key = _createUniqueString()
        
        var keyConditionDict = self._routes[transition]!
        keyConditionDict[key] = condition
        self._routes[transition] = keyConditionDict
        
        let _routeID = _RouteID(event: Optional<Event<E>>.None, transition: transition, key: key)
        
        return ActionDisposable.init { [weak self] in
            self?._removeRoute(_routeID)
        }
    }
    
    // MARK: addRoute (no-event) + conditional handler
    
    public func addRoute(transition: Transition<S>, condition: Condition? = nil, handler: Handler) -> Disposable
    {
        let route = Route(transition: transition, condition: condition)
        return self.addRoute(route, handler: handler)
    }
    
    public func addRoute(route: Route<S, E>, handler: Handler) -> Disposable
    {
        let transition = route.transition
        let condition = route.condition
        
        let routeDisposable = self.addRoute(transition, condition: condition)
        
        let handlerDisposable = self.addHandler(transition) { context in
            if _canPassCondition(condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                handler(context)
            }
        }
        
        return ActionDisposable.init {
            routeDisposable.dispose()
            handlerDisposable.dispose()
        }
    }
    
    // MARK: removeRoute
    
    private func _removeRoute(_routeID: _RouteID<S, E>) -> Bool
    {
        guard _routeID.event == nil else {
            return false
        }
        
        let transition = _routeID.transition
        
        guard let keyConditionDict_ = self._routes[transition] else {
            return false
        }
        var keyConditionDict = keyConditionDict_
        
        let removed = keyConditionDict.removeValueForKey(_routeID.key) != nil
        
        if keyConditionDict.count > 0 {
            self._routes[transition] = keyConditionDict
        }
        else {
            self._routes[transition] = nil
        }
        
        return removed
    }
    
    //--------------------------------------------------
    // MARK: - Handler
    //--------------------------------------------------

    // MARK: addHandler (no-event)
    
    public func addHandler(transition: Transition<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        if self._handlers[transition] == nil {
            self._handlers[transition] = []
        }
        
        let key = _createUniqueString()
        
        var handlerInfos = self._handlers[transition]!
        let newHandlerInfo = _HandlerInfo<S, E>(order: order, key: key, handler: handler)
        _insertHandlerIntoArray(&handlerInfos, newHandlerInfo: newHandlerInfo)
        
        self._handlers[transition] = handlerInfos
        
        let handlerID = _HandlerID<S, E>(event: nil, transition: transition, key: key)
        
        return ActionDisposable.init { [weak self] in
            self?._removeHandler(handlerID)
        }
    }
    
    // MARK: removeHandler
    
    private func _removeHandler(handlerID: _HandlerID<S, E>) -> Bool
    {
        if let transition = handlerID.transition {
            if let handlerInfos_ = self._handlers[transition] {
                var handlerInfos = handlerInfos_
                
                if _removeHandlerFromArray(&handlerInfos, removingHandlerID: handlerID) {
                    self._handlers[transition] = handlerInfos
                    return true
                }
            }
        }
        
        return false
    }
    
    //--------------------------------------------------
    // MARK: - RouteChain
    //--------------------------------------------------
    //
    // NOTE:
    // `RouteChain` allows to register `handler` which will be invoked
    // only when state-based-transitions in `RouteChain` succeeded continuously.
    //
    
    // MARK: addRouteChain + conditional handler
    
    public func addRouteChain(chain: TransitionChain<S>, condition: Condition? = nil, handler: Handler) -> Disposable
    {
        let routeChain = RouteChain(transitionChain: chain, condition: condition)
        return self.addRouteChain(routeChain, handler: handler)
    }
    
    public func addRouteChain(chain: RouteChain<S, E>, handler: Handler) -> Disposable
    {
        let routeDisposables = chain.routes.map { self.addRoute($0) }
        let handlerDisposable = self.addChainHandler(chain, handler: handler)
        
        return ActionDisposable.init {
            routeDisposables.forEach { $0.dispose() }
            handlerDisposable.dispose()
        }
    }
    
    // MARK: addChainHandler
    
    public func addChainHandler(chain: TransitionChain<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        return self.addChainHandler(RouteChain(transitionChain: chain), order: order, handler: handler)
    }
    
    public func addChainHandler(chain: RouteChain<S, E>, order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: false)
    }
    
    // MARK: addChainErrorHandler
    
    public func addChainErrorHandler(chain: TransitionChain<S>, order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        return self.addChainErrorHandler(RouteChain(transitionChain: chain), order: order, handler: handler)
    }
    
    public func addChainErrorHandler(chain: RouteChain<S, E>, order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: true)
    }
    
    private func _addChainHandler(chain: RouteChain<S, E>, order: HandlerOrder = _defaultOrder, handler: Handler, isError: Bool) -> Disposable
    {
        var handlerDisposables: [Disposable] = []
        
        var shouldStop = true
        var shouldIncrementChainingCount = true
        var chainingCount = 0
        var allCount = 0
        
        // reset count on 1st route
        let firstRoute = chain.routes.first!
        var handlerDisposable = self.addHandler(firstRoute.transition) { context in
            if _canPassCondition(firstRoute.condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                if shouldStop {
                    shouldStop = false
                    chainingCount = 0
                    allCount = 0
                }
            }
        }
        handlerDisposables += [handlerDisposable]
        
        // increment chainingCount on every route
        for route in chain.routes {
            
            handlerDisposable = self.addHandler(route.transition) { context in
                // skip duplicated transition handlers e.g. chain = 0 => 1 => 0 => 1 & transiting 0 => 1
                if !shouldIncrementChainingCount { return }
                
                if _canPassCondition(route.condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                    if !shouldStop {
                        chainingCount++
                        
                        shouldIncrementChainingCount = false
                    }
                }
            }
            handlerDisposables += [handlerDisposable]
        }
        
        // increment allCount (+ invoke chainErrorHandler) on any routes
        handlerDisposable = self.addHandler(.Any => .Any, order: 150) { context in
            
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
        handlerDisposables += [handlerDisposable]
        
        // invoke chainHandler on last route
        let lastRoute = chain.routes.last!
        handlerDisposable = self.addHandler(lastRoute.transition, order: 200) { context in
            if _canPassCondition(lastRoute.condition, forEvent: nil, fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) {
                if chainingCount == allCount && chainingCount == chain.routes.count && chainingCount == chain.routes.count {
                    shouldStop = true
                    
                    if !isError {
                        handler(context)
                    }
                }
            }
        }
        handlerDisposables += [handlerDisposable]
        
        return ActionDisposable.init {
            handlerDisposables.forEach { $0.dispose() }
        }
    }
    
    //--------------------------------------------------
    // MARK: - StateRouteMapping
    //--------------------------------------------------
    
    // MARK: addStateRouteMapping
    
    public func addStateRouteMapping(routeMapping: StateRouteMapping) -> Disposable
    {
        let key = _createUniqueString()
        
        self._routeMappings[key] = routeMapping
        
        let routeMappingID = _RouteMappingID(key: key)
        
        return ActionDisposable.init { [weak self] in
            self?._removeStateRouteMapping(routeMappingID)
        }
    }
    
    // MARK: addStateRouteMapping + conditional handler
    
    public func addStateRouteMapping(routeMapping: StateRouteMapping, handler: Handler) -> Disposable
    {
        let routeDisposable = self.addStateRouteMapping(routeMapping)
        
        let handlerDisposable = self.addHandler(.Any => .Any) { context in
            if self._hasRouteMappingInDict(fromState: context.fromState, toState: context.toState, userInfo: context.userInfo) != nil {
                handler(context)
            }
        }
        
        return ActionDisposable.init {
            routeDisposable.dispose()
            handlerDisposable.dispose()
        }
    }
    
    // MARK: removeStateRouteMapping
    
    private func _removeStateRouteMapping(routeMappingID: _RouteMappingID) -> Bool
    {
        if self._routeMappings[routeMappingID.key] != nil {
            self._routeMappings[routeMappingID.key] = nil
            return true
        }
        else {
            return false
        }
    }
    
}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

// MARK: `<-` (tryState)

infix operator <- { associativity left }

public func <- <S: StateType, E: EventType>(machine: StateMachine<S, E>, state: S) -> StateMachine<S, E>
{
    machine.tryState(state)
    return machine
}

public func <- <S: StateType, E: EventType>(machine: StateMachine<S, E>, tuple: (S, Any?)) -> StateMachine<S, E>
{
    machine.tryState(tuple.0, userInfo: tuple.1)
    return machine
}