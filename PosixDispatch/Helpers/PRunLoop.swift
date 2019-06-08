//
//  RunLoop.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/27/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PRunLoop {
    
    typealias Block = PThread.Block
    typealias Iterator = () -> Block?
    
    private let iterator: Iterator
    private let condition: PCondition
    private(set) var isCanceled = false
    
    init(condition: PCondition, iterator: @escaping Iterator) {
        self.condition = condition
        self.iterator = iterator
    }
    
    func start() {
        lock()
        repeat { loop() } while continueLoop
        unlock()
    }
    
    private var continueLoop: Bool {
        if isCanceled { return false }
        condition.wait()
        return true
    }
    
    private func loop() {
        while let block = iterator() {
            unlock()
            block()
            lock()
        }
    }
    
    @inlinable func lock() {
        condition.lock()
    }
    
    @inlinable func signal() {
        condition.signal()
    }
    
    @inlinable func unlock() {
        condition.unlock()
    }
    
    func cancel() {
        lock()
        isCanceled = true
        signal()
        unlock()
    }
    
}
