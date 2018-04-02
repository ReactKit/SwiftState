//
//  EventTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-08.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class EventTests: _TestCase
{
    func testInit_event()
    {
        let event = Event<MyEvent>(rawValue: .event0)
        XCTAssertTrue(event == .event0)
        XCTAssertTrue(.event0 == event)
    }

    func testInit_nil()
    {
        let event = Event<MyEvent>(rawValue: nil)
        XCTAssertTrue(event == .any)
        XCTAssertTrue(.any == event)
    }

    func testRawValue_event()
    {
        let event = Event<MyEvent>.some(.event0)
        XCTAssertTrue(event.rawValue == .event0)
    }

    func testRawValue_any()
    {
        let event = Event<MyEvent>.any
        XCTAssertTrue(event.rawValue == nil)
    }
}
