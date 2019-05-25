//
//  PDispatchSerialQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchSerialQueue: PDispatchQueueBackend {
    
    fileprivate class Blocks {
        var blocks = [Block]()
        init(_ block: @escaping Block) { blocks = [block] }
    }
    
    fileprivate enum Item {
        case sync(Int), async(Blocks)
    }
    
    private let condition = PCondition()
    private var queue = FifoQueue<Item>(), performing = 1
    
    init() {
        thread.start()
        condition.lockedPerform(block: condition.wait)
    }
    
    // MARK: - Thread
    
    private lazy var threadCondition = PCondition(lock: condition)
    
    private lazy var thread = PThread { [weak self] in
        (self?.condition).map { $0.lockedPerform(block: $0.signal) }
        while let self = self { self.performLoop() }
    }
    
    // MARK: - RunLoop
    
    private func performLoop() {
        condition.lock()
        waitAsync()
        let blocks = queue.pop()
        condition.unlock()
        blocks?.asyncBlocks?.blocks.forEach { $0() }
    }
    
    private func waitAsync() {
        guard performing == 2 || queue.first?.asyncBlocks == nil else { return }
        performing -= 1
        condition.broadcast()
        threadCondition.repeatWait(while: performing == 1 || queue.first?.asyncBlocks == nil)
        performing += 1
    }
    
    // MARK: - Async
    
    @inlinable func async(execute work: @escaping Block) {
        condition.lock()
        if let blocks = queue.last?.asyncBlocks {
            blocks.blocks.append(work)
        } else {
            queue.push(.async(.init(work)))
            if performing == 0 { threadCondition.signal() }
        }
        condition.unlock()
    }
    
    func async(flags: DispatchItemFlags, execute work: @escaping Block) {
        guard flags.contains(.enforceQoS) else { return async(execute: work) }
        condition.lock()
        queue.insertInStart(.async(.init(work)))
        if performing == 0 { threadCondition.signal() }
        condition.unlock()
    }
    
    // MARK: - Sync
    
    private var syncIndex = 0
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T {
        condition.lockedPerform { waitSync(enforce: false) }
        defer { condition.lockedPerform(block: finishSync) }
        return try work()
    }
    
    @discardableResult
    func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T {
        condition.lockedPerform { waitSync(enforce: flags.contains(.enforceQoS)) }
        defer { condition.lockedPerform(block: finishSync) }
        return try work()
    }
    
    private func waitSync(enforce: Bool) {
        defer { performing += 1 }
        if performing == 0, queue.isEmpty { return }
        let index = syncIndex
        syncIndex += 1
        enforce ? queue.insertInStart(.sync(index)) : queue.push(.sync(index))
        condition.repeatWait(while: performing != 0 || queue.first?.syncIndex != index)
        queue.pop()
    }
    
    private func finishSync() {
        performing -= 1
        switch queue.first {
        case .sync?: condition.broadcast()
        case .async?: threadCondition.signal()
        default: break
        }
    }
    
}

extension PDispatchSerialQueue.Item {
    
    var syncIndex: Int? {
        if case .sync(let index) = self { return index }
        return nil
    }
    
    var asyncBlocks: PDispatchSerialQueue.Blocks? {
        if case .async(let blocks) = self { return blocks }
        return nil
    }
    
}
