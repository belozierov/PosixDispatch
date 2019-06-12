//
//  PQosThreadPool+RunLoopData.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/8/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

extension PQosThreadPool {
    
    class RunLoopState {
        
        private let poolState: PoolState
        private var isRunning = false
        private var lastQos = Qos.utility
        
        init(poolState: PoolState) {
            self.poolState = poolState
        }
        
        func next() -> Block? {
            guard let qos = poolState.queue.firstQos else {
                cancelPerfom()
                return nil
            }
            return perfromNext(qos: qos) ? poolState.queue.pop(qos: qos) : nil
        }
        
        private func perfromNext(qos: Qos) -> Bool {
            if qos == lastQos {
                startPerfom(qos: qos)
                return true
            }
            cancelPerfom()
            if !poolState.canPerform(qos: qos) { return false }
            startPerfom(qos: qos)
            lastQos = qos
            return true
        }
        
        private func startPerfom(qos: Qos) {
            if isRunning { return }
            poolState.startPerforming(qos: qos)
            isRunning = true
        }
        
        private func cancelPerfom() {
            guard isRunning else { return }
            poolState.endPerforming(qos: lastQos)
            isRunning = false
        }
        
    }
    
}
