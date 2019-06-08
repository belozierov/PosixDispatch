//
//  PDispatchQueueBackend.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/18/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

protocol PDispatchQueueBackend: class {
    
    typealias Block = PThread.Block
    typealias DispatchItemFlags = PDispatchQueue.DispatchItemFlags
    typealias WorkItem<T> = PDispatchWorkItem<T>
    typealias DispatchQoS = PQosThreadPool.Qos
    
    var qos: DispatchQoS { get }
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T
    @discardableResult func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T
    
    func async(group: PDispatchGroup?, flags: DispatchItemFlags, execute work: @escaping Block)
    func async(execute work: @escaping Block)
    
}

extension PDispatchQueueBackend {
    
    func async<T>(group: PDispatchGroup? = nil, execute workItem: PDispatchWorkItem<T>) {
        async(group: group, flags: workItem.flags, execute: workItem.perform)
    }
    
    @discardableResult
    func sync<T>(execute workItem: PDispatchWorkItem<T>) throws -> T {
        return try sync(flags: workItem.flags) {
            workItem.perform()
            return try workItem.await()
        }
    }
    
    @discardableResult
    func async<T>(group: PDispatchGroup? = nil, flags: DispatchItemFlags = [], execute work: @escaping () throws -> T) -> PDispatchWorkItem<T> {
        let item = PDispatchWorkItem(flags: flags, block: work)
        async(group: group, flags: flags, execute: item.perform)
        return item
    }
    
}
