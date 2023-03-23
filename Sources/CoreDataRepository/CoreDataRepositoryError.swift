// CoreDataRepositoryError.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

public enum CoreDataRepositoryError: Error, Equatable, Hashable {
    case failedToGetObjectIdFromUrl(URL)
    case propertyDoesNotMatchEntity
    case fetchedObjectFailedToCastToExpectedType
    case fetchedObjectIsFlaggedAsDeleted
    case coreData(NSError)

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
        case let .coreData(error):
            return error.localizedDescription
        }
    }
}

extension CoreDataRepositoryError: CustomNSError {
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
        case .coreData:
            return 5
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
        case let .coreData(error):
            return error.userInfo
        }
    }
}
