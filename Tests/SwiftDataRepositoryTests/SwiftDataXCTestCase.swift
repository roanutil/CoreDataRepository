// SwiftDataXCTestCase.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CustomDump
import SwiftData
import SwiftDataRepository
import XCTest

@MainActor
class SwiftDataXCTestCase: XCTestCase {
    var _repository: SwiftDataRepository?

    func container() async throws -> ModelContainer {
        try await repository().container
    }

    func context() async throws -> ModelContext {
        try await repository().executor.context
    }

    func repository() throws -> SwiftDataRepository {
        try XCTUnwrap(_repository)
    }

    override func setUp() async throws {
        let container = try ModelContainer(
            for: RepoMovie.self,
            ModelConfiguration(inMemory: true)
        )
        _repository = SwiftDataRepository(container: container)
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try await container().destroy()
        _repository = nil
    }

    enum Failure: Error, Hashable, Sendable {
        case noPersistentIdFoundOnProxy
        case noItemFoundForPersistentId
    }

    func verify<T>(_ item: T) async throws where T: PersistentModelProxy {
        guard let identifier = item.persistentId else {
            throw Failure.noPersistentIdFoundOnProxy
        }

        guard let _object: T.Persistent = try await context().object(with: identifier) as? T.Persistent else {
            throw Failure.noItemFoundForPersistentId
        }
        XCTAssertNoDifference(item, try T(persisted: XCTUnwrap(_object)))
    }

    func verifyDoesNotExist<T>(_ item: T) async throws where T: Identifiable, T: PersistentModelProxy,
        T.Persistent: IdentifiableByProxy, T.ID == T.Persistent.ProxID
    {
        let object = try await context().fetch(FetchDescriptor<T.Persistent>()).first(where: { $0.proxyID == item.id })
        XCTAssertNil(object)
    }

    func identifier<T>(for item: T) async throws -> PersistentIdentifier where T: Identifiable, T: PersistentModelProxy,
        T.Persistent: IdentifiableByProxy, T.ID == T.Persistent.ProxID
    {
        let first = try await context().fetch(FetchDescriptor<T.Persistent>()).first(where: { $0.proxyID == item.id })
        return try XCTUnwrap(first?.objectID)
    }
}
