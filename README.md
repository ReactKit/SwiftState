SwiftState [![Circle CI](https://circleci.com/gh/ReactKit/SwiftState/tree/swift%2F2.0.svg?style=svg)](https://circleci.com/gh/ReactKit/SwiftState/tree/swift%2F2.0)
==========

Elegant state machine for Swift.

![SwiftState](Screenshots/logo.png)


## Example

```swift
enum MyState: StateType {
    case State0, State1, State2
}
```

```swift
// setup state machine
let machine = Machine<MyState, NoEvent>(state: .State0) { machine in

    machine.addRoute(.State0 => .State1)
    machine.addRoute(.Any => .State2) { context in print("Any => 2, msg=\(context.userInfo)") }
    machine.addRoute(.State2 => .Any) { context in print("2 => Any, msg=\(context.userInfo)") }

    // add handler (`context = (event, fromState, toState, userInfo)`)
    machine.addHandler(.State0 => .State1) { context in
        print("0 => 1")
    }

    // add errorHandler
    machine.addErrorHandler { event, fromState, toState, userInfo in
        print("[ERROR] \(transition.fromState) => \(transition.toState)")
    }
}

// initial
XCTAssertTrue(machine.state == .State0)
        
// tryState 0 => 1 => 2 => 1 => 0

machine <- .State1
XCTAssertTrue(machine.state == .State1)
        
machine <- (.State2, "Hello")
XCTAssertTrue(machine.state == .State2)
        
machine <- (.State1, "Bye")
XCTAssertTrue(machine.state == .State1)
        
machine <- .State0  // fail: no 1 => 0
XCTAssertTrue(machine.state == .State1)
```

This will print:

```swift
0 => 1
Any => 2, msg=Optional("Hello")
2 => Any, msg=Optional("Bye")
[ERROR] State1 => State0
```

### Transition by Event

Use `<-!` operator to try transition by `Event` rather than specifying target `State` ([Test Case](https://github.com/ReactKit/SwiftState/blob/1be67826b3cc9187dfaac85c2e70613f3129fad6/SwiftStateTests/TryEventTests.swift#L32-L54)).

```swift
enum MyEvent: EventType {
    case Event0, Event1
}
```

```swift
let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
        
    // add 0 => 1 => 2
    machine.addRouteEvent(.Event0, transitions: [
        .State0 => .State1,
        .State1 => .State2,
    ])
}
   
// tryEvent
machine <-! .Event0
XCTAssertEqual(machine.state, MyState.State1)

// tryEvent
machine <-! .Event0
XCTAssertEqual(machine.state, MyState.State2)

// tryEvent
let success = machine <-! .Event0
XCTAssertEqual(machine.state, MyState.State2)
XCTAssertFalse(success, "Event0 doesn't have 2 => Any")
```

If there is no `Event`-based transition, use built-in `NoEvent` instead.

For more examples, please see XCTest cases.


## Features

- Easy Swift syntax
    - Transition: `.State0 => .State1`, `[.State0, .State1] => .State2`
    - Try transition: `machine <- .State1`
    - Try transition + messaging: `machine <- (.State1, "GoGoGo")`
    - Try event: `machine <-! .Event1`
- Highly flexible transition routing
    - Using `Condition`
    - Using `.Any` state/event
    - Blacklisting: `.Any => .Any` + `Condition`
    - Route Mapping (closure-based routing): [#36](https://github.com/ReactKit/SwiftState/pull/36)
- Success/Error/Entry/Exit handlers with `order: UInt8` (more flexible than before/after handlers)
- Removable routes and handlers
- Chaining: `.State0 => .State1 => .State2`
- Hierarchical State Machine: [#10](https://github.com/ReactKit/SwiftState/pull/10)

## Terms

Term          | Type                          | Description
------------- | ----------------------------- | ------------------------------------------
State         | `StateType` (protocol)        | Mostly enum, describing each state e.g. `.State0`.
Event         | `EventType` (protocol)        | Name for route-group. Transition can be fired via `Event` instead of explicitly targeting next `State`.
State Machine | `Machine`                     | State transition manager which can register `Route`/`RouteMapping` and `Handler` separately for variety of transitions.
Transition    | `Transition`                  | `From-` and `to-` states represented as `.State1 => .State2`. Also, `.Any` can be used to represent _any state_.
Route         | `Route`                       | `Transition` + `Condition`.
Condition     | `Context -> Bool`             | Closure for validating transition. If condition returns `false`, transition will fail and associated handlers will not be invoked.
Route Mapping | `(event: E?, fromState: S, userInfo: Any?) -> S?`                | Another way of defining routes **using closure instead of transition arrows (`=>`)**. This is useful when state & event are enum with associated values. Return value (`S?`) means "preferred-toState", where passing `nil` means no routes available. See [#36](https://github.com/ReactKit/SwiftState/pull/36) for more info.
Handler       | `Context -> Void`             | Transition callback invoked after state has been changed.
Context       | `(event: E?, fromState: S, toState: S, userInfo: Any?)` | Closure argument for `Condition` & `Handler`.
Chain         | `TransitionChain` / `RouteChain` | Group of continuous routes represented as `.State1 => .State2 => .State3`


## Related Articles

1. [Swiftで有限オートマトン(ステートマシン)を作る - Qiita](http://qiita.com/inamiy/items/cd218144c90926f9a134) (Japanese)
2. [Swift+有限オートマトンでPromiseを拡張する - Qiita](http://qiita.com/inamiy/items/d3579b55a3ecc28dde63) (Japanese)


## Licence

[MIT](https://github.com/ReactKit/SwiftState/blob/master/LICENSE)
