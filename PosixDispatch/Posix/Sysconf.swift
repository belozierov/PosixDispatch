//
//  Sysconf.swift
//  PosixDispatch
//
//  Created by Alex Belozierov on 5/25/19.
//  Copyright © 2019 Alex Belozierov. All rights reserved.
//

import Darwin.POSIX.unistd

struct Sysconf {
    
    static let processorsNumber = sysconf(_SC_NPROCESSORS_ONLN)
    
}
