// IdentifiableByProxy.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

public protocol IdentifiableByProxy {
    associatedtype ProxID: Hashable

    var proxyID: ProxID { get }
}
