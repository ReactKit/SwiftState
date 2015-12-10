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
        let event = Event<MyEvent>(rawValue: .Event0)
        XCTAssertTrue(event == .Event0)
        XCTAssertTrue(.Event0 == event)
    }
    
    func testInit_nil()
    {
        let event = Event<MyEvent>(rawValue: nil)
        XCTAssertTrue(event == .Any)
        XCTAssertTrue(.Any == event)
    }
    
    func testRawValue_event()
    {
        let event = Event<MyEvent>.Some(.Event0)
        XCTAssertTrue(event.rawValue == .Event0)
    }
    
    func testRawValue_any()
    {
        let event = Event<MyEvent>.Any
        XCTAssertTrue(event.rawValue == nil)
    }
}