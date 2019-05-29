//
//  PLock.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/17/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

import Darwin.POSIX.pthread.pthread

class PLock {
    
    fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let refCounter: UnsafeMutablePointer<Int>
    
    init(lock: PLock? = nil) {
        if let lock = lock {
            mutex = lock.mutex
            refCounter = lock.refCounter
            refCounter.pointee += 1
        } else {
            mutex = .allocate(capacity: 1)
            pthread_mutex_init(mutex, nil)
            refCounter = .allocate(capacity: 1)
            refCounter.initialize(to: 1)
        }
    }
    
    @inlinable func lock() {
        pthread_mutex_lock(mutex)
    }
    
    @inlinable @discardableResult func tryLock() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
    @inlinable func unlock() {
        pthread_mutex_unlock(mutex)
    }
    
    @inlinable @discardableResult
    func lockedPerform<T>(block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
    
    deinit {
        if refCounter.pointee == 1 {
            pthread_mutex_destroy(mutex)
            mutex.deallocate()
            refCounter.deallocate()
        } else {
            refCounter.pointee -= 1
        }
    }
    
}

class PCondition: PLock {
    
    private let condition = UnsafeMutablePointer<pthread_cond_t>.allocate(capacity: 1)
    
    override init(lock: PLock? = nil) {
        pthread_cond_init(condition, nil)
        super.init(lock: lock)
    }
    
    @inlinable func wait() {
        pthread_cond_wait(condition, mutex)
    }
    
    @inlinable func repeatWait(while cond: @autoclosure () -> Bool) {
        repeat { wait() } while cond()
    }
    
    @inlinable func wait(while cond: @autoclosure () -> Bool) {
        while cond() { wait() }
    }
    
    @inlinable func signal() {
        pthread_cond_signal(condition)
    }
    
    @inlinable func broadcast() {
        pthread_cond_broadcast(condition)
    }
    
    deinit {
        pthread_cond_destroy(condition)
        condition.deallocate()
    }
    
}
