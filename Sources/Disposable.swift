//
//  Disposable.swift
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2014-06-02.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

//
// NOTE:
// This file is a partial copy from ReactiveCocoa v4.0.0-alpha.4 (removing `Atomic` dependency),
// which has not been taken out as microframework.
// https://github.com/ReactiveCocoa/ReactiveCocoa/issues/2579
//
// Note that `ActionDisposable` also works as `() -> ()` wrapper to help suppressing warning:
// "Expression resolved to unused function", when returned function was not used.
//

/// Represents something that can be “disposed,” usually associated with freeing
/// resources or canceling work.
public protocol Disposable {
    /// Whether this disposable has been disposed already.
    var disposed: Bool { get }

    func dispose()
}

/// A disposable that will run an action upon disposal.
public final class ActionDisposable: Disposable {
    private var action: (() -> ())?

    public var disposed: Bool {
        return action == nil
    }

    /// Initializes the disposable to run the given action upon disposal.
    public init(action: @escaping (() -> ())) {
        self.action = action
    }

    public func dispose() {
        self.action?()
        self.action = nil
    }
}
