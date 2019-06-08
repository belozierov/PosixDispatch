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
    private let poolData: PoolData
    private let runLoops: UnsafeMutablePointer<PRunLoop>
    var threadNumber: Int { return poolData.threadNumber }
    
    init(threadNumber: Int, perform: Performer? = nil) {
        poolData = PoolData(threadNumber: threadNumber)
        runLoops = .allocate(capacity: threadNumber)
        let perform = perform ?? { PThread(block: $0).start() }
        for i in 0..<threadNumber {
            let runLoop = newRunLoop
            (runLoops + i).initialize(to: runLoop)
            perform(runLoop.start)
        }
    }
    
    private var newRunLoop: PRunLoop {
        let data = RunLoopData(poolData: poolData)
        return PRunLoop(condition: condition) { data.next() }
    }
    
    func perform(block: @escaping Block, qos: Qos = .utility) {
        condition.lock()
        poolData.queue.push(block, qos: qos)
        if poolData.canPerform(qos: qos) { condition.signal() }
        condition.unlock()
    }
    
    func perform(blocks: [Block], qos: Qos = .utility) {
        condition.lock()
        poolData.queue.push(blocks, qos: qos)
        if poolData.canPerform(qos: qos) { condition.broadcast() }
        condition.unlock()
    }
    
    func subPool(threadNumber: Int, qos: Qos = .utility) -> PThreadPool {
        return .init(threadNumber: threadNumber) { self.perform(block: $0, qos: qos) }
    }
    
    deinit {
        (0..<threadNumber).forEach { runLoops[$0].cancel() }
        runLoops.deinitialize(count: threadNumber)
        runLoops.deallocate()
        condition.broadcast()
    }
    
}
