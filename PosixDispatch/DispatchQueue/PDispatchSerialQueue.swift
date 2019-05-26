//
//  PDispatchSerialQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchSerialQueue: PDispatchQueueBackend {
    
    private class Blocks {
        var blocks: ContiguousArray<Block>
        init(_ block: @escaping Block) { blocks = [block] }
    }
    
    private enum Item {
        case sync(Int), async(Blocks)
    }
    
    private let lock = PLock()
    private var performing = false
    
    init() {
        thread.start()
        lock.lockedPerform(block: threadCondition.wait)
    }
    
    // MARK: - Queue
    
    private var queue = FifoQueue<Item>()
    
    private func startNextItem() {
        switch queue.first {
        case .sync(let index)?: syncConditions.signal(index: index)
        case .async?: threadCondition.signal()
        default: performing = false
        }
    }
    
    // MARK: - Thread
    
    private lazy var threadCondition = PCondition(lock: lock)
    
    private lazy var thread = PThread { [weak self] in
        self?.lock.lock()
        self?.threadCondition.signal()
        while let condition = self?.threadCondition {
            condition.wait()
            self?.runLoop()
        }
    }
    
    private func runLoop() {
        while case .async(let blocks)? = queue.first {
            queue.pop()
            lock.unlock()
            blocks.blocks.forEach { $0() }
            lock.lock()
        }
        startNextItem()
    }
    
    // MARK: - Async
    
    func async(execute work: @escaping Block) {
        lock.lock()
        defer { lock.unlock() }
        if case .async(let blocks)? = queue.last {
            blocks.blocks.append(work)
        } else {
            queue.push(.async(.init(work)))
            startAsyncPerforming()
        }
    }
    
    func async(flags: DispatchItemFlags, execute work: @escaping Block) {
        guard flags.contains(.enforceQoS) else { return async(execute: work) }
        lock.lock()
        queue.insertInStart(.async(.init(work)))
        startAsyncPerforming()
        lock.unlock()
    }
    
    private func startAsyncPerforming() {
        if performing { return }
        performing = true
        threadCondition.signal()
    }
    
    // MARK: - Sync
    
    private lazy var syncConditions = PConditionStorage(lock: lock)
    private var syncIndex = 0
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T {
        lock.lockedPerform { waitSync(enforce: false) }
        defer { lock.lockedPerform(block: startNextItem) }
        return try work()
    }
    
    @discardableResult
    func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T {
        lock.lockedPerform { waitSync(enforce: flags.contains(.enforceQoS)) }
        defer { lock.lockedPerform(block: startNextItem) }
        return try work()
    }
    
    private func waitSync(enforce: Bool) {
        defer { performing = true }
        guard performing else { return }
        let index = syncIndex
        syncIndex += 1
        enforce ? queue.insertInStart(.sync(index)) : queue.push(.sync(index))
        syncConditions.wait(index: index)
        queue.pop()
    }
    
    deinit {
        threadCondition.signal()
    }
    
}
