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
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T
    @discardableResult func sync<T>(flags: DispatchItemFlags, execute work: () throws -> T) rethrows -> T
    
    func async(flags: DispatchItemFlags, execute work: @escaping Block)
    func async(execute work: @escaping Block)
    
}
