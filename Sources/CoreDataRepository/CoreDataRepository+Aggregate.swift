// CoreDataRepository+Aggregate.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

// swiftlint:disable file_length

extension CoreDataRepository {
    // MARK: Count

    /// Get the count or quantity of managed object instances that satisfy the predicate.
    @inlinable
    public func count<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await context.performInScratchPad { scratchPad in
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
    public func countSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
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
    public func countThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
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

    // MARK: Sum

    /// Get the sum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func sum<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .sum,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the sum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func sumSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
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
    public func sumThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
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

    // MARK: Average

    /// Get the average of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func average<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .average,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the average of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func averageSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
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
    public func averageThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
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

    // MARK: Min

    /// Get the min or minimum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func min<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .min,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the min or minimum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    @inlinable
    public func minSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
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
    public func minThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
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

    // MARK: Max

    /// Get the max or maximum of a managed object's numeric property for all instances that satisfy the predicate.
    @inlinable
    public func max<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .max,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the max or maximum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    @inlinable
    public func maxSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
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
    public func maxThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
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

    // MARK: Internals

    @usableFromInline
    enum AggregateFunction: String {
        case count
        case sum
        case average
        case min
        case max
    }

    private static func aggregate<Value: Numeric>(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSDictionary>
    ) throws -> Value {
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
    ) async -> Result<Value, CoreDataError> where Value: Numeric {
        guard entityDesc == attributeDesc.entity else {
            return .failure(.propertyDoesNotMatchEntity)
        }
        return await context.performInScratchPad { scratchPad in
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
