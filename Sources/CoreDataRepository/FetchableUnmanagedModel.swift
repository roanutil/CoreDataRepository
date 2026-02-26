// FetchableUnmanagedModel.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// Protocol for a value type for fetchiing a ``NSManagedObject`` subclass
///
/// There are times where a single ``NSManagedObject``subclass may be accessed via multiple value types.
/// ``FetchableUnmanagedModel`` provides a minimal interface for fetching values from CoreData
/// without other functionality.
///
/// For example, for `ManagedMovie`, there are two unmanaged models, `Movie` and `MoviePlaceholder`.
/// `MoviePlaceholder` will never create, update, or delete a corresponding instance of `ManagedMovie`.
/// It is only able to be fetched.
/// `Movie` supports all operations against a corresponding instacnce of `ManagedMovie`.
///
/// ```swift
/// @objc(ManagedMovie)
/// final class ManagedMovie: NSManagedObject {
///     @NSManaged var id: UUID?
///     @NSManaged var title: String?
/// }
///
/// struct Movie: Hashable, UnmanagedModel {
///     let id: UUID
///     var title: String = ""
///     var url: URL?
///
///     init(managed: ManagedMovie) throws {
///         self.init(
///             id: managed.id!,
///             title: managed.title!,
///             url: managed.objectID.uriRepresentation()
///         )
///     }
///
///     func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedMovie {
///         let object = ManagedMovie(context: context)
///         object.id = id
///         object.title = title
///         return object
///     }
///
///     func updating(managed: ManagedMovie) throws {
///         managed.id = id
///         managed.title = title
///     }
/// }
///
/// struct MoviePlaceholder: FetchableUnmanagedModel {
///     let id: UUID
///
///     init(managed: ManagedMovie) throws {
///         self.init(id: managed.id!)
///     }
/// }
/// ```
public protocol FetchableUnmanagedModel: Sendable {
    associatedtype ManagedModel: NSManagedObject

    /// Initialize of new instance of `Self` from an instance of ``ManagedModel``
    init(managed: ManagedModel) throws

    /// ``NSFetchRequest`` for ``ManagedModel`` with a strongly typed ``NSFetchRequest.ResultType``
    static func managedFetchRequest() -> NSFetchRequest<ManagedModel>

    /// A description of the context from where an error is thrown
    var errorDescription: String { get }
}

extension FetchableUnmanagedModel {
    @inlinable
    public static func managedFetchRequest() -> NSFetchRequest<ManagedModel> {
        NSFetchRequest<ManagedModel>(
            entityName: ManagedModel.entity().name ?? ManagedModel.entity()
                .managedObjectClassName
        )
    }

    @inlinable
    public var errorDescription: String {
        "\(Self.self)"
    }
}
