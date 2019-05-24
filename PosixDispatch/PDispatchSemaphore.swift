//
//  PDispatchSemaphore.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/19/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchSemaphore {
    
    private let condition = PCondition(), max: Int
    private var value: Int
    
    init(value: Int = 0) {
        self.value = value
        max = value
    }
    
    func wait() {
        condition.lock()
        condition.wait(while: value == 0)
        value -= 1
        condition.unlock()
    }
    
    @discardableResult func signal() -> Int {
        condition.lock()
        value += 1
        let result = value
        if value < max { condition.signal() }
        condition.unlock()
        return result
    }
    
}
