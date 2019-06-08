//
//  PQosThreadPool+RunLoopData.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/8/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

extension PQosThreadPool {
    
    class RunLoopData {
        
        private let poolData: PoolData
        private var isRunning = false
        private var lastQos = Qos.utility
        
        init(poolData: PoolData) {
            self.poolData = poolData
        }
        
        func next() -> Block? {
            guard let qos = poolData.queue.firstQos else {
                cancelPerfom()
                return nil
            }
            return perfromNext(qos: qos) ? poolData.queue.pop() : nil
        }
        
        private func perfromNext(qos: Qos) -> Bool {
            if qos == lastQos {
                startPerfom(qos: qos)
                return true
            }
            cancelPerfom()
            if !poolData.canPerform(qos: qos) { return false }
            startPerfom(qos: qos)
            lastQos = qos
            return true
        }
        
        private func startPerfom(qos: Qos) {
            if isRunning { return }
            poolData.startPerforming(qos: qos)
            isRunning = true
        }
        
        private func cancelPerfom() {
            guard isRunning else { return }
            poolData.endPerforming(qos: lastQos)
            isRunning = false
        }
        
    }
    
}
