//
//  PQosThreadPool.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/3/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PQosThreadPool {
    
    enum Qos: Int, CaseIterable {
        case userInteractive, userInitiated, utility, background
    }
    
    typealias Block = PThread.Block
    typealias Performer = (@escaping Block) -> Void
    
    static let global = PQosThreadPool(threadNumber: 64)
    
    private let condition = PCondition()
    private let state: PoolState
    private let runLoops: UnsafeMutablePointer<PRunLoop>
    var threadNumber: Int { return state.threadNumber }
    
    init(threadNumber: Int, perform: Performer? = nil) {
        state = PoolState(threadNumber: threadNumber)
        runLoops = .allocate(capacity: threadNumber)
        let perform = perform ?? { PThread(block: $0).start() }
        for i in 0..<threadNumber {
            let runLoop = newRunLoop
            (runLoops + i).initialize(to: runLoop)
            perform(runLoop.start)
        }
    }
    
    private var newRunLoop: PRunLoop {
        let loopState = RunLoopState(poolState: state)
        return PRunLoop(condition: condition) { loopState.next() }
    }
    
    func perform(qos: Qos = .utility, block: @escaping Block) {
        condition.lock()
        state.queue.push(block, qos: qos)
        if state.canPerform(qos: qos) { condition.signal() }
        condition.unlock()
    }
    
    func perform(qos: Qos = .utility, blocks: [Block]) {
        condition.lock()
        state.queue.push(blocks, qos: qos)
        if state.canPerform(qos: qos) { condition.broadcast() }
        condition.unlock()
    }
    
    func subPool(threadNumber: Int, qos: Qos = .utility) -> PThreadPool {
        return .init(threadNumber: threadNumber) { self.perform(qos: qos, block: $0) }
    }
    
    deinit {
        (0..<threadNumber).forEach { runLoops[$0].cancel() }
        runLoops.deinitialize(count: threadNumber)
        runLoops.deallocate()
        condition.broadcast()
    }
    
}
