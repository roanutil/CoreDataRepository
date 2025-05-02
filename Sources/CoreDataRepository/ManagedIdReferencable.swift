// ManagedIdReferencable.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

/// Protocol for types that store an `NSManagedObjectID` to relate it to an instance of `NSManagedObject`
public protocol ManagedIdReferencable {
    /// Unique `CoreData` managed identifier that relates this instance to its corresponding `NSManagedObject`
    ///
    /// A `nil` value should mean that this instance has not been saved in the repository
    var managedId: NSManagedObjectID? { get set }
}
