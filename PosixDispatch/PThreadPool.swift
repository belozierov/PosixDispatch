//
//  PThreadPool.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/24/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PThreadPool {
    
    typealias Block = () -> Void
    
    static let global = PThreadPool(count: 64)
    private let threads: [PThread], condition = PCondition()
    private var queue = FifoQueue<Block>()
    private var perform = true
    
    init(count: Int) {
        unowned var pool: PThreadPool!
        var started = 0
        threads = (0..<count).map { _ in PThread { pool.threadBlock(started: &started) } }
        pool = self
        threads.forEach { $0.start() }
        waitStart(started: started)
    }
    
    private func waitStart(started: @autoclosure () -> Int) {
        condition.lockedPerform { condition.wait(while: started() != threads.count) }
    }
    
    @inlinable var threadCount: Int {
        return threads.count
    }
    
    // MARK: - RunLoop
    
    private func threadBlock(started: inout Int) {
        condition.lock()
        started += 1
        condition.broadcast()
        condition.wait(while: started != threads.count)
        runloop()
    }
    
    private func runloop() {
        while perform {
            condition.wait()
            while let block = queue.pop() {
                condition.unlock()
                block()
                condition.lock()
            }
        }
        condition.unlock()
    }
    
    // MARK: - Perfrom Block
    
    func async(blocks: [Block]) {
        condition.lock()
        queue.push(blocks)
        condition.broadcast()
        condition.unlock()
    }
    
    func async(block: @escaping Block) {
        condition.lock()
        if queue.isEmpty {
            queue.push(block)
            condition.signal()
        } else {
            queue.push(block)
        }
        condition.unlock()
    }
    
    func deallocate() {
        condition.lock()
        perform = false
        condition.broadcast()
        condition.unlock()
    }
    
}
