// CoreDataError.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// An error that models all the possible error conditions of CoreDataRepository.
///
/// ``CoreDataError`` also conforms to `CustomNSError` so that it cleanly casts to `NSError`
public enum CoreDataError: Error, Hashable, Sendable {
    /// UnmanagedModels store the ``CoreData.NSManagedObjectID`` of their respective RepositoryManagedModels as a URL.
    /// This URL
    /// must be mapped back into a ``NSManagedObjectID`` for most transactions. If it fails, this error is returned.
    case failedToGetObjectIdFromUrl(URL)

    /// For some aggregate functions, a `NSAttributeDescription` is required so that a `NSFetchRequest` can be
    /// constructed
    /// against the correct property.
    /// If the `NSAttributeDescription` is not for the correct or expected `NSEntityDescription`, this error is
    /// returned.
    case propertyDoesNotMatchEntity(description: String?)

    /// CoreData may return a value of a related type to what is actually needed. If casting the value CoreData returns
    /// to the required type fails, this error is returned.
    case fetchedObjectFailedToCastToExpectedType(description: String?)

    /// It's possible for a persisted object to be flagged as deleted but still be fetched. If that happens, this error
    /// is returned.
    case fetchedObjectIsFlaggedAsDeleted(description: String)

    /// If CoreData throws a `CocoaError`, it is embedded here.
    case cocoa(CocoaError)

    /// If the type of an error is unknown, it is cast to `NSError` and embedded here.
    case unknown(NSError)

    /// If a `NSEntityDescription` is malformed by not having a name, this error is returned.
    case noEntityNameFound

    /// The count aggregate function requires at least one `NSAttributeDescription` on the `NSEntityDescription`. If
    /// there
    /// is none, this error is returned.
    case atLeastOneAttributeDescRequired

    /// If a ``ManagedIdUrlReferencable`` value is used in a transaction where it is expected to already be persisted
    /// but has no `URL`
    /// representing the ``NSManagedObjectID``, this error is returned.
    case noUrlOnItemToMapToObjectId(description: String)

    /// If a ``ManagedIdReferencable`` value is used in a transaction where it is expected to already be persisted but
    /// has no `NSManagedObjectID`, this error is returned.
    case noObjectIdOnItem(description: String)

    case noMatchFoundWhenReadingItem(description: String)

    public var localizedDescription: String {
        switch self {
        case .failedToGetObjectIdFromUrl:
            NSLocalizedString(
                "No NSManagedObjectID found that correlates to the provided URL.",
                bundle: .module,
                comment: "Error for when an ObjectID can't be found for the provided URL."
            )
        case .propertyDoesNotMatchEntity:
            NSLocalizedString(
                "There is a mismatch between a provided NSPropertyDescrption's entity and a NSEntityDescription. "
                    + "When a property description is provided, it must match any related entity descriptions.",
                bundle: .module,
                comment: "Error for when the developer does not provide a valid pair of NSAttributeDescription "
                    + "and NSPropertyDescription (or any of their child types)."
            )
        case .fetchedObjectFailedToCastToExpectedType:
            NSLocalizedString(
                "The object corresponding to the provided NSManagedObjectID is an incorrect Entity or "
                    + "NSManagedObject subtype. It failed to cast to the requested type.",
                bundle: .module,
                comment: "Error for when an object is found for a given ObjectID but it is not the expected type."
            )
        case .fetchedObjectIsFlaggedAsDeleted:
            NSLocalizedString(
                "The object corresponding to the provided NSManagedObjectID is deleted and cannot be fetched.",
                bundle: .module,
                comment: "Error for when an object is fetched but is flagged as deleted and is no longer usable."
            )
        case let .cocoa(error):
            error.localizedDescription
        case let .unknown(error):
            error.localizedDescription
        case .noEntityNameFound:
            NSLocalizedString(
                "The managed object entity description does not have a name.",
                bundle: .module,
                comment: "Error for when the NSEntityDescription does not have a name."
            )
        case .atLeastOneAttributeDescRequired:
            NSLocalizedString(
                "The managed object entity has no attribute description. An attribute description is required for "
                    + "aggregate operations.",
                bundle: .module,
                comment: "Error for when the NSEntityDescription has no NSAttributeDescription but one is required."
            )
        case .noUrlOnItemToMapToObjectId:
            NSLocalizedString(
                "No object ID URL found on the model for an operation against an existing managed object.",
                bundle: .module,
                comment: "Error for performing an operation against an existing NSManagedObject but the "
                    + "ManagedIdUrlReferencable instance has no managedIdUrl for looking up the NSManagedOjbectID."
            )
        case .noObjectIdOnItem:
            NSLocalizedString(
                "No object ID found on the model for an operation against an existing managed object.",
                bundle: .module,
                comment: "Error for performing an operation against an existing NSManagedObject but the "
                    + "ManagedIdReferencable instance has no managedId."
            )
        case .noMatchFoundWhenReadingItem:
            NSLocalizedString(
                "No match found when attempting to read an instance from CoreData.",
                bundle: .module,
                comment: "Error for reading an instance from CoreData but no instance was found."
            )
        }
    }

    @usableFromInline
    static func catching<T>(block: () async throws -> T) async throws(Self) -> T {
        do {
            return try await block()
        } catch let error as CoreDataError {
            throw error
        } catch let error as CocoaError {
            throw .cocoa(error)
        } catch {
            throw .unknown(error as NSError)
        }
    }
}

extension CoreDataError: CustomNSError {
    public static let errorDomain: String = "CoreDataRepository"

    @inlinable
    public var errorCode: Int {
        switch self {
        case .failedToGetObjectIdFromUrl:
            1
        case .propertyDoesNotMatchEntity:
            2
        case .fetchedObjectFailedToCastToExpectedType:
            3
        case .fetchedObjectIsFlaggedAsDeleted:
            4
        case .cocoa:
            5
        case .unknown:
            6
        case .noEntityNameFound:
            7
        case .atLeastOneAttributeDescRequired:
            8
        case .noUrlOnItemToMapToObjectId:
            9
        case .noObjectIdOnItem:
            10
        case .noMatchFoundWhenReadingItem:
            11
        }
    }

    public static let urlUserInfoKey: String = "ObjectIdUrl"

    @inlinable
    public var errorUserInfo: [String: Any] {
        switch self {
        case let .failedToGetObjectIdFromUrl(url):
            [Self.urlUserInfoKey: url]
        case .propertyDoesNotMatchEntity:
            [:]
        case .fetchedObjectFailedToCastToExpectedType:
            [:]
        case .fetchedObjectIsFlaggedAsDeleted:
            [:]
        case let .cocoa(error):
            error.userInfo
        case let .unknown(error):
            error.userInfo
        case .noEntityNameFound:
            [:]
        case .atLeastOneAttributeDescRequired:
            [:]
        case .noUrlOnItemToMapToObjectId:
            [:]
        case .noObjectIdOnItem:
            [:]
        case .noMatchFoundWhenReadingItem:
            [:]
        }
    }
}
