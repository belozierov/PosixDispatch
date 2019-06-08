//
//  PThreadPool.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 6/8/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PThreadPool {
    
    typealias Block = PThread.Block
    typealias Performer = (@escaping Block) -> Void
    
    let threadNumber: Int
    private let condition = PCondition()
    private let queue = FifoQueue<Block>()
    private let runLoops: UnsafeMutablePointer<PRunLoop>
    
    init(threadNumber: Int, perform: Performer? = nil) {
        self.threadNumber = threadNumber
        runLoops = .allocate(capacity: threadNumber)
        let perform = perform ?? { PThread(block: $0).start() }
        for i in 0..<threadNumber {
            let runLoop = PRunLoop(condition: condition, iterator: queue.pop)
            (runLoops + i).initialize(to: runLoop)
            perform(runLoop.start)
        }
    }
    
    func subPool(threadNumber: Int) -> PThreadPool {
        return .init(threadNumber: threadNumber, perform: perform)
    }
    
    func perform(block: @escaping Block) {
        condition.lock()
        queue.push(block)
        condition.signal()
        condition.unlock()
    }
    
    func perform(blocks: [Block]) {
        condition.lock()
        queue.push(blocks)
        condition.broadcast()
        condition.unlock()
    }
    
    deinit {
        (0..<threadNumber).forEach { runLoops[$0].cancel() }
        runLoops.deinitialize(count: threadNumber)
        runLoops.deallocate()
    }
    
}
