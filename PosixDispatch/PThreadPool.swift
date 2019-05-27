//
//  PThreadPool.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/24/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PThreadPool {
    
    typealias Block = PThread.Block
    static let global = PThreadPool(count: 64)
    
    private let condition = PCondition()
    private let queue = FifoQueue<Block>()
    private var threads = [PThread]()
    var threadCount: Int { return threads.count }
    
    init(count: Int) {
        let group = PDispatchGroup(count: count)
        let runLoop = RunLoop(condition: condition, iterator: queue.popIterator)
        let block = { [weak self] in group.leave(); runLoop.run(while: self != nil) }
        condition.lock()
        threads = (0..<count).map { _ in PThread(block: block) }
        threads.forEach { $0.start() }
        group.wait()
    }
    
    // MARK: - Perfrom Block
    
    func perform(blocks: [Block]) {
        condition.lock()
        queue.push(blocks)
        condition.broadcast()
        condition.unlock()
    }
    
    func perform(block: @escaping Block) {
        condition.lock()
        if queue.isEmpty {
            queue.push(block)
            condition.signal()
        } else {
            queue.push(block)
        }
        condition.unlock()
    }
    
    deinit {
        condition.broadcast()
    }
    
}
