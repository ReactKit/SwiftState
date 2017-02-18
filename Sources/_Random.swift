//
//  _Random.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#else
import Glibc
#endif

internal func _random(_ upperBound: Int) -> Int
{
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    return Int(arc4random_uniform(UInt32(upperBound)))
    #else
    return Int(random() % upperBound)
    #endif
}
