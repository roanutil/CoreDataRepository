// FetchRepositoryFailure.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import CoreData
import Foundation

/// Error type for fetch functions of `CoreDataRepository`
public struct FetchRepositoryFailure<Model: UnmanagedModel>: Error {
    public let code: FailureCode
    public let fetchRequest: NSFetchRequest<Model.RepoManaged>

    public init(code: FailureCode, fetchRequest: NSFetchRequest<Model.RepoManaged>) {
        self.code = code
        self.fetchRequest = fetchRequest
    }

    public var limit: Int { fetchRequest.fetchLimit }
    public var offset: Int { fetchRequest.fetchOffset }
    public var predicate: NSPredicate? { fetchRequest.predicate }
    public var sortDesc: [NSSortDescriptor]? { fetchRequest.sortDescriptors }

    public var localizedDescription: String {
        String(
            format: NSLocalizedString(
                "Encountered the following error while executing a fetch: %@",
                bundle: .module,
                comment: "Description of a fetch operation error."
            ),
            "\(code.localizedDescription)"
        )
    }
}

// MARK: CustomNSError Conformance

extension FetchRepositoryFailure: CustomNSError {
    public static var errorDomain: String { "CoreDataRepository-FetchRepository" }

    public var errorCode: Int {
        code.rawValue
    }
}

// MARK: Equatable Conformance

extension FetchRepositoryFailure: Equatable where Model: Equatable {}

// MARK: Hashable Conformance

extension FetchRepositoryFailure: Hashable where Model: Hashable {}
