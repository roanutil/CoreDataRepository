// CoreDataRepository+Aggregate.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

extension CoreDataRepository {
    // MARK: Count

    /// Get the count or quantity of managed object instances that satisfy the predicate.
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
    public func countStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AsyncStream { continuation in
            let subscription = CountStreamProvider(
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
    public func countThrowingStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let subscription = CountThrowingStreamProvider(
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
    public func sumStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AsyncStream { continuation in
            let subscription = AggregateStreamProvider(
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
    public func sumThrowingStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingStreamProvider(
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
    public func averageStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AsyncStream { continuation in
            let subscription = AggregateStreamProvider(
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
    public func averageThrowingStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingStreamProvider(
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
    public func minStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AsyncStream { continuation in
            let subscription = AggregateStreamProvider(
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
    public func minThrowingStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingStreamProvider(
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
    public func maxStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AsyncStream { continuation in
            let subscription = AggregateStreamProvider(
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
    public func maxThrowingStreamProvider<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let subscription = AggregateThrowingStreamProvider(
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

    private static func send<Value>(
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
