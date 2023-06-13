// Either.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

/// Wrapper for success/failure output where failure does not confrom to `Error`
enum Either<Success, Failure> {
    case success(Success)
    case failure(Failure)
}
