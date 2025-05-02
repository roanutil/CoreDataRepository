// ManagedIdUrlReferencable.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// Protocol for types that store a `URL` encoded `NSManagedObjectID` to relate it to an instance of `NSManagedObject`
public protocol ManagedIdUrlReferencable {
    /// Unique `CoreData` managed identifier in `URL` form that relates this instance to its corresponding
    /// `NSManagedObject`
    ///
    /// A `nil` value should mean that this instance has not been saved in the repository
    var managedIdUrl: URL? { get set }
}
