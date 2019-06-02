# PosixDispatch
A cross-platform library written in Swift 5 for multithreading based on [POSIX threads](https://uk.wikipedia.org/wiki/Pthread). It has a similar API to Apple’s [GCD](https://developer.apple.com/documentation/dispatch) and in most cases works much faster.

It consists of the following:

 * **PLock** - wrapper for POSIX mutex, analog to [NSLock](https://developer.apple.com/documentation/foundation/nslock)
 * **PCondition** - wrapper for POSIX condition, analog to [NSCondition](https://developer.apple.com/documentation/foundation/nscondition)
 * **PThread** - wrapper for POSIX thread, analog to [Thread](https://developer.apple.com/documentation/foundation/thread)
 * **PThreadPool** - [thread pool](https://en.wikipedia.org/wiki/Thread_pool) implementation
 * **PDispatchQueue** - FIFO queue for serially or concurrently executing tasks, analog to [DispatchQueue](https://developer.apple.com/documentation/dispatch/dispatchqueue)
 * **PDispatchGroup** - group of tasks for aggregation and synchronization, analog to [DispatchGroup](https://developer.apple.com/documentation/dispatch/dispatchgroup)
 * **PDispatchSemaphore** - [semaphore](https://en.wikipedia.org/wiki/Semaphore_(programming)) implementation, analog to [DispatchSemaphore](https://developer.apple.com/documentation/dispatch/dispatchsemaphore)
  * **PDispatchWorkItem** - block wrapper, analog to [DispatchWorkItem](https://developer.apple.com/documentation/dispatch/dispatchworkitem)
