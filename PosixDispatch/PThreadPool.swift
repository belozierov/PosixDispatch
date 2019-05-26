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
        weak var pool: PThreadPool?
        threads = (0..<count).map { _ in
            PThread {
                guard let condition = pool?.condition else { return }
                condition.lock()
                condition.wait(while: pool?.runLoop() != nil)
                condition.signal()
                condition.unlock()
            }
        }
        pool = self
        threads.forEach { $0.start() }
    }
    
    @inlinable var threadCount: Int {
        return threads.count
    }
    
    // MARK: - RunLoop
    
    private func runLoop() {
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
    
    deinit {
        condition.broadcast()
    }
    
}
