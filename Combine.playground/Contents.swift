import Combine
import SwiftUI

class CustomSubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        subscription.request(.unlimited) // Request unlimited values.
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("Received value: \(input)")
        return .unlimited // Continue to request more values.
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Subscription completed.")
    }
}

// A PassthroughSubject can be used both as Publisher and Subscriber
// see line 37.
let intPublisher = PassthroughSubject<Int, Never>()
let cancellable = Set<AnyCancellable>()
// AnySubscriber is rarely used, only when we want to customize behavior
// for .sink operator
let intSubscriber = AnySubscriber(CustomSubscriber())

intPublisher.dropFirst().sink(receiveValue: {
    print($0)
})

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
