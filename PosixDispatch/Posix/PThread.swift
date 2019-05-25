//
//  PThread.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

import Darwin.POSIX.pthread.pthread

class PThread {
    
    static var current: PThread {
        return PThread(with: pthread_self())
    }
    
    static var isMainThread: Bool {
        return pthread_main_np() != 0
    }
    
    typealias Block = () -> Void
    private let block = UnsafeMutablePointer<Block?>.allocate(capacity: 1)
    private let thread = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
    private var started = false
    
    init(block: @escaping Block) {
        self.block.initialize(to: block)
    }
    
    private init(with thread: pthread_t) {
        self.thread.initialize(to: thread)
    }
    
    func start() {
        if started { return }
        pthread_create(thread, nil, {
            let pointer = $0.assumingMemoryBound(to: PThread.Block?.self)
            if let block = pointer.pointee {
                block()
                pointer.deinitialize(count: 1)
            }
            pointer.deallocate()
            return nil
        }, block)
    }
    
    func wait() {
        guard let thread = thread.pointee else { return }
        pthread_join(thread, nil)
    }
    
    deinit {
        thread.deallocate()
        if !started { block.deallocate() }
    }
    
}

extension PThread: Equatable {
    
    static func == (lhs: PThread, rhs: PThread) -> Bool {
        return pthread_equal(lhs.thread.pointee, rhs.thread.pointee) != 0
    }
    
}
