// CoreDataRepository+Aggregate.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

@preconcurrency import CoreData
import Foundation

// swiftlint:disable file_length

extension CoreDataRepository {
    public enum AggregateFunction: String {
        case average
        case count
        case max
        case min
        case sum
    }

    @inlinable
    public func aggregate<Value>(
        function: AggregateFunction,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as valueType: Value.Type
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        switch function {
        case .count:
            await count(predicate: predicate, entityDesc: entityDesc, as: valueType)
        default:
            await Self.send(
                function: function,
                context: Transaction.current?.context ?? context,
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy
            )
        }
    }

    // MARK: Average

    /// Get the average of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func average<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        await Self.send(
            function: .average,
            context: Transaction.current?.context ?? context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the average of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func averageSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> where Value: Numeric, Value: Sendable {
        AsyncStream { continuation in
            let subscription = AggregateSubscription(
                function: .average,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    /// Subscribe to the average of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func averageThrowingSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> where Value: Numeric, Value: Sendable {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingSubscription(
                function: .average,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    // MARK: Count

    /// Get the count or quantity of managed object instances that satisfy the predicate.
    @inlinable
    public func count<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        await context.performInChild { scratchPad in
            do {
                let request = try NSFetchRequest<NSDictionary>
                    .countRequest(predicate: predicate, entityDesc: entityDesc)
                let count = try scratchPad.count(for: request)
                return Value(exactly: count) ?? Value.zero
            } catch let error as CocoaError {
                throw CoreDataError.cocoa(error)
            } catch {
                throw CoreDataError.unknown(error as NSError)
            }
        }
    }

    /// Subscribe to the count or quantity of managed object instances that satisfy the predicate.
    @inlinable
    public func countSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> where Value: Numeric, Value: Sendable {
        AsyncStream { continuation in
            let subscription = CountSubscription(
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    /// Subscribe to the count or quantity of managed object instances that satisfy the predicate.
    @inlinable
    public func countThrowingSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> where Value: Numeric, Value: Sendable {
        AsyncThrowingStream { continuation in
            let subscription = CountThrowingSubscription(
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    // MARK: Max

    /// Get the max or maximum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func max<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        await Self.send(
            function: .max,
            context: Transaction.current?.context ?? context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the max or maximum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    @inlinable
    public func maxSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> where Value: Numeric, Value: Sendable {
        AsyncStream { continuation in
            let subscription = AggregateSubscription(
                function: .max,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    /// Subscribe to the max or maximum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    @inlinable
    public func maxThrowingSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> where Value: Numeric, Value: Sendable {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingSubscription(
                function: .max,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    // MARK: Min

    /// Get the min or minimum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func min<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        await Self.send(
            function: .min,
            context: Transaction.current?.context ?? context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the min or minimum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    @inlinable
    public func minSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> where Value: Numeric, Value: Sendable {
        AsyncStream { continuation in
            let subscription = AggregateSubscription(
                function: .min,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    /// Subscribe to the min or minimum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    @inlinable
    public func minThrowingSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> where Value: Numeric, Value: Sendable {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingSubscription(
                function: .min,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    // MARK: Sum

    /// Get the sum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func sum<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        await Self.send(
            function: .sum,
            context: Transaction.current?.context ?? context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the sum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func sumSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> where Value: Numeric, Value: Sendable {
        AsyncStream { continuation in
            let subscription = AggregateSubscription(
                function: .sum,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    /// Subscribe to the sum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func sumThrowingSubscription<Value>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> where Value: Numeric, Value: Sendable {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingSubscription(
                function: .sum,
                context: context.childContext(),
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy,
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    // MARK: Internals

    private static func aggregate<Value>(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSDictionary>
    ) throws -> Value where Value: Numeric, Value: Sendable {
        let result = try context.fetch(request)
        guard let value: Value = result.asAggregateValue() else {
            throw CoreDataError.fetchedObjectFailedToCastToExpectedType
        }
        return value
    }

    @usableFromInline
    static func send<Value>(
        function: AggregateFunction,
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) async -> Result<Value, CoreDataError> where Value: Numeric, Value: Sendable {
        guard entityDesc == attributeDesc.entity else {
            return .failure(.propertyDoesNotMatchEntity)
        }
        return await context.performInChild { scratchPad in
            let request = try NSFetchRequest<NSDictionary>.request(
                function: function,
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy
            )
            do {
                let value: Value = try Self.aggregate(context: scratchPad, request: request)
                return value
            } catch let error as CocoaError {
                throw CoreDataError.cocoa(error)
            } catch {
                throw CoreDataError.unknown(error as NSError)
            }
        }
    }
}

// swiftlint:enable file_length
