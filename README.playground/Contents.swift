
import Foundation

//let queue = DispatchQueue(label: "ss" ,attributes: .concurrent)
//let queue = DispatchQueue(label: "ss" )
//
//print("fdskfds_1")
//
//queue.async {
//    print("yousef")
//    print("yousef_2")
////    queue.sync {
////        print("deadLock")
////    }
//}
//
//queue.sync {
//    sleep(2)
//    print("hi man")
//
//}
//
//DispatchQueue.main.async {
//    print("yyyyyyyy")
//}
//
//print("kkkkkkkkkk")
//
//DispatchQueue.main.async {
//    print("qqqqqqqq")
//}
//
//
//
//queue.async {
//    sleep(1)
//    print("deadLock")
//}
//
//queue.async {
//    print("sssssss")
//}
//
//
//print("fdskfds_2")

//DispatchQueue.global().async {
//    print("first async")
//}
//DispatchQueue.global().async {
//    print("second async")
//}
//
//DispatchQueue.global().sync {
//    print("first")
//}
//DispatchQueue.global().sync {
//    print("second")
//}

//let group = DispatchGroup()
//
//DispatchQueue.main.async(group: group ) {
//    print("main_1")
//}
//
//DispatchQueue.main.async(group: group ) {
//    print("main_2")
//}
//
//DispatchQueue.global().async(group: group )  {
//    print("global_1")
//    sleep(2)
//}
//
//DispatchQueue.main.async(group: group ) {
//    print("main_3")
//}
//
//
//print("first print")
//
//
//group.notify(queue: DispatchQueue.main) {
//    print("notify")
//}
//
//DispatchQueue.global().async(group: group )  {
//    print("global_2")
//    sleep(2)
//}

let queue = DispatchQueue(label: "label", qos: .utility , attributes: .concurrent )
let group = DispatchGroup()
let semaphore = DispatchSemaphore(value: 4)

for i in 1...10 {
    queue.async(group: group) {
        semaphore.wait()
        defer {
            group.leave()
            semaphore.signal()
            print("end closure")
        }
        print("Downloading image \(i)")
        // Simulate a network wait
        Thread.sleep(forTimeInterval: 3)
        print("---------------")
        print("Downloaded image \(i)")
    }
}


let sentence = "Ray's courses are the best!"
let wordOperation = BlockOperation()
for word in sentence.split(separator: " ") {
    wordOperation.addExecutionBlock {
        print(word)
        sleep(2)
    }
}
wordOperation.start()
