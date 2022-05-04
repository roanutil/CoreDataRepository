// BatchRepositoryFailure.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import CoreData
import Foundation

/// Error type for batch functions of `CoreDataRepository`
public struct BatchRepositoryFailure: Error {
    public let code: FailureCode
    public let method: Method
    public let objectIds: Set<NSManagedObjectID>

    public init(
        code: FailureCode,
        method: Method,
        objectIds: Set<NSManagedObjectID>
    ) {
        self.code = code
        self.method = method
        self.objectIds = objectIds
    }

    /// Function or Endpoing where the error originated
    public enum Method: Int {
        case create = 10
        case read = 20
        case update = 30
        case delete = 40

        var localizedDescription: String {
            switch self {
            case .create:
                return NSLocalizedString(
                    "create",
                    bundle: .module,
                    comment: "Name for a batch create failure method."
                )
            case .read:
                return NSLocalizedString(
                    "read",
                    bundle: .module,
                    comment: "Name for a batch read failure method."
                )
            case .update:
                return NSLocalizedString(
                    "update",
                    bundle: .module,
                    comment: "Name for a batch update failure method."
                )
            case .delete:
                return NSLocalizedString(
                    "delete",
                    bundle: .module,
                    comment: "Name for a batch delete failure method."
                )
            }
        }
    }

    public var localizedDescription: String {
        String(
            format: NSLocalizedString(
                "Encountered the following error while executing a batch %@: %@",
                bundle: .module,
                comment: "Description of a batch operation error."
            ),
            "\(method.localizedDescription)",
            "\(code.localizedDescription)"
        )
    }
}

// MARK: CustomNSError Conformance

extension BatchRepositoryFailure: CustomNSError {
    public static let errorDomain: String = "CoreDataRepository-BatchRepository"

    public var errorCode: Int {
        code.rawValue + method.rawValue
    }
}

// MARK: Hashable conformance

extension BatchRepositoryFailure: Hashable {}
