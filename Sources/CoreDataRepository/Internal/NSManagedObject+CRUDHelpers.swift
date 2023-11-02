// NSManagedObject+CRUDHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

extension NSManagedObject {
    /// Helper function to handle casting ``NSManagedObject`` to a sub-class.
    func asManagedModel<T>() throws -> T where T: NSManagedObject {
        guard let repoManaged = self as? T else {
            throw CoreDataError.fetchedObjectFailedToCastToExpectedType
        }
        return repoManaged
    }
}