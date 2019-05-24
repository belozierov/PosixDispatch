//
//  PConditionStorage.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/23/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

struct PConditionStorage {
    
    private let lock: PLock
    private var conditions = [Int: PCondition]()
    
    init(lock: PLock) {
        self.lock = lock
    }
    
    @inlinable mutating func broadcast(index: Int) {
        conditions.removeValue(forKey: index)?.broadcast()
    }
    
    @inlinable mutating func broadcast() {
        conditions.values.forEach { $0.broadcast() }
        conditions.removeAll()
    }
    
    @inlinable mutating func removeAll() {
        conditions.removeAll()
    }
    
    @inlinable mutating func wait(index: Int) {
        condition(for: index).wait()
    }
    
    @inlinable mutating func wait(index: Int, while value: @autoclosure () -> Bool) {
        let condition = self.condition(for: index)
        while value() { condition.wait() }
    }
    
    @inlinable mutating func repeatWait(index: Int, while value: @autoclosure () -> Bool) {
        let condition = self.condition(for: index)
        repeat { condition.wait() } while value()
    }
    
    private mutating func condition(for index: Int) -> PCondition {
        if let condition = conditions[index] { return condition }
        let condition = PCondition(lock: lock)
        conditions[index] = condition
        return condition
    }
    
}
