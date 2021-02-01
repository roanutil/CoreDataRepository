// https://github.com/CombineCommunity/CombineExt/blob/master/Sources/Operators/Create.swift

/*
 Copyright (c) 2020 Combine Community, and/or Shai Mishali

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#if canImport(Combine)
import Combine
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AnyPublisher {
    /// Create a publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically send value or completion events.
    ///                      You should return a `Cancelable`-conforming object
    ///                      from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    AnyPublisher<String, MyError>.create { subscriber in
    ///        // Values
    ///        subscriber.send("Hello")
    ///        subscriber.send("World!")
    ///
    ///        // Complete with error
    ///        subscriber.send(completion: .failure(MyError.someError))
    ///
    ///        // Or, complete successfully
    ///        subscriber.send(completion: .finished)
    ///
    ///        return AnyCancellable {
    ///          // Perform clean-up
    ///        }
    ///    }
    ///
    init(_ factory: @escaping Publishers.Create<Output, Failure>.SubscriberHandler) {
        self = Publishers.Create(factory: factory).eraseToAnyPublisher()
    }

    /// Create a publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically send value or completion events.
    ///                      You should return a `Cancelable`-conforming object
    ///                      from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    AnyPublisher<String, MyError>.create { subscriber in
    ///        // Values
    ///        subscriber.send("Hello")
    ///        subscriber.send("World!")
    ///
    ///        // Complete with error
    ///        subscriber.send(completion: .failure(MyError.someError))
    ///
    ///        // Or, complete successfully
    ///        subscriber.send(completion: .finished)
    ///
    ///        return AnyCancellable {
    ///          // Perform clean-up
    ///        }
    ///    }
    ///
    static func create(_ factory: @escaping Publishers.Create<Output, Failure>.SubscriberHandler)
        -> AnyPublisher<Output, Failure> {
        AnyPublisher(factory)
    }
}

// MARK: - Publisher
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    /// A publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    struct Create<Output, Failure: Swift.Error>: Publisher {
        public typealias SubscriberHandler = (Subscriber) -> Cancellable
        private let factory: SubscriberHandler

        /// Initialize the publisher with a provided factory
        ///
        /// - parameter factory: A factory with a closure to which you can
        ///                      dynamically push value or completion events
        public init(factory: @escaping SubscriberHandler) {
            self.factory = factory
        }

        public func receive<S: Combine.Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(factory: factory, downstream: subscriber))
        }
    }
}

// MARK: - Subscription
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.Create {
    class Subscription<Downstream: Combine.Subscriber>: Combine.Subscription where Output == Downstream.Input, Failure == Downstream.Failure {
        private let buffer: DemandBuffer<Downstream>
        private var cancelable: Cancellable?

        init(factory: @escaping SubscriberHandler,
             downstream: Downstream) {
            self.buffer = DemandBuffer(subscriber: downstream)

            let subscriber = Subscriber(onValue: { [weak self] in _ = self?.buffer.buffer(value: $0) },
                                        onCompletion: { [weak self] in self?.buffer.complete(completion: $0) })

            self.cancelable = factory(subscriber)
        }

        func request(_ demand: Subscribers.Demand) {
            _ = self.buffer.demand(demand)
        }

        func cancel() {
            self.cancelable?.cancel()
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Create.Subscription: CustomStringConvertible {
    var description: String {
        return "Create.Subscription<\(Output.self), \(Failure.self)>"
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers.Create {
    struct Subscriber {
        private let onValue: (Output) -> Void
        private let onCompletion: (Subscribers.Completion<Failure>) -> Void

        fileprivate init(onValue: @escaping (Output) -> Void,
                         onCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
            self.onValue = onValue
            self.onCompletion = onCompletion
        }

        /// Sends a value to the subscriber.
        ///
        /// - Parameter value: The value to send.
        public func send(_ input: Output) {
            onValue(input)
        }

        /// Sends a completion event to the subscriber.
        ///
        /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
        public func send(completion: Subscribers.Completion<Failure>) {
            onCompletion(completion)
        }
    }
}

/// A buffer responsible for managing the demand of a downstream
/// subscriber for an upstream publisher
///
/// It buffers values and completion events and forwards them dynamically
/// according to the demand requested by the downstream
///
/// In a sense, the subscription only relays the requests for demand, as well
/// the events emitted by the upstream — to this buffer, which manages
/// the entire behavior and backpressure contract
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class DemandBuffer<S: Subscriber> {
    private let lock = NSRecursiveLock()
    private var buffer = [S.Input]()
    private let subscriber: S
    private var completion: Subscribers.Completion<S.Failure>?
    private var demandState = Demand()

    /// Initialize a new demand buffer for a provided downstream subscriber
    ///
    /// - parameter subscriber: The downstream subscriber demanding events
    init(subscriber: S) {
        self.subscriber = subscriber
    }

    /// Buffer an upstream value to later be forwarded to
    /// the downstream subscriber, once it demands it
    ///
    /// - parameter value: Upstream value to buffer
    ///
    /// - returns: The demand fulfilled by the bufferr
    func buffer(value: S.Input) -> Subscribers.Demand {
        precondition(self.completion == nil,
                     "How could a completed publisher sent values?! Beats me 🤷‍♂️")

        switch demandState.requested {
        case .unlimited:
            return subscriber.receive(value)
        default:
            buffer.append(value)
            return flush()
        }
    }

    /// Complete the demand buffer with an upstream completion event
    ///
    /// This method will deplete the buffer immediately,
    /// based on the currently accumulated demand, and relay the
    /// completion event down as soon as demand is fulfilled
    ///
    /// - parameter completion: Completion event
    func complete(completion: Subscribers.Completion<S.Failure>) {
        precondition(self.completion == nil,
                     "Completion have already occured, which is quite awkward 🥺")

        self.completion = completion
        _ = flush()
    }

    /// Signal to the buffer that the downstream requested new demand
    ///
    /// - note: The buffer will attempt to flush as many events rqeuested
    ///         by the downstream at this point
    func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
        flush(adding: demand)
    }

    /// Flush buffered events to the downstream based on the current
    /// state of the downstream's demand
    ///
    /// - parameter newDemand: The new demand to add. If `nil`, the flush isn't the
    ///                        result of an explicit demand change
    ///
    /// - note: After fulfilling the downstream's request, if completion
    ///         has already occured, the buffer will be cleared and the
    ///         completion event will be sent to the downstream subscriber
    private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
        lock.lock()
        defer { lock.unlock() }

        if let newDemand = newDemand {
            demandState.requested += newDemand
        }

        // If buffer isn't ready for flushing, return immediately
        guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }

        while !buffer.isEmpty && demandState.processed < demandState.requested {
            demandState.requested += subscriber.receive(buffer.remove(at: 0))
            demandState.processed += 1
        }

        if let completion = completion {
            // Completion event was already sent
            buffer = []
            demandState = .init()
            self.completion = nil
            subscriber.receive(completion: completion)
            return .none
        }

        let sentDemand = demandState.requested - demandState.sent
        demandState.sent += sentDemand
        return sentDemand
    }
}

// MARK: - Private Helpers
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension DemandBuffer {
    /// A model that tracks the downstream's
    /// accumulated demand state
    struct Demand {
        var processed: Subscribers.Demand = .none
        var requested: Subscribers.Demand = .none
        var sent: Subscribers.Demand = .none
    }
}

// MARK: - Internally-scoped helpers
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Subscription {
    /// Reqeust demand if it's not empty
    ///
    /// - parameter demand: Requested demand
    func requestIfNeeded(_ demand: Subscribers.Demand) {
        guard demand > .none else { return }
        request(demand)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Optional where Wrapped == Subscription {
    /// Cancel the Optional subscription and nullify it
    mutating func kill() {
        self?.cancel()
        self = nil
    }
}
#endif

/*
extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
  @inlinable @discardableResult
  func sync<R>(_ work: () -> R) -> R {
    os_unfair_lock_lock(self)
    defer { os_unfair_lock_unlock(self) }
    return work()
  }
}

extension NSRecursiveLock {
  @inlinable @discardableResult
  func sync<R>(work: () -> R) -> R {
    self.lock()
    defer { self.unlock() }
    return work()
  }
}

private class DemandBuffer<S: Subscriber> {
  private var buffer = [S.Input]()
  private let subscriber: S
  private var completion: Subscribers.Completion<S.Failure>?
  private var demandState = Demand()
  private let lock: os_unfair_lock_t

  init(subscriber: S) {
    self.subscriber = subscriber
    self.lock = os_unfair_lock_t.allocate(capacity: 1)
    self.lock.initialize(to: os_unfair_lock())
  }

  deinit {
    self.lock.deinitialize(count: 1)
    self.lock.deallocate()
  }

  func buffer(value: S.Input) -> Subscribers.Demand {
    precondition(
      self.completion == nil, "How could a completed publisher sent values?! Beats me 🤷‍♂️")

    switch demandState.requested {
    case .unlimited:
      return subscriber.receive(value)
    default:
      buffer.append(value)
      return flush()
    }
  }

  func complete(completion: Subscribers.Completion<S.Failure>) {
    precondition(
      self.completion == nil, "Completion have already occurred, which is quite awkward 🥺")

    self.completion = completion
    _ = flush()
  }

  func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
    flush(adding: demand)
  }

  private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
    self.lock.sync {

      if let newDemand = newDemand {
        demandState.requested += newDemand
      }

      // If buffer isn't ready for flushing, return immediately
      guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }

      while !buffer.isEmpty && demandState.processed < demandState.requested {
        demandState.requested += subscriber.receive(buffer.remove(at: 0))
        demandState.processed += 1
      }

      if let completion = completion {
        // Completion event was already sent
        buffer = []
        demandState = .init()
        self.completion = nil
        subscriber.receive(completion: completion)
        return .none
      }

      let sentDemand = demandState.requested - demandState.sent
      demandState.sent += sentDemand
      return sentDemand
    }
  }

  struct Demand {
    var processed: Subscribers.Demand = .none
    var requested: Subscribers.Demand = .none
    var sent: Subscribers.Demand = .none
  }
}

extension AnyPublisher {
  private init(_ callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable) {
    self = Publishers.Create(callback: callback).eraseToAnyPublisher()
  }

  static func create(
    _ factory: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable
  ) -> AnyPublisher<Output, Failure> {
    AnyPublisher(factory)
  }
}

extension Publishers {
  fileprivate class Create<Output, Failure: Swift.Error>: Publisher {
    private let callback: (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable

    init(callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable) {
      self.callback = callback
    }

    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
      subscriber.receive(subscription: Subscription(callback: callback, downstream: subscriber))
    }
  }
}

extension Publishers.Create {
  fileprivate class Subscription<Downstream: Subscriber>: Combine.Subscription
  where Output == Downstream.Input, Failure == Downstream.Failure {
    private let buffer: DemandBuffer<Downstream>
    private var cancellable: Cancellable?

    init(
      callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable,
      downstream: Downstream
    ) {
      self.buffer = DemandBuffer(subscriber: downstream)

      let cancellable = callback(
        .init(
          send: { [weak self] in _ = self?.buffer.buffer(value: $0) },
          complete: { [weak self] in self?.buffer.complete(completion: $0) }
        )
      )

      self.cancellable = cancellable
    }

    func request(_ demand: Subscribers.Demand) {
      _ = self.buffer.demand(demand)
    }

    func cancel() {
      self.cancellable?.cancel()
    }
  }
}

extension Publishers.Create.Subscription: CustomStringConvertible {
  var description: String {
    return "Create.Subscription<\(Output.self), \(Failure.self)>"
  }
}

extension AnyPublisher {
  public struct Subscriber {
    private let _send: (Output) -> Void
    private let _complete: (Subscribers.Completion<Failure>) -> Void

    init(
      send: @escaping (Output) -> Void,
      complete: @escaping (Subscribers.Completion<Failure>) -> Void
    ) {
      self._send = send
      self._complete = complete
    }

    public func send(_ value: Output) {
      self._send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
      self._complete(completion)
    }
  }
}
*/
