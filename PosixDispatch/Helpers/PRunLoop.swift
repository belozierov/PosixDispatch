//
//  RunLoop.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/27/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

class PRunLoop<Iterator: IteratorProtocol> where Iterator.Element == PThread.Block {
    
    private let condition: PCondition
    private var iterator: Iterator
    
    init(condition: PCondition, iterator: Iterator) {
        self.condition = condition
        self.iterator = iterator
    }
    
    func run(while cond: @autoclosure () -> Bool) {
        repeat { loop() } while cond()
        condition.unlock()
    }
    
    private func loop() {
        condition.wait()
        while let block = iterator.next() {
            condition.unlock()
            block()
            condition.lock()
        }
    }
    
}

extension PRunLoop where Iterator == AnyIterator<PThread.Block> {
    
    convenience init(condition: PCondition, iterator: @escaping () -> PThread.Block?) {
        self.init(condition: condition, iterator: AnyIterator(iterator))
    }
    
}
