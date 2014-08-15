//
//  StateMachine.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/03.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import Darwin

// TODO: change Array() to []
// TODO: change Dictionary to []
// TODO: change .append() to +=

// TODO: nest inside StateMachine class
public struct StateMachineRouteID<S: StateType, E: StateEventType>
{
    private let transition: StateTransition<S>?
    private let routeKey: StateMachine<S, E>.RouteKey?
    private let event: E?
    
    private let bundledRouteIDs: [StateMachineRouteID<S, E>]?
    
    private init(transition: StateTransition<S>?, routeKey: StateMachine<S, E>.RouteKey?, event: E?)
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

// TODO: nest inside StateMachine class
public struct StateMachineHandlerID<S: StateType, E: StateEventType>
{
    private let transition: StateTransition<S>? // NOTE: nil is used for error-handlerID
    private let handlerKey: StateMachine<S, E>.HandlerKey?
    
    private let bundledHandlerIDs: [StateMachineHandlerID<S, E>]?
    
    private init(transition: StateTransition<S>?, handlerKey: StateMachine<S, E>.HandlerKey?)
    {
        self.transition = transition
        self.handlerKey = handlerKey
    }
    
    private init(bundledHandlerIDs: [StateMachineHandlerID<S, E>]?)
    {
        self.bundledHandlerIDs = bundledHandlerIDs
    }
}

// TODO: nest inside StateMachine class
private struct _StateMachineHandlerInfo<S: StateType, E: StateEventType>
{
    private let order: StateMachine<S, E>.OrderType
    private let handlerKey: StateMachine<S, E>.HandlerKey
    private let handler: StateMachine<S, E>.Handler
}

public class StateMachine<S: StateType, E: StateEventType>
{
    public typealias OrderType = UInt8
    public typealias Handler = ((context: HandlerContext) -> Void)
    public typealias HandlerContext = (event: Event, transition: Transition, order: OrderType, userInfo: Any?)
    
    private typealias State = S
    private typealias Event = E
    private typealias Transition = StateTransition<State>
    private typealias TransitionChain = StateTransitionChain<State>
    
    private typealias Route = StateRoute<State>
    private typealias RouteKey = String
    private typealias RouteID = StateMachineRouteID<State, Event>
    private typealias RouteChain = StateRouteChain<State>
    
    private typealias Condition = Route.Condition
    
    private typealias HandlerKey = String
    private typealias HandlerID = StateMachineHandlerID<State, Event>
    private typealias HandlerInfo = _StateMachineHandlerInfo<State, Event>
    // NOTE: don't use tuple due to Array's copying behavior for closure
//    private typealias HandlerInfo = (order: OrderType, handlerKey: HandlerKey, handler: Handler)
    
    private typealias TransitionRouteDictionary = [Transition : [RouteKey : Condition?]]
    
    private var _routes: [Event : TransitionRouteDictionary] = Dictionary()
    private var _handlers: [Transition : [HandlerInfo]] = Dictionary()
    private var _errorHandlers: [HandlerInfo] = Array()
    
    private var _state: State
    
    private class var _defaultOrder: OrderType { return 100 }
    
    //--------------------------------------------------
    // MARK: - Utility
    //--------------------------------------------------
    
    // generate approx 126bit random string
    private class func _createUniqueString() -> String
    {
        var uniqueString: String = ""
        for i in 1...8 {
            uniqueString += String(UnicodeScalar(arc4random_uniform(UInt32.max) % 0xD800)) // 0xD800 = 55296 = 15.755bit
        }
        //println("uniqueString = \(uniqueString)")
        return uniqueString
    }
    
    //--------------------------------------------------
    // MARK: - Init
    //--------------------------------------------------
    
    public init(state: State, initClosure: (StateMachine -> Void)? = nil)
    {
        self._state = state
        
        if let initClosure_ = initClosure {
            initClosure_(self)
        }
    }
    
    public func configure(closure: StateMachine -> Void)
    {
        closure(self)
    }
    
    public var state: State
    {
        return self._state
    }
    
    public func hasTransition(transition: Transition) -> Bool
    {
        return self._validTransitionsForTransition(transition).count > 0
    }
    
    public func hasRoute(transition: Transition, forEvent event: Event = Event.anyStateEvent()) -> Bool
    {
        let validTransitions = self._validTransitionsForTransition(transition)
        
        for validTransition in validTransitions {
            
            var transitionDicts: [TransitionRouteDictionary] = []
            
            if event == Event.anyStateEvent() {
                transitionDicts += self._routes.values.array
            }
            else {
                for (ev, transitionDict) in self._routes {
                    if ev == event || ev == Event.anyStateEvent() {
                        transitionDicts.append(transitionDict)
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
    
    public func canTryState(state: State, forEvent event: Event = Event.anyStateEvent()) -> Bool
    {
        let oldValue = self._state
        let newValue = state
        
        return  self.hasRoute(oldValue => newValue, forEvent: event)
    }
    
    public func tryState(state: State, userInfo: Any? = nil) -> Bool
    {
        return self._tryState(state, userInfo: userInfo, forEvent: Event.anyStateEvent())
    }
    
    private func _tryState(state: State, userInfo: Any? = nil, forEvent event: Event) -> Bool
    {
        var didTransit = false
        
        let oldValue = self._state
        let newValue = state
        let transition = oldValue => newValue
        
        if self.canTryState(state, forEvent: event) {
            
            // collect valid handlers before updating state
            let validHandlerInfos = self._validHandlerInfosForTransition(transition)
            
            // update state
            self._state = newValue
            
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
        var transitions: [Transition] = Array()
        
        // anywhere
        transitions.append(nil => nil)
        
        // exit
        if transition.fromState != nil as State {
            transitions.append(transition.fromState => nil)
        }
        
        // entry
        if transition.toState != nil as State {
            transitions.append(nil => transition.toState)
        }
        
        // specific
        if (transition.fromState != nil as State) && (transition.toState != nil as State) {
            transitions.append(transition)
        }
        
        return transitions
    }
    
    public func canTryEvent(event: Event) -> State?
    {
        var validEvents: [Event] = []
        if event == Event.anyStateEvent() {
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
    
    private func _addRoute(route: Route, forEvent event: Event = Event.anyStateEvent()) -> RouteID
    {
        let transition = route.transition
        let condition = route.condition
        
        if self._routes[event] == nil {
            self._routes[event] = Dictionary()
        }
        
        var transitionDict = self._routes[event]!
        if transitionDict[transition] == nil {
            transitionDict[transition] = Dictionary()
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
            if self == nil { return }
            let self_ = self!
            
            if self_._canPassCondition(condition, transition: context.transition) {
                handler(context: context)
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
    
//    public func removeTransition(transition: Transition, removeHandlers: Bool = true)
//    {
//        if self._routes[transition] {
//            self._routes[transition] = nil
//        }
//        
//        if removeHandlers {
//            self.removeAllHandlers(inTransition: transition)
//        }
//    }
//    
//    public func removeAllTransitions(removeHandlers: Bool = true)
//    {
//        self._routes.removeAll(keepCapacity: false)
//        
//        if removeHandlers {
//            self.removeAllHandlers()
//        }
//    }
    
    //--------------------------------------------------
    // MARK: - Handler
    //--------------------------------------------------

    public func addHandler(transition: Transition, handler: Handler) -> HandlerID
    {
        return self.addHandler(transition, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addHandler(transition: Transition, order: OrderType, handler: Handler) -> HandlerID
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
    
    public func addEntryHandler(state: State, order: OrderType, handler: Handler) -> HandlerID
    {
        return self.addHandler(nil => state, handler: handler)
    }
    
    // MARK: addExitHandler
    
    public func addExitHandler(state: State, handler: Handler) -> HandlerID
    {
        return self.addHandler(state => nil, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addExitHandler(state: State, order: OrderType, handler: Handler) -> HandlerID
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
    
//    public func removeAllHandlers(inTransition transition: Transition? = nil) -> Bool
//    {
//        if let transition_ = transition {
//            if self._handlers[transition_] != nil {
//                self._handlers[transition_] = nil
//                return true
//            }
//        }
//        else {
//            self._handlers.removeAll(keepCapacity: false)
//            return true
//        }
//        
//        return false
//    }
    
    // MARK: addErrorHandler
    
    public func addErrorHandler(handler: Handler) -> HandlerID
    {
        return self.addErrorHandler(order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addErrorHandler(#order: OrderType, handler: Handler) -> HandlerID
    {
        let handlerKey = self.dynamicType._createUniqueString()
        
        let newHandlerInfo = HandlerInfo(order: order, handlerKey: handlerKey, handler: handler)
        self._insertHandlerIntoArray(&self._errorHandlers, newHandlerInfo: newHandlerInfo)
        
        let handlerID = HandlerID(transition: nil, handlerKey: handlerKey)
        
        return handlerID
    }
    
//    public func removeAllErrorHandlers() -> Bool
//    {
//        if self._errorHandlers.count > 0 {
//            self._errorHandlers = []
//            return true
//        }
//        return false
//    }
    
    //--------------------------------------------------
    // MARK: - RouteChain
    // TODO: move to extension
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
        var routeIDs: [RouteID] = Array()
        
        for route in chain.routes {
            let routeID = self.addRoute(route)
            routeIDs.append(routeID)
        }
        
        let handlerID = self.addChainHandler(chain, handler: handler)
        
        let bundledRouteID = RouteID(bundledRouteIDs: routeIDs)
        
        return (bundledRouteID, handlerID)
    }
    
    // MARK: addChainHandler
    
    public func addChainHandler(chain: TransitionChain, handler: Handler) -> HandlerID
    {
        let routeChain = RouteChain(transitionChain: chain, condition: nil)
        return self.addChainHandler(routeChain, handler: handler)
    }
    
    public func addChainHandler(chain: TransitionChain, order: OrderType, handler: Handler) -> HandlerID
    {
        let routeChain = RouteChain(transitionChain: chain, condition: nil)
        return self.addChainHandler(routeChain, order: order, handler: handler)
    }
    
    public func addChainHandler(chain: RouteChain, handler: Handler) -> HandlerID
    {
        return self.addChainHandler(chain, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addChainHandler(chain: RouteChain, order: OrderType, handler: Handler) -> HandlerID
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: false)
    }
    
    // MARK: addChainErrorHandler
    
    public func addChainErrorHandler(chain: RouteChain, handler: Handler) -> HandlerID
    {
        return self.addChainErrorHandler(chain, order: self.dynamicType._defaultOrder, handler: handler)
    }
    
    public func addChainErrorHandler(chain: RouteChain, order: OrderType, handler: Handler) -> HandlerID
    {
        return self._addChainHandler(chain, order: order, handler: handler, isError: true)
    }
    
    private func _addChainHandler(chain: RouteChain, order: OrderType, handler: Handler, isError: Bool) -> HandlerID
    {
        var handlerIDs: [HandlerID] = Array()
        
        var shouldStop = true
        var shouldIncrementChainingCount = true
        var chainingCount = 0
        var allCount = 0
        
        // reset count on 1st route
        let firstRoute = chain.routes.first!
        var handlerID = self.addHandler(firstRoute.transition) { [weak self] context in
            if self == nil { return }
            let self_ = self!
            
            if self_._canPassCondition(firstRoute.condition, transition: context.transition) {
                if shouldStop {
                    shouldStop = false
                    chainingCount = 0
                    allCount = 0
//                    println("[RouteChain] start")
                }
                else {
//                    println("[RouteChain] back home a while")
                }
            }
        }
        handlerIDs.append(handlerID)
        
        // increment chainingCount on every route
        for route in chain.routes {
            handlerID = self.addHandler(route.transition) { [weak self] context in
                if self == nil { return }
                let self_ = self!
                
                // skip duplicated transition handlers e.g. chain = 0 => 1 => 0 => 1 & transiting 0 => 1
                if !shouldIncrementChainingCount { return }
                
                if self_._canPassCondition(route.condition, transition: context.transition) {
                    if !shouldStop {
                        chainingCount++
//                        println("[RouteChain] chainingCount++ =\(chainingCount), transition=\(route.transition)")
                        
                        shouldIncrementChainingCount = false
                    }
                }
            }
            handlerIDs.append(handlerID)
        }
        
        // increment allCount (+ invoke chainErrorHandler) on any routes
        handlerID = self.addHandler(nil => nil, order: 150) { [weak self] context in
            
            shouldIncrementChainingCount = true
            
            if !shouldStop {
                allCount++
//                println("[RouteChain] allCount++")
            }
            
            if chainingCount < allCount {
                shouldStop = true
                if isError {
                    handler(context: context)
                }
            }
        }
        handlerIDs.append(handlerID)
        
        // invoke chainHandler on last route
        let lastRoute = chain.routes.last!
        handlerID = self.addHandler(lastRoute.transition, order: 200) { [weak self] context in
//            println("[RouteChain] finish? \(chainingCount) \(allCount) \(chain.routes.count)")
            if self == nil { return }
            let self_ = self!
            
            if self_._canPassCondition(lastRoute.condition, transition: context.transition) {
                if chainingCount == allCount && chainingCount == chain.routes.count && chainingCount == chain.routes.count {
                    shouldStop = true
                    
                    if !isError {
                        handler(context: context)
                    }
                }
            }
        }
        handlerIDs.append(handlerID)
        
        let bundledHandlerID = HandlerID(bundledHandlerIDs: handlerIDs)
        
        return bundledHandlerID
    }
    
    //--------------------------------------------------
    // MARK: - RouteEvent
    //--------------------------------------------------
    
    public func addRouteEvent(event: Event, transitions: [Transition], condition: Condition? = nil) -> [RouteID]
    {
        var routes: [Route] = Array()
        for transition in transitions {
            let route = Route(transition: transition, condition: condition)
            routes.append(route)
        }
        
        return self.addRouteEvent(event, routes: routes)
    }
    
    public func addRouteEvent(event: Event, transitions: [Transition], condition: @autoclosure () -> Bool) -> [RouteID]
    {
        return self.addRouteEvent(event, transitions: transitions, condition: { t in condition() })
    }
    
    public func addRouteEvent(event: Event, routes: [Route]) -> [RouteID]
    {
        var routeIDs: [RouteID] = Array()
        for route in routes {
            let routeID = self._addRoute(route, forEvent: event)
            routeIDs.append(routeID)
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
    
    public func addEventHandler(event: Event, order: OrderType, handler: Handler) -> HandlerID
    {
        let transitions = self._routes[event]?.keys
        
        let handlerID = self.addHandler(nil => nil) { [weak self] context in
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

public func <- <S: StateType, E: StateEventType>(machine: StateMachine<S, E>, event: E) -> Bool
{
    return machine.tryEvent(event)
}

public func <- <S: StateType, E: StateEventType>(machine: StateMachine<S, E>, tuple: (E, Any?)) -> Bool
{
    return machine.tryEvent(tuple.0, userInfo: tuple.1)
}
