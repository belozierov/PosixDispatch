# PosixDispatch
A cross-platform library written in Swift 5 for multithreading based on POSIX threads. It has a similar API to Apple’s GCD and in most cases works much faster.

It consists of the following:

 * PLock - Swift wrapper of POSIX mutex, analog to [NSLock](https://developer.apple.com/documentation/foundation/nslock)
 * PCondition - Swift wrapper of POSIX condition, analog to [NSCondition](https://developer.apple.com/documentation/foundation/nscondition)
 * PThread - Swift wrapper of POSIX thread, analog to [Thread](https://developer.apple.com/documentation/foundation/thread)
 * PThreadPool - thread pool implementation
 </br>
 * PDispatchQueue - FIFO queue for serially or concurrently executing tasks, analog to [DispatchQueue](https://developer.apple.com/documentation/dispatch/dispatchqueue)
 * PDispatchGroup - group of tasks for aggregation and synchronization, analog to [DispatchGroup](https://developer.apple.com/documentation/dispatch/dispatchgroup)
 * PDispatchSemaphore - semaphore implementation, analog to [DispatchSemaphore](https://developer.apple.com/documentation/dispatch/dispatchsemaphore)
