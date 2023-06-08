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
    var _container: ModelContainer?
    var _context: ModelContext?
    var _repository: SwiftDataRepository?

    func container() throws -> ModelContainer {
        try XCTUnwrap(_container)
    }

    func context() throws -> ModelContext {
        try XCTUnwrap(_context)
    }

    func repository() throws -> SwiftDataRepository {
        try XCTUnwrap(_repository)
    }

    override func setUp() async throws {
        let container = try ModelContainer(
            for: RepoMovie.self,
            ModelConfiguration(inMemory: true)
        )
        _container = container
        _context = container.mainContext
        _repository = SwiftDataRepository(container: container)
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        _container?.destroy()
        _container = nil
        _context = nil
        _repository = nil
    }

    enum Failure: Error, Hashable, Sendable {
        case noPersistentIdFoundOnProxy
        case noItemFoundForPersistentId
    }

    func verify<T>(_ item: T) throws where T: PersistentModelProxy {
        guard let identifier = item.persistentId else {
            throw Failure.noPersistentIdFoundOnProxy
        }

        guard let _object: T.Persistent = try context().registeredObject(for: identifier) else {
            throw Failure.noItemFoundForPersistentId
        }
        XCTAssertNoDifference(item, try T(persisted: XCTUnwrap(_object)))
    }

    func verifyDoesNotExist<T>(_ item: T) throws where T: PersistentModelProxy {
        guard let identifier = item.persistentId else {
            throw Failure.noPersistentIdFoundOnProxy
        }

        try context().transaction {
            let model: T.Persistent? = try context().registeredObject(for: identifier)
            XCTAssertNil(model)
        }
    }

    func identifier<T>(for item: T) throws -> PersistentIdentifier where T: Identifiable, T: PersistentModelProxy,
        T.Persistent: Identifiable, T.ID == T.Persistent.ID, T: Codable
    {
        let predicate = #Predicate<T.Persistent> { model in
            model.id == item.id
        }
        let first = try XCTUnwrap(context().fetchIdentifiers(FetchDescriptor(predicate: predicate)).first)
        return first
    }
}
