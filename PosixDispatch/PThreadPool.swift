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
    
    private let threads: [PThread], condition = PCondition()
    private var queue = FifoQueue<Block>()
    
    init(count: Int) {
        let group = PDispatchGroup(count: count)
        weak var pool: PThreadPool?
        threads = (0..<count).map { _ in
            PThread {
                group.leave()
                pool?.condition.lock()
                while let condition = pool?.condition {
                    condition.wait()
                    pool?.runloop()
                }
            }
        }
        pool = self
        threads.forEach { $0.start() }
        group.wait()
    }
    
    @inlinable var threadCount: Int {
        return threads.count
    }
    
    // MARK: - RunLoop
    
    private func runloop() {
        while let block = queue.pop() {
            condition.unlock()
            block()
            condition.lock()
        }
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
    
}
