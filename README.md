SwiftState
==========

Elegant state machine for Swift.

![SwiftState](Screenshots/logo.png)

## Example

```
enum MyState: StateType {
    case State0, State1, State2
    case AnyState   // create case=Any

    static func convertFromNilLiteral() -> MyState { return AnyState }
}
```

```
let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in

    machine.addRoute(.State0 => .State1)
    machine.addRoute(nil => .State2) { context in println("Any => 2, msg=\(context.userInfo!)") }
    machine.addRoute(.State2 => nil) { context in println("2 => Any, msg=\(context.userInfo!)") }

    // add handler (handlerContext = (event, transition, order, userInfo))
    machine.addHandler(.State0 => .State1) { context in
        println("0 => 1")
    }

    // add errorHandler
    machine.addErrorHandler { (event, transition, order, userInfo) in
        println("[ERROR] \(transition.fromState) => \(transition.toState)")
    }
}

// tryState 0 => 1 => 2 => 1 => 0
machine <- .State1
machine <- (.State2, "Hello")
machine <- (.State1, "Bye")
machine <- .State0  // fail: no 1 => 0

println("machine.state = \(machine.state)")
```

This will print:

```
0 => 1
Any => 2, msg=Hello
2 => Any, msg=Bye
[ERROR] 1 => 0
machine.state = 1
```

For more examples, please see XCTest cases.


## Features

- Easy Swift syntax
    - Transition: `.State0 => .State1`
    - Try transition: `machine <- .State1`
    - Try transition + messaging: `machine <- (.State1, "GoGoGo")`
- Highly flexible transition routing
    - using Condition
    - using AnyState (`nil` state)
    - or both (blacklisting): `nil => nil` + condition
- Success/Error/Entry/Exit handlers with `order: UInt8` (no before/after handler stuff)
- Removable routes and handlers
- Chaining: `.State0 => .State1 => .State2`
- Event: `machine.addRouteEvent("WakeUp", transitions); machine <- "WakeUp"`


## Terms

Term      | Class                         | Description
--------- | ----------------------------- | ------------------------------------------
State     | `StateType` (protocol)        | Mostly enum, describing each state e.g. `.State0`.
Event     | `StateEventType` (protocol)   | Name for route-group. Transition can be fired via `Event` instead of explicitly targeting next `State`.
Machine   | `StateMachine`                | State transition manager which can register `Route` and `Handler` separately for variety of transitions.
Transition   | `StateTransition`          | `From-` and `to-` states represented as `.State1 => .State2`. If `nil` is used for either state, it will be represented as `.AnyState`.
Route     | `StateRoute`                  | `Transition` + `Condition`.
Condition | `(Transition, Event) -> Bool` | Closure for validating transition. If condition returns `false`, transition will fail and associated handlers will not be invoked.
Handler   | `HandlerContext -> Void`      | Transition callback invoked after state has been changed.
Chain     | `StateTransitionChain`        | Group of continuous routes represented as `.State1 => .State2 => .State3`




## Licence

[MIT](https://github.com/inamiy/SwiftState/blob/master/LICENSE)
