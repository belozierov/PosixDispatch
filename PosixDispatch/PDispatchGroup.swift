//
//  PDispatchGroup.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/19/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PDispatchGroup {
    
    private var count: Int
    private let condition = PCondition()
    
    init(count: Int = 0) {
        self.count = count
    }
    
    @inlinable func setCount(_ count: Int) {
        condition.lock()
        self.count = count
        condition.unlock()
    }
    
    @inlinable func enter() {
        condition.lock()
        count += 1
        condition.unlock()
    }
    
    @inlinable func leave() {
        condition.lock()
        count -= 1
        if count == 0 { condition.signal() }
        condition.unlock()
    }
    
    @inlinable func wait() {
        condition.lock()
        condition.wait()
        condition.unlock()
    }
    
}
