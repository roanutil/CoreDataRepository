// CoreDataError.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// An error that models all the possible error conditions of CoreDataRepository.
///
/// CoreDataError also conforms to CustomNSError so that it cleanly casts to NSError
public enum CoreDataError: Error, Hashable, Sendable {
    /// UnmanagedModels store the ``CoreData.NSManagedObjectID`` of their respective RepositoryManagedModels as a URL.
    /// This URL
    /// must be mapped back into a ``NSManagedObjectID`` for most transactions. If it fails, this error is returned.
    case failedToGetObjectIdFromUrl(URL)

    /// For some aggregate functions, a NSAttributeDescription is required so that a NSFetchRequest can be constructed
    /// against the correct property.
    /// If the NSAttributeDescription is not for the correct or expected NSEntityDescription, this error is returned.
    case propertyDoesNotMatchEntity

    /// CoreData may return a value of a related type to what is actually needed. If casting the value CoreData returns
    /// to the required type fails, this error is returned.
    case fetchedObjectFailedToCastToExpectedType

    /// It's possible for a persisted object to be flagged as deleted but still be fetched. If that happens, this error
    /// is returned.
    case fetchedObjectIsFlaggedAsDeleted

    /// If CoreData throws a CocoaError, it is embedded here.
    case cocoa(CocoaError)

    /// If the type of an error is unknown, it is cast to NSError and embedded here.
    case unknown(NSError)

    /// If a NSEntityDescription is malformed by not having a name, this error is returned.
    case noEntityNameFound

    /// The count aggregate function requires at least one NSAttributeDescription on the NSEntityDescription. If there
    /// is none, this error is returned.
    case atLeastOneAttributeDescRequired

    /// If an UnmanagedModel is used in a transaction where it is expected to already be persisted but has no URL
    /// representing the ``NSManagedObjectID``, this error is returned.
    case noUrlOnItemToMapToObjectId

    public var localizedDescription: String {
        switch self {
        case .failedToGetObjectIdFromUrl:
            return NSLocalizedString(
                "No NSManagedObjectID found that correlates to the provided URL.",
                bundle: .module,
                comment: "Error for when an ObjectID can't be found for the provided URL."
            )
        case .propertyDoesNotMatchEntity:
            return NSLocalizedString(
                "There is a mismatch between a provided NSPropertyDescrption's entity and a NSEntityDescription. "
                    + "When a property description is provided, it must match any related entity descriptions.",
                bundle: .module,
                comment: "Error for when the developer does not provide a valid pair of NSAttributeDescription "
                    + "and NSPropertyDescription (or any of their child types)."
            )
        case .fetchedObjectFailedToCastToExpectedType:
            return NSLocalizedString(
                "The object corresponding to the provided NSManagedObjectID is an incorrect Entity or "
                    + "NSManagedObject subtype. It failed to cast to the requested type.",
                bundle: .module,
                comment: "Error for when an object is found for a given ObjectID but it is not the expected type."
            )
        case .fetchedObjectIsFlaggedAsDeleted:
            return NSLocalizedString(
                "The object corresponding to the provided NSManagedObjectID is deleted and cannot be fetched.",
                bundle: .module,
                comment: "Error for when an object is fetched but is flagged as deleted and is no longer usable."
            )
        case let .cocoa(error):
            return error.localizedDescription
        case let .unknown(error):
            return error.localizedDescription
        case .noEntityNameFound:
            return NSLocalizedString(
                "The managed object entity description does not have a name.",
                bundle: .module,
                comment: "Error for when the NSEntityDescription does not have a name."
            )
        case .atLeastOneAttributeDescRequired:
            return NSLocalizedString(
                "The managed object entity has no attribute description. An attribute description is required for "
                    + "aggregate operations.",
                bundle: .module,
                comment: "Error for when the NSEntityDescription has no NSAttributeDescription but one is required."
            )
        case .noUrlOnItemToMapToObjectId:
            return NSLocalizedString(
                "No object ID URL found on the unmanaged model for an operation against an existing managed object.",
                bundle: .module,
                comment: "Error for performing an operation against an existing NSManagedObject but the UnmanagedModel "
                    + "instance has no ManagedRepoUrl for looking up the NSManagedOjbectID."
            )
        }
    }
}

extension CoreDataError: CustomNSError {
    public static let errorDomain: String = "CoreDataRepository"

    public var errorCode: Int {
        switch self {
        case .failedToGetObjectIdFromUrl:
            return 1
        case .propertyDoesNotMatchEntity:
            return 2
        case .fetchedObjectFailedToCastToExpectedType:
            return 3
        case .fetchedObjectIsFlaggedAsDeleted:
            return 4
        case .cocoa:
            return 5
        case .unknown:
            return 6
        case .noEntityNameFound:
            return 7
        case .atLeastOneAttributeDescRequired:
            return 8
        case .noUrlOnItemToMapToObjectId:
            return 9
        }
    }

    public static let urlUserInfoKey: String = "ObjectIdUrl"

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .failedToGetObjectIdFromUrl(url):
            return [Self.urlUserInfoKey: url]
        case .propertyDoesNotMatchEntity:
            return [:]
        case .fetchedObjectFailedToCastToExpectedType:
            return [:]
        case .fetchedObjectIsFlaggedAsDeleted:
            return [:]
        case let .cocoa(error):
            return error.userInfo
        case let .unknown(error):
            return error.userInfo
        case .noEntityNameFound:
            return [:]
        case .atLeastOneAttributeDescRequired:
            return [:]
        case .noUrlOnItemToMapToObjectId:
            return [:]
        }
    }
}
