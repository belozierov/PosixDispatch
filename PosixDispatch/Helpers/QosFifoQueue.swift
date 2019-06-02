//
//  QosFifoQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/2/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class QosFifoQueue<T> {
    
    typealias Queue = FifoQueue<T>
    
    enum Qos: Int, CaseIterable {
        case userInteractive, userInitiated, utility, background
    }
    
    private let queues = UnsafeMutablePointer<Queue>.allocate(capacity: 4)
    private(set) var count = 0
    
    init() {
        let queues = (0..<4).map { _ in Queue() }
        self.queues.initialize(from: queues, count: 4)
    }
    
    @inlinable func push(_ item: T, qos: Qos) {
        count += 1
        queues[qos.rawValue].push(item)
    }
    
    @inlinable func push(_ items: [T], qos: Qos) {
        count += items.count
        queues[qos.rawValue].push(items)
    }
    
    @inlinable func insertInStart(_ item: T, qos: Qos) {
        count += 1
        queues[qos.rawValue].insertInStart(item)
    }
    
    @discardableResult func pop() -> T? {
        if isEmpty { return nil }
        for i in 0..<4 {
            guard let item = queues[i].pop() else { continue }
            count -= 1
            return item
        }
        return nil
    }
    
    @inlinable var isEmpty: Bool {
        return count == 0
    }
    
    @inlinable var first: T? {
        if isEmpty { return nil }
        for i in 0..<4 {
            if let first = queues[i].first { return first }
        }
        return nil
    }
    
    @inlinable var last: T? {
        if isEmpty { return nil }
        for i in 0..<4 {
            if let last = queues[i].last { return last }
        }
        return nil
    }
    
    @inlinable var popIterator: AnyIterator<T> {
        return AnyIterator { self.pop() }
    }
    
    deinit {
        queues.deinitialize(count: 4)
        queues.deallocate()
    }
    
}
