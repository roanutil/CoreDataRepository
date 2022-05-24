// _Result.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Foundation

/// Wrapper for success/failure output where failure does not confrom to `Error`
enum _Result<Success, Failure> {
    case success(Success)
    case failure(Failure)
}
