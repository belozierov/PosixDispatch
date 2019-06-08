//
//  PQosThreadPool+PoolData.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/8/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

extension PQosThreadPool {
    
    class PoolData {
        
        let threadNumber: Int, queue = QosFifoQueue<Block>()
        private let perfroming = UnsafeMutablePointer<Int>.allocate(capacity: 4)
        
        init(threadNumber: Int) {
            self.threadNumber = threadNumber
            perfroming.assign(repeating: 0, count: 4)
        }
        
        func canPerform(qos: Qos) -> Bool {
            let max = Int(qos.maxThreads * Float(threadNumber))
            var sum = 0
            for i in 0...qos.performingIndex {
                sum += perfroming[i]
                if sum >= max { return false }
            }
            return true
        }
        
        @inlinable func startPerforming(qos: Qos) {
            perfroming[qos.performingIndex] += 1
        }
        
        @inlinable func endPerforming(qos: Qos) {
            perfroming[qos.performingIndex] -= 1
        }
        
        deinit {
            perfroming.deallocate()
        }
        
    }
    
}

extension PQosThreadPool.Qos {
    
    fileprivate var performingIndex: Int {
        return 3 - rawValue
    }
    
    var maxThreads: Float {
        switch self {
        case .userInteractive: return 1
        case .userInitiated: return 0.75
        case .utility: return 0.5
        case .background: return 0.25
        }
    }
    
}
