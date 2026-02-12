// NSManagedObjectContext+Helpers.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension NSManagedObjectContext {
    /// Helper function for getting the ``NSManagedObjectID`` from an ``URL``
    @inlinable
    public func objectId(from url: URL) -> Result<NSManagedObjectID, CoreDataError> {
        guard let objectId = persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return .failure(CoreDataError.failedToGetObjectIdFromUrl(url))
        }
        return .success(objectId)
    }

    /// Helper function for checking that a managed object is not deleted in the store
    @inlinable
    public func notDeletedObject(for id: NSManagedObjectID) throws -> NSManagedObject {
        let object: NSManagedObject = try existingObject(with: id)
        guard !object.isDeleted else {
            throw CoreDataError.fetchedObjectIsFlaggedAsDeleted(description: id.description)
        }
        return object
    }
}
