//
//  PConditionStorage.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/23/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PConditionStorage {
    
    private let lock: PLock
    private var conditions = [Int: PCondition]()
    private var pool = ContiguousArray<PCondition>()
    
    init(lock: PLock) {
        self.lock = lock
    }
    
    @inlinable func signal(index: Int, count: Int = 1) {
        guard let condition = removeCondition(index: index) else { return }
        (0..<count).forEach { _ in condition.signal() }
    }
    
    @inlinable func broadcast(index: Int) {
        removeCondition(index: index)?.broadcast()
    }
    
    private func removeCondition(index: Int) -> PCondition? {
        guard let condition = conditions.removeValue(forKey: index) else { return nil }
        pool.append(condition)
        return condition
    }
    
    @inlinable func wait(index: Int) {
        condition(for: index).wait()
    }
    
    @inlinable func wait(index: Int, while value: @autoclosure () -> Bool) {
        let condition = self.condition(for: index)
        while value() { condition.wait() }
    }
    
    @inlinable func repeatWait(index: Int, while value: @autoclosure () -> Bool) {
        let condition = self.condition(for: index)
        repeat { condition.wait() } while value()
    }
    
    private func condition(for index: Int) -> PCondition {
        if let condition = conditions[index] { return condition }
        let condition = pool.popLast() ?? PCondition(lock: lock)
        conditions[index] = condition
        return condition
    }
    
}
