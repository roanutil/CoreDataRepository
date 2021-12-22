// RepositoryErrors.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

import Foundation

public enum RepositoryErrors: Error, Equatable, Hashable {
    case unknown
    case noExistingObjectByID
    case cocoa(NSError)
    case propertyDoesNotMatchEntity
    case entityHasNoProperties
}
