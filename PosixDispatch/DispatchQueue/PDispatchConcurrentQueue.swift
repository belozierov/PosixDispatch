//
//  PDispatchConcurrentQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/22/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchConcurrentQueue: PDispatchQueueBackend {
    
    private struct Item {
        
        let index: Int
        var sync: Int, async: Int, barrier: Bool
        var count: Int { return async + sync }
        var isEmpty: Bool { return async == 0 && sync == 0 }
        
        init(sync: Int = 0, async: Int = 0, index: Int, barrier: Bool = false) {
            (self.sync, self.async) = (sync, async)
            (self.index, self.barrier) = (index, barrier)
        }
        
    }
    
    private let lock = PLock()
    let qos: DispatchQoS
    
    init(threadPool: PQosThreadPool, qos: DispatchQoS) {
        self.qos = qos
        self.threadPool = threadPool
    }
    
    // MARK: - Threads
    
    private let threadPool: PQosThreadPool
    
    private func performAsync() {
        threadPool.perform(qos: qos) { self.asyncBlock() }
    }
    
    private func asyncBlock() {
        lock.lock()
        while currentItem.async != 0, let block = blockQueue.pop() {
            currentItem.async -= 1
            perform(block: block)
        }
        lock.unlock()
    }
    
    // MARK: - Items
    
    private let itemQueue = FifoQueue<Item>()
    private var currentItem = Item(index: 0)
    private var lastItem = Item(index: 1)
    private var indexCounter = 2
    
    private var nextIndex: Int {
        defer { indexCounter += 1 }
        return indexCounter
    }
    
    private func resumeNextItem() {
        if let item = itemQueue.pop() {
            currentItem = item
        } else if lastItem.isEmpty {
            currentItem.barrier = false
            return performing = 0
        } else {
            currentItem = lastItem
            lastItem = .init(index: nextIndex)
        }
        performing = currentItem.count
        signalConditions()
    }
    
    private func signalConditions() {
        if currentItem.sync != 0 { syncConditions.broadcast(index: currentItem.index) }
        for _ in 0..<min(currentItem.async, threadPool.threadNumber) { performAsync() }
    }
    
    private func pushBarrier(item: Item) {
        if lastItem.count != 0 { itemQueue.push(lastItem) }
        itemQueue.push(item)
        lastItem = .init(index: nextIndex)
    }
    
    // MARK: - Performing block
    
    private var performing = 0
    
    private func perform<T>(block: () throws -> T) rethrows -> T {
        lock.unlock()
        defer { didFinishPerforming() }
        return try block()
    }
    
    private func didFinishPerforming() {
        lock.lock()
        performing == 1
            ? resumeNextItem()
            : (performing -= 1)
    }
    
    // MARK: - Async
    
    private let blockQueue = FifoQueue<Block>()
    
    func async(execute work: @escaping Block) {
        lock.lock()
        blockQueue.push(work)
        addNotBarrierAsyncCount()
        lock.unlock()
    }
    
    func async(group: PDispatchGroup? = nil, flags: DispatchItemFlags = [], execute work: @escaping Block) {
        lock.lock()
        blockQueue.push(group.block(with: work))
        flags.contains(.barrier)
            ? addBarrierAsyncCount()
            : addNotBarrierAsyncCount()
        lock.unlock()
    }
    
    private func addNotBarrierAsyncCount() {
        guard !currentItem.barrier, itemQueue.isEmpty
            else { return (lastItem.async += 1) }
        currentItem.async += 1
        performing += 1
        performAsync()
    }
    
    private func addBarrierAsyncCount() {
        guard performing == 0
            else { return pushBarrier(item: .init(async: 1, index: nextIndex, barrier: true)) }
        currentItem = .init(async: 1, index: nextIndex, barrier: true)
        performing = 1
        performAsync()
    }
    
    // MARK: - Sync
    
    private lazy var syncConditions = PConditionStorage(lock: lock)
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T {
        lock.lock()
        waitForNotBarrier()
        defer { lock.unlock() }
        return try perform(block: work)
    }
    
    @discardableResult
    func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T {
        lock.lock()
        flags.contains(.barrier)
            ? waitForBarrier()
            : waitForNotBarrier()
        defer { lock.unlock() }
        return try perform(block: work)
    }
    
    private func waitForBarrier() {
        if performing == 0 {
            currentItem.barrier = true
            performing = 1
        } else {
            let index = nextIndex
            pushBarrier(item: .init(sync: 1, index: index, barrier: true))
            syncConditions.wait(index: index)
            currentItem.sync -= 1
        }
    }
    
    private func waitForNotBarrier() {
        guard currentItem.barrier || !itemQueue.isEmpty
            else { return (performing += 1) }
        lastItem.sync += 1
        syncConditions.wait(index: lastItem.index)
        currentItem.sync -= 1
    }
    
}
