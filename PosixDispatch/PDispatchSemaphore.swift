//
//  PDispatchSemaphore.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/19/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchSemaphore {
    
    private let condition = PCondition()
    private var value: Int
    
    init(value: Int = 0) {
        self.value = value
    }
    
    func wait() {
        condition.lock()
        value -= 1
        if value < 0 { condition.wait() }
        condition.unlock()
    }
    
    @discardableResult func signal() -> Bool {
        condition.lock()
        defer { condition.unlock() }
        if value < 0 {
            value += 1
            condition.signal()
            return true
        } else {
            value += 1
            return false
        }
    }
    
}
