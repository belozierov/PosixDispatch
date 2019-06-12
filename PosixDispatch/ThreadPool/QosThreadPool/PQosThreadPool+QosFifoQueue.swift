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
        
        init() {
            let queues = (0..<4).map { _ in Queue() }
            self.queues.initialize(from: queues, count: 4)
        }
        
        @inlinable func push(_ item: T, qos: Qos) {
            queues[qos.rawValue].push(item)
        }
        
        @inlinable func push(_ items: [T], qos: Qos) {
            queues[qos.rawValue].push(items)
        }
        
        @inlinable func pop(qos: Qos) -> T? {
            return queues[qos.rawValue].pop()
        }
        
        var firstQos: Qos? {
            return (0..<4).first { !queues[$0].isEmpty }.flatMap(Qos.init)
        }
        
        deinit {
            queues.deinitialize(count: 4)
            queues.deallocate()
        }
        
    }
    
}
