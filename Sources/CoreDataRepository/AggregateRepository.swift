//
//  AggregateRepository.swift
//
//  Created by Andrew Roan on 1/18/21.
//

import CoreData
import Combine

/// A CoreData repository with functions for getting aggregate values
public final class AggregateRepository {
    // MARK: Properties
    /// The context used by the repository
    public let context: NSManagedObjectContext
    var cancellables = [AnyCancellable]()
    var subscriptions = [SubscriptionProvider]()

    // MARK: Init
    /// Initializes a repository
    /// - Parameters:
    ///     - context: NSManagedObjectContext
    ///
    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Types
    /// The aggregate function to be calculated
    public enum Function: String {
        case count
        case sum
        case average
        case min
        case max
    }

    /// A return type for successful calculation
    public struct Success<Value: Numeric> {
        public let function: Function
        public let result: [[String: Value]]
        public let request: NSFetchRequest<NSDictionary>

        public var predicate: NSPredicate? {
            request.predicate
        }
    }

    /// A return type for failure to calculate
    public struct Failure: Error, Hashable {
        public let function: Function
        public let request: NSFetchRequest<NSDictionary>
        public let error: RepositoryErrors

        public var predicate: NSPredicate? {
            request.predicate
        }
    }

    private func request(function: Function, predicate: NSPredicate, entityDesc: NSEntityDescription, attributeDesc: NSAttributeDescription, groupBy: NSAttributeDescription? = nil) -> NSFetchRequest<NSDictionary> {
        let expDesc = NSExpressionDescription.aggregate(function: function, attributeDesc: attributeDesc)
        let request = NSFetchRequest<NSDictionary>(entityName: entityDesc.managedObjectClassName)
        request.entity = entityDesc
        request.returnsObjectsAsFaults = false
        request.resultType = .dictionaryResultType
        if function == .count {
            request.propertiesToFetch = [attributeDesc.name, expDesc]
        } else {
            request.propertiesToFetch = [expDesc]
        }
        
        if let groupBy = groupBy {
            request.propertiesToGroupBy = [groupBy.name]
        }
        request.sortDescriptors = [NSSortDescriptor(key: attributeDesc.name, ascending: false)]
        return request
    }

    // MARK: Private Functions
    /// Calculates aggregate values
    /// - Parameters
    ///     - function: Function
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - `[[String: Value]]`
    ///
    private func aggregate<Value: Numeric>(request: NSFetchRequest<NSDictionary>) throws -> [[String: Value]] {
        let result = try self.context.fetch(request)
        return result as? [[String: Value]] ?? []
    }

    // MARK: Public Functions
    /// Calculate the count for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    /// - Returns
    ///     - AnyPublisher<Success<Int>, Failure<Int>>
    ///
    public func count(predicate: NSPredicate, entityDesc: NSEntityDescription) -> AnyPublisher<Success<Int>, Failure> {
        return Deferred { Future { [weak self] callback in
            let request = NSFetchRequest<NSDictionary>(entityName: entityDesc.name ?? "")
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: entityDesc.attributesByName.values.first!.name, ascending: true)]
            guard let self = self else { return callback(.failure(Failure(function: .count, request: request, error: .unknown))) }
            do {
                let count = try self.context.count(for: request)
                callback(.success(Success(function: .count, result: [["countOf\(entityDesc.name ?? "")": count]], request: request)))
            } catch {
                callback(.failure(Failure(function: .count, request: request, error: .cocoa(error as NSError))))
            }
            
        }}.eraseToAnyPublisher()
    }

    /// Calculate the sum for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Failure<Value>>
    ///
    public func sum<Value: Numeric>(predicate: NSPredicate, entityDesc: NSEntityDescription, attributeDesc: NSAttributeDescription, groupBy: NSAttributeDescription? = nil) -> AnyPublisher<Success<Value>, Failure> {
        let request = self.request(function: .sum, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .sum, request: request, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .sum, request: request, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(request: request)
                callback(.success(Success(function: .sum, result: result, request: request)))
            } catch {
                callback(.failure(Failure(function: .sum, request: request, error: .cocoa(error as NSError))))
            }
        }}.eraseToAnyPublisher()
    }

    /// Calculate the average for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Failure<Value>>
    ///
    public func average<Value: Numeric>(predicate: NSPredicate, entityDesc: NSEntityDescription, attributeDesc: NSAttributeDescription, groupBy: NSAttributeDescription? = nil) -> AnyPublisher<Success<Value>, Failure> {
        let request = self.request(function: .average, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .average, request: request, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .average, request: request, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(request: request)
                callback(.success(Success(function: .average, result: result, request: request)))
            } catch {
                callback(.failure(Failure(function: .average, request: request, error: .cocoa(error as NSError))))
            }
        }}.eraseToAnyPublisher()
    }

    /// Calculate the min for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Failure<Value>>
    ///
    public func min<Value: Numeric>(predicate: NSPredicate, entityDesc: NSEntityDescription, attributeDesc: NSAttributeDescription, groupBy: NSAttributeDescription? = nil) -> AnyPublisher<Success<Value>, Failure> {
        let request = self.request(function: .min, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .min, request: request, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .min, request: request, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(request: request)
                callback(.success(Success(function: .min, result: result, request: request)))
            } catch {
                callback(.failure(Failure(function: .min, request: request, error: .cocoa(error as NSError))))
            }
        }}.eraseToAnyPublisher()
    }

    /// Calculate the max for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Failure<Value>>
    ///
    public func max<Value: Numeric>(predicate: NSPredicate, entityDesc: NSEntityDescription, attributeDesc: NSAttributeDescription, groupBy: NSAttributeDescription? = nil) -> AnyPublisher<Success<Value>, Failure> {
        let request = self.request(function: .max, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .max, request: request, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .max, request: request, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(request: request)
                callback(.success(Success(function: .max, result: result, request: request)))
            } catch {
                callback(.failure(Failure(function: .max, request: request, error: .cocoa(error as NSError))))
            }
        }}.eraseToAnyPublisher()
    }
}

// MARK: Extensions
extension NSExpression {
    /// Convenience initializer for NSExpression that represent an aggregate function on a keypath
    fileprivate convenience init(function: AggregateRepository.Function, attributeDesc: NSAttributeDescription) {
        let keyPathExp = NSExpression(forKeyPath: attributeDesc.name)
        self.init(forFunction: "\(function.rawValue):", arguments: [keyPathExp])
    }
}

extension NSExpressionDescription {
    /// Convenience initializer for NSExpressionDescription that represent the properties to fetch in NSFetchRequest
    fileprivate static func aggregate(function: AggregateRepository.Function, attributeDesc: NSAttributeDescription) -> NSExpressionDescription {
        let expression = NSExpression(function: function, attributeDesc: attributeDesc)
        let expDesc = NSExpressionDescription()
        expDesc.expression = expression
        expDesc.name = "\(function.rawValue)Of\(attributeDesc.name.capitalized)"
        expDesc.expressionResultType = attributeDesc.attributeType
        return expDesc
    }
}

extension AggregateRepository.Success: Equatable where Value: Equatable {}
