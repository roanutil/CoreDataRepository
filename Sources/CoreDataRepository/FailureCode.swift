// FailureCode.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import CoreData
import Foundation

/// Error codes for major failure points in `CoreDataRepository` code.
public enum FailureCode: Int {
    case unknown = 1
    case noExistingObjectByID = 2
    case propertyDoesNotMatchEntity = 3

    public var localizedDescription: String {
        switch self {
        case .unknown:
            return NSLocalizedString(
                "Unknown error.",
                bundle: .module,
                comment: "Fallback error code for when the cause is unknown."
            )
        case .noExistingObjectByID:
            return NSLocalizedString(
                "The provided NSManagedObjectID does not correlate to any object in the CoreData store.",
                bundle: .module,
                comment: "Error code for when an object can't be found for the provided NSManagedObjectID"
            )
        case .propertyDoesNotMatchEntity:
            return NSLocalizedString(
                "There is a mismatch between a provided NSPropertyDescrption's entity and a NSEntityDescription. "
                    + "When a property description is provided, it must match any related entity descriptions.",
                bundle: .module,
                comment: "Error code for when the developer does not provide a valid pair of NSAttributeDescription "
                    + "and NSPropertyDescription (or any of their child types)."
            )
        }
    }
}
