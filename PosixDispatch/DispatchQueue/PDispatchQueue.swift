//
//  DispatchQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchQueue: PDispatchQueueBackend {
    
    struct Attributes: OptionSet {
        static let concurrent   = Attributes(rawValue: 1 << 0)
        let rawValue: Int
    }
    
    struct DispatchItemFlags: OptionSet {
        static let barrier      = DispatchItemFlags(rawValue: 1 << 0)
        static let enforceQoS   = DispatchItemFlags(rawValue: 1 << 1)
        let rawValue: Int
    }
    
    static let global = PDispatchQueue(label: "com.global", attributes: .concurrent)
    
    let label: String
    private let backend: PDispatchQueueBackend
    
    init(label: String, attributes: Attributes = []) {
        self.label = label
        backend = attributes.contains(.concurrent)
            ? PDispatchConcurrentQueue(threadPool: .global)
            : PDispatchSerialQueue()
    }
    
    @discardableResult @inlinable
    func sync<T>(execute work: () throws -> T) rethrows -> T {
        return try backend.sync(execute: work)
    }
    
    @discardableResult @inlinable
    func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T {
        return try backend.sync(flags: flags, execute: work)
    }
    
    @inlinable func async(execute work: @escaping Block) {
        backend.async(execute: work)
    }
    
    @inlinable func async(group: PDispatchGroup? = nil, flags: DispatchItemFlags = [], execute work: @escaping Block) {
        backend.async(group: group, flags: flags, execute: work)
    }
    
    // MARK: - Concurrent Perform
    
    static func concurrentPerform(iterations: Int, execute work: @escaping (Int) -> Void) {
        let group = PDispatchGroup(count: iterations)
        PThreadPool(count: Sysconf.processorsNumber)
            .perform(blocks: (0..<iterations).map { i in { work(i); group.leave() } })
        group.wait()
    }
    
}
