//
//  FifoQueue.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/20/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

struct FifoQueue<T> {
    
    private var input = [T](), output: [T]
    
    init(item: T) {
        output = [item]
    }
    
    init(array: [T] = []) {
        output = array.reversed()
    }
    
    @inlinable mutating func push(_ item: T) {
        input.append(item)
    }
    
    @inlinable mutating func push(_ items: [T]) {
        input.append(contentsOf: items)
    }
    
    @inlinable  mutating func insertInStart(_ item: T) {
        output.append(item)
    }
    
    @discardableResult mutating func pop() -> T? {
        if let item = output.popLast() { return item }
        if input.isEmpty { return nil }
        output = input.reversed()
        input.removeAll(keepingCapacity: true)
        return output.popLast()
    }
    
    @inlinable  var isEmpty: Bool {
        return output.isEmpty && input.isEmpty
    }
    
    @inlinable  var count: Int {
        return output.count + input.count
    }
    
    @inlinable  var first: T? {
        return output.last ?? input.first
    }
    
    @inlinable  var last: T? {
        return input.last ?? output.first
    }
    
}
