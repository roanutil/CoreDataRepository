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
        let function: Function
        let result: [[String: Value]]
        let predicate: NSPredicate
    }

    /// A return type for failure to calculate
    public struct Failure: Error {
        let function: Function
        let predicate: NSPredicate
        let error: RepositoryErrors
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
    private func aggregate<Value: Numeric>(
        function: Function,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) throws -> [[String: Value]] {
        let expDesc = NSExpressionDescription.aggregate(function: function, attributeDesc: attributeDesc)
        let request = NSFetchRequest<NSDictionary>(entityName: entityDesc.className)
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
            guard let self = self else { return callback(.failure(Failure(function: .count, predicate: predicate, error: .unknown))) }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityDesc.name ?? "")
            request.predicate = predicate
            do {
                let count = try self.context.count(for: request)
                callback(.success(Success(function: .count, result: [["countOf\(entityDesc.name ?? "")": count]], predicate: predicate)))
            } catch {
                callback(.failure(Failure(function: .count, predicate: predicate, error: .cocoa(error as NSError))))
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
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .sum, predicate: predicate, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .sum, predicate: predicate, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(function: .sum, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
                callback(.success(Success(function: .sum, result: result, predicate: predicate)))
            } catch {
                callback(.failure(Failure(function: .sum, predicate: predicate, error: .cocoa(error as NSError))))
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
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .average, predicate: predicate, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .average, predicate: predicate, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(function: .average, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
                callback(.success(Success(function: .average, result: result, predicate: predicate)))
            } catch {
                callback(.failure(Failure(function: .average, predicate: predicate, error: .cocoa(error as NSError))))
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
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .min, predicate: predicate, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .min, predicate: predicate, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(function: .min, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
                callback(.success(Success(function: .min, result: result, predicate: predicate)))
            } catch {
                callback(.failure(Failure(function: .min, predicate: predicate, error: .cocoa(error as NSError))))
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
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: Failure(function: .max, predicate: predicate, error: .propertyDoesNotMatchEntity)).eraseToAnyPublisher()
        }
        return Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(Failure(function: .max, predicate: predicate, error: .unknown))) }
            do {
                let result: [[String: Value]] = try self.aggregate(function: .max, predicate: predicate, entityDesc: entityDesc, attributeDesc: attributeDesc, groupBy: groupBy)
                callback(.success(Success(function: .max, result: result, predicate: predicate)))
            } catch {
                callback(.failure(Failure(function: .max, predicate: predicate, error: .cocoa(error as NSError))))
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
