// AggregateRepositoryFailure.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import CoreData
import Foundation

/// Error type for aggregate functions of `CoreDataRepository`
public struct AggregateRepositoryFailure: Error {
    public let code: FailureCode
    public let method: Method

    public init(
        code: FailureCode,
        method: Method
    ) {
        self.code = code
        self.method = method
    }

    /// Function or Endpoing where the error originated
    public enum Method: Int {
        case count = 10
        case sum = 20
        case average = 30
        case min = 40
        case max = 50

        var localizedDescription: String {
            switch self {
            case .count:
                return NSLocalizedString(
                    "create",
                    bundle: .module,
                    comment: "Name for a count aggregate failure method."
                )
            case .sum:
                return NSLocalizedString(
                    "read",
                    bundle: .module,
                    comment: "Name for a sum aggregate failure method."
                )
            case .average:
                return NSLocalizedString(
                    "update",
                    bundle: .module,
                    comment: "Name for a average aggregate failure method."
                )
            case .min:
                return NSLocalizedString(
                    "delete",
                    bundle: .module,
                    comment: "Name for a min aggregate failure method."
                )
            case .max:
                return NSLocalizedString(
                    "delete",
                    bundle: .module,
                    comment: "Name for a max aggregate failure method."
                )
            }
        }
    }

    public var localizedDescription: String {
        String(
            format: NSLocalizedString(
                "Encountered the following error while executing an aggregate %@: %@",
                bundle: .module,
                comment: "Description of an aggregate operation error."
            ),
            "\(method.localizedDescription)",
            "\(code.localizedDescription)"
        )
    }
}

// MARK: CustomNSError Conformance

extension AggregateRepositoryFailure: CustomNSError {
    public static let errorDomain: String = "CoreDataRepository-AggregateRepository"

    public var errorCode: Int {
        code.rawValue + method.rawValue
    }
}

// MARK: Hashable conformance

extension AggregateRepositoryFailure: Hashable {}
