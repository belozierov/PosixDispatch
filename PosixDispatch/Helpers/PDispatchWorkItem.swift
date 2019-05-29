//
//  PDispatchWorkItem.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/29/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchWorkItem<T> {
    
    typealias Flags = PDispatchQueue.DispatchItemFlags
    typealias Block = () throws -> T
    typealias Result = Swift.Result<T, Error>
    typealias Completion = (Result) -> Void
    
    enum State {
        case ready, performing, completed, cancelled
    }
    
    enum ItemError: Error {
        case canceled
    }
    
    let flags: Flags
    private let block: Block, condition = PCondition()
    private var _state: State = .ready, result: Result?
    
    init(flags: Flags = [], block: @escaping Block) {
        (self.flags, self.block) = (flags, block)
    }
    
    var state: State {
        return condition.lockedPerform { _state }
    }
    
    func perform() {
        condition.lock()
        if _state != .ready { return condition.unlock() }
        _state = .performing
        condition.unlock()
        let result = Result(catching: block)
        condition.lock()
        if _state == .cancelled { return condition.unlock() }
        self.result = result
        _state = .completed
        condition.broadcast()
        observers.forEach { $0(result) }
        observers.removeAll()
        condition.unlock()
    }
    
    // MARK: - Wait
    
    func wait() {
        condition.lock()
        while _state == .ready || _state != .performing {
            condition.wait()
        }
        condition.unlock()
    }
    
    func await() throws -> T {
        condition.lock()
        defer { condition.unlock() }
        while _state != .cancelled {
            switch result {
            case .success(let result)?: return result
            case .failure(let error)?: throw error
            default: condition.wait()
            }
        }
        throw ItemError.canceled
    }
    
    // MARK: - Observers
    
    private var observers = [Completion]()
    
    func notify(flags: Flags = [], queue: PDispatchQueue, execute: @escaping PThread.Block) {
        condition.lock()
        observers.append { _ in queue.async(flags: flags, execute: execute) }
        condition.unlock()
    }
    
    func notify(flags: Flags = [], queue: PDispatchQueue, execute: @escaping Completion) {
        condition.lock()
        observers.append { result in queue.async(flags: flags) { execute(result) } }
        condition.unlock()
    }
    
    func notify(queue: PDispatchQueue, execute: PDispatchWorkItem) {
        condition.lock()
        observers.append { _ in queue.async(execute: execute) }
        condition.unlock()
    }
    
    // MARK: - Cancel
    
    var isCancelled: Bool {
        return condition.lockedPerform { _state == .cancelled }
    }
    
    func cancel() {
        condition.lock()
        _state = .cancelled
        observers.removeAll()
        condition.broadcast()
        condition.unlock()
    }
    
}
