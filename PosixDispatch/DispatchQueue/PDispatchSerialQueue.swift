//
//  PDispatchSerialQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

protocol PDispatchSerialQueueDelegate: class {
    
    func cancelPerforming(queue: PDispatchSerialQueue)
    
}

class PDispatchSerialQueue: PDispatchQueueBackend {
    
    fileprivate class Blocks {
        var blocks = [Block]()
        init(_ block: @escaping Block) { blocks = [block] }
    }
    
    fileprivate enum Item {
        case sync(Int), async(Blocks)
    }
    
    let tag: Int
    private let cond = PCondition()
    private var queue = FifoQueue<Item>()
    private var performing = 1, syncIndex = 0
    weak var delegate: PDispatchSerialQueueDelegate?
    
    init(tag: Int = 0) {
        self.tag = tag
        thread.start()
        cond.lockedPerform(block: cond.wait)
    }
    
    // MARK: - Thread
    
    private lazy var thread = PThread { [weak self] in
        self.map { $0.cond.lockedPerform(block: $0.cond.signal) }
        while let self = self { self.performLoop() }
    }
    
    // MARK: - RunLoop
    
    private func performLoop() {
        cond.lock()
        waitAsync()
        let blocks = queue.pop()
        cond.unlock()
        blocks?.asyncBlocks?.blocks.forEach { $0() }
    }
    
    private func waitAsync() {
        guard performing == 2 || queue.first?.asyncBlocks == nil else { return }
        performing -= 1
        cond.broadcast()
        cond.repeatWait(while: performing == 1 || queue.first?.asyncBlocks == nil)
        performing += 1
    }
    
    // MARK: - Async
    
    @inlinable func async(execute work: @escaping Block) {
        cond.lock()
        if let blocks = queue.last?.asyncBlocks {
            blocks.blocks.append(work)
        } else {
            queue.push(.async(.init(work)))
            if performing == 0 { cond.signal() }
        }
        cond.unlock()
    }
    
    func async(flags: DispatchItemFlags, execute work: @escaping Block) {
        guard flags.contains(.enforceQoS) else { return async(execute: work) }
        cond.lock()
        queue.insertInStart(.async(.init(work)))
        if performing == 0 { cond.signal() }
        cond.unlock()
    }
    
    // MARK: - Sync
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T {
        cond.lockedPerform { waitSync(enforce: false) }
        defer { cond.lockedPerform(block: finishSync) }
        return try work()
    }
    
    @discardableResult
    func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T {
        cond.lockedPerform { waitSync(enforce: flags.contains(.enforceQoS)) }
        defer { cond.lockedPerform(block: finishSync) }
        return try work()
    }
    
    private func waitSync(enforce: Bool) {
        defer { performing += 1 }
        if performing == 0 { return }
        let index = syncIndex
        syncIndex += 1
        enforce ? queue.insertInStart(.sync(index)) : queue.push(.sync(index))
        cond.repeatWait(while: performing != 0 || queue.first?.syncIndex != index)
        queue.pop()
    }
    
    private func finishSync() {
        performing -= 1
        cond.broadcast()
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
