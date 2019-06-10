//
//  PQosThreadPool+PoolData.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/8/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

extension PQosThreadPool {
    
    class PoolState {
        
        let threadNumber: Int, queue = QosFifoQueue<Block>()
        private let performing = UnsafeMutablePointer<Int>.allocate(capacity: 4)
        private let maxThreads: UnsafePointer<Int>
        private var freeThreads: Int
        
        init(threadNumber: Int) {
            self.threadNumber = threadNumber
            freeThreads = threadNumber
            performing.assign(repeating: 0, count: 4)
            let max = Qos.allCases.map { Int($0.maxThreads * Float(threadNumber)) }
            let maxThreads = UnsafeMutablePointer<Int>.allocate(capacity: 4)
            maxThreads.initialize(from: max, count: 4)
            self.maxThreads = .init(maxThreads)
        }
        
        func canPerform(qos: Qos) -> Bool {
            if freeThreads == 0 { return false }
            let max = maxThreads[qos.rawValue]
            var sum = 0
            for i in (0...qos.rawValue).reversed() {
                sum += performing[i]
                if sum >= max { return false }
            }
            return true
        }
        
        @inlinable func startPerforming(qos: Qos) {
            freeThreads -= 1
            performing[qos.rawValue] += 1
        }
        
        @inlinable func endPerforming(qos: Qos) {
            freeThreads += 1
            performing[qos.rawValue] -= 1
        }
        
        deinit {
            performing.deallocate()
            maxThreads.deallocate()
        }
        
    }
    
}

extension PQosThreadPool.Qos {
    
    var maxThreads: Float {
        switch self {
        case .userInteractive: return 1
        case .userInitiated: return 0.75
        case .utility: return 0.5
        case .background: return 0.25
        }
    }
    
}
