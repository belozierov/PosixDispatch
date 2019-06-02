//
//  PDispatchSerialQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchSerialQueue: PDispatchQueueBackend {
    
    fileprivate class Blocks {
        var blocks: ContiguousArray<Block>
        init(_ block: @escaping Block) { blocks = [block] }
    }
    
    fileprivate enum Item {
        case sync(Int), async(Blocks)
    }
    
    private let lock = PLock()
    private var performing = false
    
    init() {
        thread.start()
        lock.lockedPerform(block: threadCondition.wait)
    }
    
    // MARK: - Queue
    
    private let queue = FifoQueue<Item>()
    
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
        self?.runLoop.run(while: self?.startNextItem() != nil)
    }
    
    private var runLoop: PRunLoop<AnyIterator<Block>> {
        return PRunLoop(condition: threadCondition, iterator: queue.popIterator)
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
    
    func async(group: PDispatchGroup? = nil, flags: DispatchItemFlags = [], execute work: @escaping Block) {
        let block = group.block(with: work)
        guard flags.contains(.enforceQoS) else { return async(execute: block) }
        lock.lock()
        queue.insertInStart(.async(.init(block)))
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

extension FifoQueue where T == PDispatchSerialQueue.Item {
    
    fileprivate var popIterator: AnyIterator<PDispatchSerialQueue.Block> {
        return AnyIterator {
            guard case .async(let blocks)? = self.first else { return nil }
            self.pop()
            return { blocks.blocks.forEach { $0() } }
        }
    }
    
}
