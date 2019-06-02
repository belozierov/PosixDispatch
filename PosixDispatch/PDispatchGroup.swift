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
    
    @inlinable func enter() {
        condition.lockedPerform { count += 1 }
    }
    
    @inlinable func leave() {
        condition.lock()
        count -= 1
        if count == 0 { condition.signal() }
        condition.unlock()
    }
    
    @inlinable func wait() {
        condition.lock()
        if count != 0 { condition.wait() }
        condition.unlock()
    }
    
}

extension Optional where Wrapped: PDispatchGroup {
    
    func block(with work: @escaping PThreadPool.Block) -> PThreadPool.Block {
        guard let group = self else { return work }
        group.enter()
        return { work(); group.leave() }
    }
    
}
