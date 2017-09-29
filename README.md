SwiftState
==========

Elegant state machine for Swift.

![SwiftState](Screenshots/logo.png)


## Example

```swift
enum MyState: StateType {
    case state0, state1, state2
}
```

```swift
// setup state machine
let machine = StateMachine<MyState, NoEvent>(state: .state0) { machine in
    
    machine.addRoute(.state0 => .state1)
    machine.addRoute(.any => .state2) { context in print("Any => 2, msg=\(context.userInfo)") }
    machine.addRoute(.state2 => .any) { context in print("2 => Any, msg=\(context.userInfo)") }
    
    // add handler (`context = (event, fromState, toState, userInfo)`)
    machine.addHandler(.state0 => .state1) { context in
        print("0 => 1")
    }
    
    // add errorHandler
    machine.addErrorHandler { event, fromState, toState, userInfo in
        print("[ERROR] \(fromState) => \(toState)")
    }
}

// initial
XCTAssertEqual(machine.state, MyState.state0)

// tryState 0 => 1 => 2 => 1 => 0

machine <- .state1
XCTAssertEqual(machine.state, MyState.state1)

machine <- (.state2, "Hello")
XCTAssertEqual(machine.state, MyState.state2)

machine <- (.state1, "Bye")
XCTAssertEqual(machine.state, MyState.state1)

machine <- .state0  // fail: no 1 => 0
XCTAssertEqual(machine.state, MyState.state1)
```

This will print:

```swift
0 => 1
Any => 2, msg=Optional("Hello")
2 => Any, msg=Optional("Bye")
[ERROR] state1 => state0
```

### Transition by Event

Use `<-!` operator to try transition by `Event` rather than specifying target `State`.

```swift
enum MyEvent: EventType {
    case event0, event1
}
```

```swift
let machine = StateMachine<MyState, MyEvent>(state: .state0) { machine in
    
    // add 0 => 1 => 2
    machine.addRoutes(event: .event0, transitions: [
        .state0 => .state1,
        .state1 => .state2,
    ])
    
    // add event handler
    machine.addHandler(event: .event0) { context in
        print(".event0 triggered!")
    }
}

// initial
XCTAssertEqual(machine.state, MyState.state0)

// tryEvent
machine <-! .event0
XCTAssertEqual(machine.state, MyState.state1)

// tryEvent
machine <-! .event0
XCTAssertEqual(machine.state, MyState.state2)

// tryEvent (fails)
machine <-! .event0
XCTAssertEqual(machine.state, MyState.state2, "event0 doesn't have 2 => Any")
```

If there is no `Event`-based transition, use built-in `NoEvent` instead.

### State & Event enums with associated values

Above examples use _arrow-style routing_ which are easy to understand, but it lacks in ability to handle **state & event enums with associated values**. In such cases, use either of the following functions to apply _closure-style routing_:

- `machine.addRouteMapping(routeMapping)`
    - `RouteMapping`: `(_ event: E?, _ fromState: S, _ userInfo: Any?) -> S?`
- `machine.addStateRouteMapping(stateRouteMapping)`
    - `StateRouteMapping`: `(_ fromState: S, _ userInfo: Any?) -> [S]?`

For example:

```swift
enum StrState: StateType {
    case str(String) ...
}
enum StrEvent: EventType {
    case str(String) ...
}

let machine = Machine<StrState, StrEvent>(state: .str("initial")) { machine in
    
    machine.addRouteMapping { event, fromState, userInfo -> StrState? in
        // no route for no-event
        guard let event = event else { return nil }
        
        switch (event, fromState) {
            case (.str("gogogo"), .str("initial")):
                return .str("Phase 1")
            case (.str("gogogo"), .str("Phase 1")):
                return .str("Phase 2")
            case (.str("finish"), .str("Phase 2")):
                return .str("end")
            default:
                return nil
        }
    }
    
}

// initial
XCTAssertEqual(machine.state, StrState.str("initial"))

// tryEvent (fails)
machine <-! .str("go?")
XCTAssertEqual(machine.state, StrState.str("initial"), "No change.")

// tryEvent
machine <-! .str("gogogo")
XCTAssertEqual(machine.state, StrState.str("Phase 1"))

// tryEvent (fails)
machine <-! .str("finish")
XCTAssertEqual(machine.state, StrState.str("Phase 1"), "No change.")

// tryEvent
machine <-! .str("gogogo")
XCTAssertEqual(machine.state, StrState.str("Phase 2"))

// tryEvent (fails)
machine <-! .str("gogogo")
XCTAssertEqual(machine.state, StrState.str("Phase 2"), "No change.")

// tryEvent
machine <-! .str("finish")
XCTAssertEqual(machine.state, StrState.str("end"))
```

This behaves very similar to JavaScript's safe state-container [rackt/Redux](https://github.com/rackt/redux), where `RouteMapping` can be interpretted as `Redux.Reducer`.

For more examples, please see XCTest cases.


## Features

- Easy Swift syntax
    - Transition: `.state0 => .state1`, `[.state0, .state1] => .state2`
    - Try state: `machine <- .state1`
    - Try state + messaging: `machine <- (.state1, "GoGoGo")`
    - Try event: `machine <-! .event1`
- Highly flexible transition routing
    - Using `Condition`
    - Using `.any` state
        - Entry handling: `.any => .someState`
        - Exit handling: `.someState => .any`
        - Blacklisting: `.any => .any` + `Condition`
    - Using `.any` event
    
    - Route Mapping (closure-based routing): [#36](https://github.com/ReactKit/SwiftState/pull/36)
- Success/Error handlers with `order: UInt8` (more flexible than before/after handlers)
- Removable routes and handlers using `Disposable`
- Route Chaining: `.state0 => .state1 => .state2`
- Hierarchical State Machine: [#10](https://github.com/ReactKit/SwiftState/pull/10)


## Terms

Term          | Type                          | Description
------------- | ----------------------------- | ------------------------------------------
State         | `StateType` (protocol)        | Mostly enum, describing each state e.g. `.state0`.
Event         | `EventType` (protocol)        | Name for route-group. Transition can be fired via `Event` instead of explicitly targeting next `State`.
State Machine | `Machine`                     | State transition manager which can register `Route`/`RouteMapping` and `Handler` separately for variety of transitions.
Transition    | `Transition`                  | `From-` and `to-` states represented as `.state1 => .state2`. Also, `.any` can be used to represent _any state_.
Route         | `Route`                       | `Transition` + `Condition`.
Condition     | `Context -> Bool`             | Closure for validating transition. If condition returns `false`, transition will fail and associated handlers will not be invoked.
Route Mapping | `(event: E?, fromState: S, userInfo: Any?) -> S?`                | Another way of defining routes **using closure instead of transition arrows (`=>`)**. This is useful when state & event are enum with associated values. Return value (`S?`) means preferred-`toState`, where passing `nil` means no routes available. See [#36](https://github.com/ReactKit/SwiftState/pull/36) for more info.
State Route Mapping | `(fromState: S, userInfo: Any?) -> [S]?`                | Another way of defining routes **using closure instead of transition arrows (`=>`)**. This is useful when state is enum with associated values. Return value (`[S]?`) means multiple `toState`s from single `fromState` (synonym for multiple routing e.g. `.state0 => [.state1, .state2]`). See [#36](https://github.com/ReactKit/SwiftState/pull/36) for more info.
Handler       | `Context -> Void`             | Transition callback invoked when state has been changed successfully.
Context       | `(event: E?, fromState: S, toState: S, userInfo: Any?)` | Closure argument for `Condition` & `Handler`.
Chain         | `TransitionChain` / `RouteChain` | Group of continuous routes represented as `.state1 => .state2 => .state3`


## Related Articles

1. [Swiftで有限オートマトン(ステートマシン)を作る - Qiita](http://qiita.com/inamiy/items/cd218144c90926f9a134) (Japanese)
2. [Swift+有限オートマトンでPromiseを拡張する - Qiita](http://qiita.com/inamiy/items/d3579b55a3ecc28dde63) (Japanese)


## Licence

[MIT](LICENSE)
