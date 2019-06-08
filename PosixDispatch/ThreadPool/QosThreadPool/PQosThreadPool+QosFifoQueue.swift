//
//  PQosThreadPool+QosFifoQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/8/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

extension PQosThreadPool {
    
    class QosFifoQueue<T> {
        
        private typealias Queue = FifoQueue<T>
        private let queues = UnsafeMutablePointer<Queue>.allocate(capacity: 4)
        private var count = 0
        
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
        
        @discardableResult func pop() -> T? {
            if count == 0 { return nil }
            for i in 0..<4 {
                guard let item = queues[i].pop() else { continue }
                count -= 1
                return item
            }
            return nil
        }
        
        @inlinable var firstQos: Qos? {
            if count == 0 { return nil }
            for i in 0..<4 where queues[i].first != nil {
                return Qos(rawValue: i)
            }
            return nil
        }
        
        deinit {
            queues.deinitialize(count: 4)
            queues.deallocate()
        }
        
    }
    
}
