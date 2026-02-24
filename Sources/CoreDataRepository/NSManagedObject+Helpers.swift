// NSManagedObject+Helpers.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension NSManagedObject {
    /// Helper function to handle casting ``NSManagedObject`` to a sub-class.
    @inlinable
    public func asManagedModel<T: NSManagedObject>() throws -> T {
        guard let repoManaged = self as? T else {
            throw CoreDataError.fetchedObjectFailedToCastToExpectedType
        }
        return repoManaged
    }
}
