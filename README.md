# What is concurrency?
- Wikipedia defines concurrency as "the decomposability property of a program, algorithm, or problem into order-independent or partially-ordered components or units." What this means is looking at the logic of your app to determine which pieces can run at the same time, and possibly in a random order, yet still result in a correct implementation of your data flow.

# GCD & Operations
- There are two APIs that you'll use when making your app concurrent: Grand Central Dispatch, commonly referred to as GCD, and Operations. These are neither competing technologies nor something that you have to exclusively pick between. In fact, Operations are built on top of GCD!

- **Thread-safe** : code that can be safely called from multiple threads without causing any issues.

## Grand Central Dispatch

- GCD is Apple's implementation of C's libdispatch library. Its purpose is to queue up tasks — either a method or a closure — that can be run in parallel, depending on availability of resources; it then executes the tasks on an available processor core.

>Note: Apple's documentation sometimes refers to a block in lieu of closure, since
>that was the name used in Objective-C. You can consider them interchangeable in
>the context of concurrency.

- While GCD uses threads in its implementation, you, as the developer, do not need to worry about managing them yourself. GCD's tasks are so lightweight to enqueue that Apple, in its 2009 technical brief on GCD, stated that only 15 instructions are required for implementation, whereas creating traditional threads could require several hundred instructions.

- All of the tasks that GCD manages for you are placed into GCD-managed first-in, firstout (FIFO) queues. Each task that you submit to a queue is then executed against a pool of threads fully managed by the system.

> Note: There is no guarantee as to which thread your task will execute against

# Synchronous and asynchronous tasks

- Work placed into the queue may either run synchronously or asynchronously. When running a task synchronously, your app will wait and block the current run loop until execution finishes before moving on to the next task. Alternatively, a task that is run asynchronously will start, but return execution to your app immediately. This way, the app is free to run other tasks while the first one is executing.

>Note: It's important to keep in mind that, while the queues are FIFO based, that does not ensure that tasks will finish in the order you submit them. The FIFO procedure applies to when the task starts, not when it finishes.

- In general, you'll want to take any long-running non-UI task that you can find and make it run asynchronously in the background. GCD makes this very simple via closures with a few lines of code, like so:
```swift
// Class level variable
let queue = DispatchQueue(label: "com.raywenderlich.worker")
// Somewhere in your function
queue.async {
// Call slow non-UI methods here
    DispatchQueue.main.async {
    // Update the UI here
    }
}
```
- you create a queue, submit a task to it to run asynchronously on a background thread, and, when it's complete, you delegate the code back to the main thread to update the UI.

## Serial and concurrent queues

- The queue to which your task is submitted also has a characteristic of being either serial or concurrent. Serial queues only have a single thread associated with them and thus only allow a single task to be executed at any given time. A concurrent queue, on the other hand, is able to utilize as many threads as the system has resources for. Threads will be created and released as necessary on a concurrent queue.

> Note: While you can tell iOS that you'd like to use a concurrent queue, remember that there is no guarantee that more than one task will run at a time. If your iOS device is completely bogged down and your app is competing for resources, it may only be capable of running a single task.

## Asynchronous doesn't mean concurrent

- While the difference seems subtle at first, just because your tasks are asynchronous doesn't mean they will run concurrently. You're actually able to submit asynchronous tasks to either a serial queue or a concurrent queue. Being synchronous or asynchronous simply identifies whether or not the queue on which you're running the task must wait for the task to complete before it can spawn the next task.

- On the other hand, categorizing something as serial versus concurrent identifies whether the queue has a single thread or multiple threads available to it. If you think about it, submitting three asynchronous tasks to a serial queue means that each task has to completely finish before the next task is able to start as there is only one thread available.
- In other words, a task being synchronous or not speaks to the source of the task. Being serial or concurrent speaks to the destination of the task.

# Operations
- GCD is great for common tasks that need to be run a single time in the background. When you find yourself building functionality that should be reusable — such as image editing operations — you will likely want to encapsulate that functionality into a class. By subclassing Operation, you can accomplish that goal!

## Operation subclassing
- Operations are fully-functional classes that can be submitted to an OperationQueue, just like you'd submit a closure of work to a DispatchQueue for GCD. Because they're classes and can contain variables, you gain the ability to know what state the operation is in at any given point.

- Operations can exist in any of the following states:
1-  isReady
2- isExecuting
3- isCancelled
4- isFinished

- Unlike GCD, an operation is run synchronously by default, and getting it to run asynchronously requires more work. While you can directly execute an operation yourself, that's almost never going to be a good idea due to its synchronous nature. You'll want to get it off of the main thread by submitting it to an OperationQueue so that your UI performance isn't impacted.

### Bonus features
- But wait, there's more! Operations provide greater control over your tasks as you can now handle such common needs as cancelling the task, reporting the state of the task, wrapping asynchronous tasks into an operation and specifying dependences between various tasks. Chapter 6, "Operations," will provide a more in-depth discussion of using operations in your app.

### BlockOperation
- Sometimes, you find yourself working on an app that heavily uses operations, but find that you have a need for a simpler, GCD-like, closure. If you don't want to also create a DispatchQueue, then you can instead utilize the BlockOperation class.
- BlockOperation subclasses Operation for you and manages the concurrent execution of one or more closures on the default global queue. However, being an actual Operation subclass lets you take advantage of all the other features of an operation.

> Note: Block operations run concurrently. If you need them to run serially, you'll need to setup a dispatch queue instead.

## Which should you use?
- There's no clear-cut directive as to whether you should use GCD or Operations in your app. GCD tends to be simpler to work with for simple tasks you just need to execute and forget. Operations provide much more functionality when you need to keep track of a job or maintain the ability to cancel it.

- If you're just working with methods or chunks of code that need to be executed, GCD is a fitting choice. If you're working with objects that need to encapsulate data and functionality then you're more likely to utilize Operations. Some developers even go to the extreme of saying that you should always use Operations because it's built on top of GCD, and Apple's guidance says to always use the highest level of abstraction provided

- At the end of the day, you should use whichever technology makes the most sense at the time and provides for the greatest long-term sustainability of your project, or specific use-case.


# Queues & Threads

## Dispatch queues
- The way you work with threads is by creating a DispatchQueue. When you create a queue, the OS will potentially create and assign one or more threads to the queue. If existing threads are available, they can be reused; if not, then the OS will create them as necessary.

- Creating a dispatch queue is pretty simple on your part, as you can see in the example below:
```swift
let label = "com.razeware.mycoolapp.networking"
let queue = DispatchQueue(label: label)
```
- The label argument simply needs to be any unique value for identification purposes. While you could simply use a UUID to guarantee uniqueness, it's best to use a reverse- DNS style name, as shown above (e.g. com.company.app), since the label is what you'll see when debugging and it's helpful to assign it meaningful text.

## The main queue
- When your app starts, a main dispatch queue is automatically created for you. It's a serial queue that's responsible for your UI. Because it's used so often, Apple has made it available as a class variable, which you access via DispatchQueue.main. You never want to execute something synchronously against the main queue, unless it's related to actual UI work. Otherwise, you'll lock up your UI which could potentially degrade your app performance.

- there are two types of dispatch queues: serial or concurrent. The default initializer, as shown in the code above, will create a serial queue wherein each task must complete before the next task is able to start.

- In order to create a concurrent queue, simply pass in the .concurrent attribute, like so:
```swift
let label = "com.razeware.mycoolapp.networking"
let queue = DispatchQueue(label: label, attributes: .concurrent)
```
- Concurrent queues are so common that Apple has provided six different global concurrent queues, depending on the Quality of service (QoS) the queue should have.

### Quality of service

- If you just need a concurrent queue but don't want to manage your own, you can use the global class method on DispatchQueue to get one of the pre-defined global queues:
```swift
let queue = DispatchQueue.global(qos: .userInteractive)
```
### **.userInteractive**
- The .userInteractive QoS is recommended for tasks that the user directly interacts with. UI-updating calculations, animations or anything needed to keep the UI responsive and fast. If the work doesn't happen quickly, things may appear to freeze. Tasks submitted to this queue should complete virtually instantaneously.

### **.userInitiated**
- The .userInitiated queue should be used when the user kicks off a task from the UI that needs to happen immediately, but can be done asynchronously. For example, you may need to open a document or read from a local database. If the user clicked a button, this is probably the queue you want. Tasks performed in this queue should take a few seconds or less to complete.

### **.utility**
- You'll want to use the .utility dispatch queue for tasks that would typically include a progress indicator such as long-running computations, I/O, networking or continuous data feeds. The system tries to balance responsiveness and performance with energy efficiency. Tasks can take a few seconds to a few minutes in this queue.

### **.background**
- For tasks that the user is not directly aware of you should use the .background queue. They don't require user interaction and aren't time sensitive. Prefetching, database maintenance, synchronizing remote servers and performing backups are all great examples. The OS will focus on energy efficiency instead of speed. You'll want to use this queue for work that will take significant time, on the order of minutes or more.

### **.default and .unspecified**
- There are two other possible choices that exist, but you should not use explicitly. There's a .default option, which falls between .userInitiated and .utility and is the default value of the qos argument. It's not intended for you to directly use. The second option is .unspecified, and exists to support legacy APIs that may opt the thread out of a quality of service. It's good to know they exist, but if you're using them, you're almost certainly doing something wrong.

> Note: Global queues are always concurrent and first-in, first-out.

```swift
let queue = DispatchQueue(label: label, qos: .userInitiated, attributes: .concurrent)
```
- If you submit a task with a higher quality of service than the queue has, the queue's level will increase. Not only that, but all the operations enqueued will also have their priority raised as well.

- If the current context is the main thread, the inferred QoS is .userInitiated. You can specify a QoS yourself, but as soon as you'll add a task with a higher QoS, your queue's QoS service will be increased to match it.

> Note: You should never perform UI updates on any queue other than the main
queue. If it's not documented what queue an API callback uses, dispatch it to the
main queue!


> Note: Never call sync from the main thread, since it would block your main thread
and could even potentially cause a deadlock.


## Important Notes

## **serial queue**

- The main queue is a serial queue and it work on 1 thread, so when use `DispatchQueue.main.async` this task will add to the end of queue
```swift
DispatchQueue.main.async {
    print("first async")
}
DispatchQueue.main.async {
    print("second async")
}
print("first")
print("second")

// the result of this example : 

// first
// second
// first async
// second async
```
- you code work on  `DispatchQueue.main.sync` so when you write  `print("first")` and `print("second")`, you add this task to sync in main 
- but when you write  `print("first async")` and `print("second async")` in async then this tasks added to the end of queue

## **concurrent queue**
- Concurrent queue works on multiple threads so when you use `sync` current loop is stoped untile task finish but when you use `async`  the queue perform the work on thread and other work also perfom on other threads 

```swift
DispatchQueue.global().async {
    print("first async")
}
DispatchQueue.global().async {
    print("second async")
}

DispatchQueue.global().sync {
    print("first")
}
DispatchQueue.global().sync {
    print("second")
}

// you can't expect the result becase OS will handle threads
// the these some results that appear to me:

// first
// second async
// first async
// second
-----------------------
// first async
// first
// second async
// second
-----------------------
// first
// first async
// second async
// second
```

# Groups & Semaphores

- The aptly named DispatchGroup class is what you'll use when you want to track the completion of a group of tasks.
- You start by initializing a DispatchGroup. Once you have one and want to track a task as part of that group, you can provide the group as an argument to the async method on any dispatch queue:
```swift
let group = DispatchGroup()
someQueue.async(group: group) { ... your work ... }
someQueue.async(group: group) { ... more work .... }
someOtherQueue.async(group: group) { ... other work ... }
group.notify(queue: DispatchQueue.main) { [weak self] in
    self?.textLabel.text = "All jobs have completed"
}
```
- As seen in the example code above, groups are not hardwired to a single dispatch queue. You can use a single group, yet submit jobs to multiple queues, depending on the priority of the task that needs to be run. DispatchGroups provide a notify(queue:) method, which you can use to be notified as soon as every job submitted has finished.

> Note: The notification is itself asynchronous, so it's possible to submit more jobs
to the group after calling notify, as long as the previously submitted jobs have not
already completed.

```swift
let group = DispatchGroup()

DispatchQueue.main.async(group: group ) {
    print("main_1")
}

DispatchQueue.main.async(group: group ) {
    print("main_2")
}

DispatchQueue.global().async(group: group )  {
    print("global_1")
    sleep(2)
}

DispatchQueue.main.async(group: group ) {
    print("main_3")
}


print("first print")


group.notify(queue: DispatchQueue.main) {
    print("notify")
}

DispatchQueue.global().async(group: group )  {
    print("global_2")
    sleep(2)
}
```
the result is : 

```swift
first print
global_1
global_2
main_1
main_2
main_3
notify

```
- `first print` beacse print method is add to main queue
- beacse global function is concurrent and main queue is serial, so global is work immediatly on more than one thread, and the tasks in main queue it add to the end of queue so these works run in the end 



- You'll notice that the notify method takes a dispatch queue as a parameter. When the jobs are all finished, the closure that you provide will be executed in the indicated dispatch queue. The notify call shown is likely to be the version you'll use most often, but there are a couple other versions which allow you to specify a quality of service as well, for example.

## **Synchronous waiting**

- If, for some reason, you can't respond asynchronously to the group's completion notification, then you can instead use the wait method on the dispatch group. This is a synchronous method that will block the current queue until all the jobs have finished. It takes an optional parameter which specifies how long to wait for the tasks to complete. If not specified then there is an infinite wait time: 

```swift
let group = DispatchGroup()
someQueue.async(group: group) { ... }
someQueue.async(group: group) { ... }
someOtherQueue.async(group: group) { ... }
if group.wait(timeout: .now() + 60) == .timedOut {
    print("The jobs didn't finish in 60 seconds")
}
```
> Note: Remember, this blocks the current thread; never ever call wait on the main queue.

> **It's important to know that the jobs will still run, even after the timeout has happened.**

```swift
let group = DispatchGroup()
let queue = DispatchQueue.global(qos: .userInitiated)
queue.async(group: group) {
print("Start job 1")
Thread.sleep(until: Date().addingTimeInterval(10))
    print("End job 1")
}
queue.async(group: group) {
print("Start job 2")
Thread.sleep(until: Date().addingTimeInterval(2))
    print("End job 2")
}
```
- It then synchronously waits for the group to complete:

```swift
if group.wait(timeout: .now() + 5) == .timedOut {
    print("I got tired of waiting")
} else {
    print("All the jobs have completed")
}
```
- When you run the code You'll immediately see messages telling you that jobs 1 and 2 have started. After two seconds, you'll see a message saying job 2 has completed, and then three seconds later a message saying, "I got tired of waiting."

- You can see from the sample that job 2 only sleeps for two seconds and that's why it can complete. You specified five total seconds of time to wait, and that's not enough for job 1 to complete, so the timeout message was printed.

- However, if you wait another five seconds — you've already waited five and job 1 takes ten seconds — you'll see the completion message for job 1.

- At this point, calling a synchronous wait method like this should be a code smell to you, potentially pointing out other issues in your architecture.

## **Wrapping asynchronous methods**

- A dispatch queue natively knows how to work with dispatch groups, and it takes care of signaling to the system that a job has completed for you. In this case, completed means that the code block has run its course. Why does that matter? Because if you call an asynchronous method inside of your closure, then the closure will complete before the internal asynchronous method has completed.

- You've got to somehow tell the task that it's not done until those internal calls have completed as well. In such a case, you can call the provided enter and leave methods on DispatchGroup. Think of them like a simple count of running tasks. Every time you enter, the count goes up by 1. When you leave, the count goes down by 1:

```swift

queue.dispatch(group: group) {
// count is 1
group.enter()
// count is 2
    someAsyncMethod {
        defer { group.leave() }
        // Perform your work here,
        // count goes back to 1 once complete
    }
}

```
- By calling group.enter(), you let the dispatch group know that there's another block of code running, which should be counted towards the group's overall completion status. You, of course, have to pair that with a corresponding group.leave() call or you'll never be signaled of completion. Because you have to call leave even during error conditions, you will usually want to use a defer statement, as shown above, so that, no matter how you exit the closure, the group.leave() code executes.

- In a simple case similar to the previous code sample, you can simply call the enter / leave pairs directly. If you're going to use someAsyncMethod frequently with dispatch groups, you should wrap the method to ensure you never forget to make the necessary calls:

```swift

func myAsyncAdd(
lhs: Int,
rhs: Int,
completion: @escaping (Int) -> Void) {
// Lots of cool code here
completion(lhs + rhs)
}
func myAsyncAddForGroups(
    group: DispatchGroup,
    lhs: Int,
    rhs: Int,
    completion: @escaping (Int) -> Void) {
    
    group.enter()
    myAsyncAdd(first: first, second: second) { result in
        defer { group.leave() }
        completion(result)
    }
}

```

- The wrapper method takes a parameter for the group that it will count against, and then the rest of the arguments should be exactly the same as that of the method you're wrapping. There's nothing special about wrapping the async method other than being 100% sure that the group enter and leave methods are properly handled.

- If you write a wrapper method, then testing — you do test, right? — is simplified to a single location to validate proper pairing of enter and leave calls in all utilizations.

## **Semaphores**

- There are times when you really need to control how many threads have access to a shared resource. You've already seen the read/write pattern to limit access to a single thread, but there are times when you can allow more resources to be used at once while still maintaining control over the total thread count.

- If you're downloading data from the network, for example, you may wish to limit how many downloads happen at once. You'll use a dispatch queue to offload the work, and you'll use dispatch groups so that you know when all the downloads have completed. However, you only want to allow four downloads to happen at once because you know the data you're getting is quite large and resource-heavy to process.

- By using a DispatchSemaphore, you can handle exactly that use case. Before any desired use of the resource, you simply call the wait method, which is a synchronous function, and your thread will pause execution until the resource is available. If nothing has claimed ownership yet, you immediately get access. If somebody else has it, you'll wait until they signal that they're done with it.

- When creating a semaphore, you specify how many concurrent accesses to the resource are allowed. If you wish to enable four network downloads at once, then you pass in 4. If you're trying to lock a resource for exclusive access, then you'd just specify 1.

# [The following explanation from articl on medium](https://medium.com/@roykronenfeld/semaphores-in-swift-e296ea80f860) 

## A Bit of Theory
- A semaphore consists of a threads queue and a counter value (type Int).

**The threads queue**
- is used by the semaphore to keep track of waiting threads in FIFO order (The first thread entered into the queue will be the first to get access to the shared resource once it is available).

**The counter value**
- is used by the semaphore to decide if a thread should get access to a shared resource or not. The counter value changes when we call signal() or wait() function.

### So, when should we call wait() and signal() functions?
- Call wait() each time before using the shared resource. We are basically asking the semaphore if the shared resource is available or not. If not, we will wait.
- Call signal() each time after using the shared resource. We are basically signaling the semaphore that we are done interacting with the shared resource.

### Calling wait() will do the following:
1. Decrement semaphore counter by 1.
2. If the resulting value is less than zero, the thread is frozen.
3. If the resulting value is equal to or bigger than zero, the code will get executed without waiting.

### Calling signal() will do the following:
1. Increment semaphore counter by 1.
2. If the previous value was less than zero, this function wakes the oldest thread currently waiting in the thread queue.
3. If the previous value is equal to or bigger than zero, it means the thread queue is empty, aka, no one is waiting.


<img align="center" src="resources/semaphore.png" width="100%" />

### Example 1 :

```swift
let semaphore = DispatchSemaphore(value: 1)
DispatchQueue.global().async {
   print("Kid 1 - wait")
   semaphore.wait()
   print("Kid 1 - wait finished")
   sleep(1) // Kid 1 playing with iPad
   semaphore.signal()
   print("Kid 1 - done with iPad")
}
DispatchQueue.global().async {
   print("Kid 2 - wait")
   semaphore.wait()
   print("Kid 2 - wait finished")
   sleep(1) // Kid 1 playing with iPad
   semaphore.signal()
   print("Kid 2 - done with iPad")
}
DispatchQueue.global().async {
   print("Kid 3 - wait")
   semaphore.wait()
   print("Kid 3 - wait finished")
   sleep(1) // Kid 1 playing with iPad
   semaphore.signal()
   print("Kid 3 - done with iPad")
}
```
<img align="right" src="resources/gif_1.gif" width="50%" />

**Let’s track the semaphore counter for a better understanding:**
- 1 (our initial value)
- 0 (kid 1 wait, since value >= 0, kid 1 can play the iPad)
- -1 (kid 2 wait, since value < 0, it enters threads queue)
- -2 (kid 3 wait, since value < 0, it enters thread queue)
- -1 (kid 1 signal, last value < 0, wake up kid 2 and pop it from queue)
- 0 (kid 2 signal, last value < 0, wake up kid 3 and pop it from queue)
- 1 (kid 3 signal, last value >= 0, no threads are waiting to be awaken)

### Example 2 :

```swift
let queue = DispatchQueue(label: "com.gcd.myQueue", attributes: .concurrent)
let semaphore = DispatchSemaphore(value: 3)
for i in 0 ..> 15 {
   queue.async {
      let songNumber = i + 1
      semaphore.wait()
      print("Downloading song", songNumber)
      sleep(2) // Download take ~2 sec each
      print("Downloaded song", songNumber)
      semaphore.signal()
   }
}
```
<img align="right" src="resources/gif_2.gif" width="40%" />

**Let’s track the semaphore counter for a better understanding:**
- 3 (our initial value)
- 2 (song 1 wait, since value >= 0, start song download)
- 1 (song 2 wait, since value >= 0, start song download)
- 0 (song 3 wait, since value >= 0, start song download)
- -1 (song 4 wait, since value < 0, add to queue)
- -2 (song 5 wait, since value < 0, add to queue)
- Repeats for all songs, it will take us to counter value of -12
- -12 (song 15 wait, sing value < 0, add to queue)
- -11 (song 1 signal, since last value < 0, wake first song in queue)
- -10 (song 2 signal, since last value < 0, wake first song in queue)
- You can continue this yourself in order to be sure you got the idea…

> **🚧 NEVER run semaphore wait() function on the main thread as it will freeze your app.**
> **Wait() function allows us to specify a timeout. Once timeout is reached, the wait will finish regardless of semaphore count value.**
