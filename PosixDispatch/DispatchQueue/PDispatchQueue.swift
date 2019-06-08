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
    
    let label: String
    private let backend: PDispatchQueueBackend
    var qos: DispatchQoS { return backend.qos }
    
    init(label: String = "", qos: DispatchQoS = .utility, attributes: Attributes = []) {
        self.label = label
        backend = attributes.contains(.concurrent)
            ? PDispatchConcurrentQueue(threadPool: .global, qos: qos)
            : PDispatchSerialQueue()
    }
    
    // MARK: - PDispatchQueueBackend
    
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
    
    // MARK: - Global queues
    
    private static let queues = DispatchQoS.allCases
        .map { PDispatchQueue(label: "com.global\($0.rawValue)", qos: $0, attributes: .concurrent) }
    
    static func global(qos: DispatchQoS = .utility) -> PDispatchQueue {
        return queues[qos.rawValue]
    }
    
    // MARK: - Concurrent Perform
    
    static func concurrentPerform(iterations: Int, execute work: @escaping (Int) -> Void) {
        let group = PDispatchGroup(count: iterations)
        PThreadPool(threadNumber: Sysconf.processorsNumber)
            .perform(blocks: (0..<iterations).map { i in { work(i); group.leave() } })
        group.wait()
    }
    
}
