// CoreDataXCTestCase.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

extension FetchableUnmanagedModel {
    static func initFromManaged(_ managed: ManagedModel) throws -> Self {
        try managed.managedObjectContext!.performAndWait {
            try Self(managed: managed)
        }
    }
}

class CoreDataXCTestCase: XCTestCase {
    var _container: NSPersistentContainer?
    var _repositoryContext: NSManagedObjectContext?
    var _repository: CoreDataRepository?
    let mainQueue = DispatchQueue.main
    let backgroundQueue = DispatchQueue(label: "background", qos: .userInitiated)

    func container() throws -> NSPersistentContainer {
        try XCTUnwrap(_container)
    }

    func repositoryContext() throws -> NSManagedObjectContext {
        try XCTUnwrap(_repositoryContext)
    }

    func repository() throws -> CoreDataRepository {
        try XCTUnwrap(_repository)
    }

    override func setUpWithError() throws {
        let stack = CoreDataStack(
            storeName: "coredata_repository_tests",
            type: .sqliteEphemeral,
            container: CoreDataStack.persistentContainer(
                storeName: "coredata_repository_tests",
                type: .sqliteEphemeral,
                model: .model_UuidId
            )
        )
        let container = stack.container
        _container = container
        backgroundQueue.sync {
            _repositoryContext = container.newBackgroundContext()
            _repositoryContext?.automaticallyMergesChangesFromParent = true
        }
        _repository = try CoreDataRepository(context: repositoryContext())
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        _container = nil
        _repositoryContext = nil
        _repository = nil
    }

    func mapInContext<I, O>(_ input: I, transform: (I) throws -> O) throws -> O {
        try repositoryContext().performAndWait {
            try transform(input)
        }
    }

    func verify<T>(_ item: T) async throws where T: FetchableUnmanagedModel, T: Equatable {
        let context = try repositoryContext()
        context.performAndWait {
            var managed: T.ManagedModel?
            do {
                managed = try context.fetch(T.managedFetchRequest()).first { try T(managed: $0) == item }
            } catch {
                XCTFail(
                    "Failed to verify item in store because fetching failed. Error: \(error.localizedDescription)"
                )
                return
            }

            guard managed != nil else {
                XCTFail("Failed to verify item in store because it was not found.")
                return
            }
        }
    }

    func verify<T>(_ item: T) async throws where T: ReadableUnmanagedModel, T: Equatable {
        let context = try repositoryContext()
        try context.performAndWait {
            var _managed: T.ManagedModel?
            do {
                _managed = try item.readManaged(from: context)
            } catch {
                XCTFail(
                    "Failed to verify item in store because reading it failed. Error: \(error.localizedDescription)"
                )
                return
            }

            guard let managed = _managed else {
                XCTFail("Failed to verify item in store because it was not found.")
                return
            }
            try expectNoDifference(item, T(managed: managed))
        }
    }

    func verify(transactionAuthor: String?, timeStamp: Date) throws {
        let historyRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: timeStamp)
        try repositoryContext().performAndWait {
            let historyResult = try XCTUnwrap(repositoryContext().execute(historyRequest) as? NSPersistentHistoryResult)
            let history = try XCTUnwrap(historyResult.result as? [NSPersistentHistoryTransaction])
            XCTAssertGreaterThan(history.count, 0)
            for historyTransaction in history {
                XCTAssertEqual(historyTransaction.author, transactionAuthor)
            }
        }
    }

    func verifyDoesNotExist<T>(_ item: T) async throws where T: FetchableUnmanagedModel, T: Equatable {
        let context = try repositoryContext()
        context.performAndWait {
            var _managed: T.ManagedModel?
            do {
                _managed = try context.fetch(T.managedFetchRequest()).first { try T(managed: $0) == item }
            } catch {
                return
            }

            if let _managed, !_managed.isDeleted {
                XCTFail("Item does exist and is not deleted which is not expected")
            }
        }
    }

    func verifyDoesNotExist<T>(_ item: T) async throws where T: ReadableUnmanagedModel, T: Equatable {
        let context = try repositoryContext()
        context.performAndWait {
            var _managed: T.ManagedModel?
            do {
                _managed = try item.readManaged(from: context)
            } catch {
                return
            }

            if let _managed, !_managed.isDeleted {
                XCTFail("Item does exist and is not deleted which is not expected")
            }
        }
    }

    func delete(managedId: NSManagedObjectID) throws {
        try repositoryContext().performAndWait {
            let managed = try repositoryContext().object(with: managedId)
            try repositoryContext().delete(managed)
            try repositoryContext().save()
        }
    }
}
