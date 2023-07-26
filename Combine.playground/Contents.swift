import Combine
import SwiftUI

class CustomSubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        subscription.request(.unlimited) // Request unlimited values.
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        if input % 2 == 0 {
            print("\(input) is not even")
        } else {
            print("\(input) is even")
        }
        return .unlimited // Continue to request more values.
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Subscription completed.")
    }
}

// A PassthroughSubject can be used both as Publisher and Subscriber
// see line 42.
let intPublisher = PassthroughSubject<Int, Never>()
var cancellable = Set<AnyCancellable>()
// AnySubscriber is rarely used, only when we want to customize behavior
// for .sink operator
let intSubscriber = CustomSubscriber()

intPublisher.dropFirst().sink(receiveValue: {
    print($0)
})
.store(in: &cancellable)

intPublisher.send(4)
intPublisher.send(2)

// Here i'm subscribing a PassthroughSubject to a AnyPublisher
let intAnyPublisher: AnyPublisher<Int, Never> = intPublisher.eraseToAnyPublisher()
let subscription = intAnyPublisher.sink(receiveValue: {
    print($0)
})

intPublisher.send(6)
subscription.cancel()
intPublisher.send(8)

// subscribe a PassthroughSubject to a AnySubscriber
intPublisher.subscribe(intSubscriber)
intPublisher.send(10)
intPublisher.send(completion: .finished)


public func example(of description: String,
                    action: () -> Void) {
    print("\n——— Example of:", description, "———")
    action()
}

var subscriptions = Set<AnyCancellable>()

// This section demonstrates how to work with publishers and notifications in Combine.
// It creates a PassthroughSubject, subscribes to notifications using NotificationCenter,
// posts a notification, and then removes the observer.
example(of: "Publisher") {
    // 1
    let myNotification = Notification.Name("MyNotification")
    
    // 2
    let publisher = NotificationCenter.default
        .publisher(for: myNotification, object: nil)
    
    // 3
    let center = NotificationCenter.default
    
    // 4
    let observer = center.addObserver(
        forName: myNotification,
        object: nil,
        queue: nil) { notification in
            print("Notification received!")
        }
    
    // 5
    center.post(name: myNotification, object: nil)
    
    // 6
    center.removeObserver(observer)
}

// This section shows how to subscribe to a publisher using a sink subscriber.
// It creates a subscriber for notifications and posts a notification to trigger the subscriber.
example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    let center = NotificationCenter.default
    
    let publisher = center.publisher(for: myNotification, object: nil)
    
    // 1
    let subscription = publisher
        .sink { _ in
            print("Notification received from a publisher!")
        }
    
    // 2
    center.post(name: myNotification, object: nil)
    // 3
    subscription.cancel()
}

// This section demonstrates the use of Just publisher, which emits a single value and then completes.
// It subscribes to the publisher twice, and each subscription prints the received value.
example(of: "Just") {
    // 1
    let just = Just("Hello world!")
    
    // 2
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion", $0)
            },
            receiveValue: {
                print("Received value", $0)
            })
    
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion (another)", $0)
            },
            receiveValue: {
                print("Received value (another)", $0)
            })
}

// This section shows how to use assign(to:on:) to bind a publisher's value to an object's
// property using Key-Value Coding (KVC).
// It creates a class SomeObject with a value property and binds a publisher of strings to this property.
example(of: "assign(to:on:)") {
    // 1
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        }
    }
    
    // 2
    let object = SomeObject()
    
    // 3
    let publisher = ["Hello", "world!"].publisher
    
    // 4
    _ = publisher
        .assign(to: \.value, on: object)
}

// This section demonstrates the use of @Published property wrapper,
// which creates a publisher for the property, and then assigns a
// publisher's value to an object's property directly.
example(of: "assign(to:)") {
    // 1
    class SomeObject {
        @Published var value = 0
    }
    
    let object = SomeObject()
    
    // 2
    object.$value
        .sink {
            print($0)
        }
    
    // 3
    (0..<10).publisher
        .assign(to: &object.$value)
}

// This section shows how to create a custom subscriber by conforming
// to the Subscriber protocol. It subscribes to a publisher and receives values, completion, and errors.
example(of: "Custom Subscriber") {
    // 1
    let publisher = (1...6).publisher
    
    // 2
    final class IntSubscriber: Subscriber {
        // 3
        typealias Input = Int
        typealias Failure = Never
        
        // 4
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }
        
        // 5
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .none
        }
        
        // 6
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    
    publisher.subscribe(subscriber)
}

/*
 example(of: "Future") {
 func futureIncrement(
 integer: Int,
 afterDelay delay: TimeInterval) -> Future<Int, Never> {
 
 Future<Int, Never> { promise in
 print("Original")
 DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
 promise(.success(integer + 1))
 }
 }
 }
 
 // 1
 let future = futureIncrement(integer: 1, afterDelay: 3)
 
 // 2
 future
 .sink(receiveCompletion: { print($0) },
 receiveValue: { print($0) })
 .store(in: &subscriptions)
 
 future
 .sink(receiveCompletion: { print("Second", $0) },
 receiveValue: { print("Second", $0) })
 .store(in: &subscriptions)
 }
 */

// This section demonstrates the use of PassthroughSubject, which acts as both a publisher and a subscriber.
// It creates a custom subscriber, subscribes it to the subject, and sends values through the subject.
example(of: "PassthroughSubject") {
    // 1
    enum MyError: Error {
        case test
    }
    
    // 2
    final class StringSubscriber: Subscriber {
        typealias Input = String
        typealias Failure = MyError
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value", input)
            // 3
            return input == "World" ? .max(1) : .none
        }
        
        func receive(completion: Subscribers.Completion<MyError>) {
            print("Received completion", completion)
        }
    }
    
    // 4
    let subscriber = StringSubscriber()
    
    // 5
    let subject = PassthroughSubject<String, MyError>()
    
    // 6
    subject.subscribe(subscriber)
    
    // 7
    let subscription = subject
        .sink(
            receiveCompletion: { completion in
                print("Received completion (sink)", completion)
            },
            receiveValue: { value in
                print("Received value (sink)", value)
            }
        )
    
    subject.send("Hello")
    subject.send("World")
    
    // 8
    subscription.cancel()
    
    // 9
    subject.send("Still there?")
    
    subject.send(completion: .failure(MyError.test))
    subject.send(completion: .finished)
    subject.send("How about another one?")
}

// This section demonstrates CurrentValueSubject, which is a subject that holds a current value and publishes its changes.
// It shows how to subscribe to the subject and change its value.
example(of: "CurrentValueSubject") {
    // 1
    var subscriptions = Set<AnyCancellable>()
    
    // 2
    let subject = CurrentValueSubject<Int, Never>(0)
    
    // 3
    subject
        .print()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions) // 4
    
    subject.send(1)
    subject.send(2)
    
    print(subject.value)
    
    subject.value = 3
    print(subject.value)
    
    subject
        .print()
        .sink(receiveValue: { print("Second subscription:", $0) })
        .store(in: &subscriptions)
    
    subject.send(completion: .finished)
}

// This section demonstrates dynamically adjusting the demand for receiving values from a publisher based on the received values.
// It uses a custom subscriber to control the demand dynamically.
example(of: "Dynamically adjusting Demand") {
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            
            switch input {
            case 1:
                return .max(2) // 1
            case 3:
                return .max(1) // 2
            default:
                return .none // 3
            }
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            print("Subscription completed.")
        }
    }
}

// This section demonstrates type erasure using eraseToAnyPublisher().
// It converts a PassthroughSubject to an AnyPublisher to hide the underlying specific publisher type.
example(of: "Type erasure") {
    // 1
    let subject = PassthroughSubject<Int, Never>()
    
    // 2
    let publisher = subject.eraseToAnyPublisher()
    
    // 3
    publisher
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    // 4
    subject.send(0)
    //publisher.send(1)
}

// This section demonstrates using async/await with Combine.
// It creates a CurrentValueSubject, uses Task with await to handle asynchronous values, and prints the received elements.
example(of: "async/await") {
    // 1
    let subject = CurrentValueSubject<Int, Never>(0)
    
    // 2
    Task {
        for await element in subject.values {
            print("Element: \(element)")
        }
        print("Completed.")
    }
    
    // 3
    subject.send(1)
    subject.send(2)
    subject.send(3)
    
    subject.send(completion: .finished)
}
