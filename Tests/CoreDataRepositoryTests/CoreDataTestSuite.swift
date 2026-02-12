// CoreDataTestSuite.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import Testing

protocol CoreDataTestSuite {
    var container: NSPersistentContainer { get }
    var repositoryContext: NSManagedObjectContext { get }
    var repository: CoreDataRepository { get }

    mutating func extraSetup() async throws

    init() async throws
    init(container: NSPersistentContainer, repositoryContext: NSManagedObjectContext, repository: CoreDataRepository)
}

extension CoreDataTestSuite {
    init() async throws {
        let stack = CoreDataStack(
            storeName: "coredata_repository_tests",
            type: .sqliteEphemeral,
            container: CoreDataStack.persistentContainer(
                storeName: "coredata_repository_tests",
                type: .sqliteEphemeral,
                model: .model_UuidId
            )
        )
        let _container = stack.container
        let _repositoryContext = _container.newBackgroundContext()
        _repositoryContext.automaticallyMergesChangesFromParent = true
        let _repository = CoreDataRepository(context: _repositoryContext)
        self.init(container: _container, repositoryContext: _repositoryContext, repository: _repository)

        try await extraSetup()
    }

    mutating func extraSetup() async throws {
        // empty by default
    }

    func verify<T: FetchableUnmanagedModel & Equatable>(_ item: T) async throws {
        repositoryContext.performAndWait { [repositoryContext] in
            var managed: T.ManagedModel?
            do {
                managed = try repositoryContext.fetch(T.managedFetchRequest()).first { try T(managed: $0) == item }
            } catch {
                Issue.record(
                    "Failed to verify item in store because fetching failed. Error: \(error.localizedDescription)"
                )
                return
            }

            guard managed != nil else {
                Issue.record("Failed to verify item in store because it was not found.")
                return
            }
        }
    }

    func verify<T: ReadableUnmanagedModel & Equatable>(_ item: T) async throws {
        try repositoryContext.performAndWait { [repositoryContext] in
            var _managed: T.ManagedModel?
            do {
                _managed = try item.readManaged(from: repositoryContext)
            } catch {
                Issue.record(
                    "Failed to verify item in store because reading it failed. Error: \(error.localizedDescription)"
                )
                return
            }

            guard let managed = _managed else {
                Issue.record("Failed to verify item in store because it was not found.")
                return
            }
            try expectNoDifference(item, T(managed: managed))
        }
    }

    func verify(transactionAuthor: String?, timeStamp: Date) throws {
        try repositoryContext.performAndWait { [repositoryContext] in
            let historyRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: timeStamp)
            let historyResult = try #require(repositoryContext.execute(historyRequest) as? NSPersistentHistoryResult)
            let history = try #require(historyResult.result as? [NSPersistentHistoryTransaction])
            #expect(history.count > 0)
            for historyTransaction in history {
                #expect(historyTransaction.author == transactionAuthor)
            }
        }
    }

    func verifyDoesNotExist<T: FetchableUnmanagedModel & Equatable>(_ item: T) async throws {
        repositoryContext.performAndWait { [repositoryContext] in
            var _managed: T.ManagedModel?
            do {
                _managed = try repositoryContext.fetch(T.managedFetchRequest()).first { try T(managed: $0) == item }
            } catch {
                return
            }

            if let _managed, !_managed.isDeleted {
                Issue.record("Item does exist and is not deleted which is not expected")
            }
        }
    }

    func verifyDoesNotExist<T: ReadableUnmanagedModel & Equatable>(_ item: T) async throws {
        repositoryContext.performAndWait { [repositoryContext] in
            var _managed: T.ManagedModel?
            do {
                _managed = try item.readManaged(from: repositoryContext)
            } catch {
                return
            }

            if let _managed, !_managed.isDeleted {
                Issue.record("Item does exist and is not deleted which is not expected")
            }
        }
    }

    func verifyDoesNotExist(transactionAuthor: String?, timeStamp: Date) throws {
        try repositoryContext.performAndWait { [repositoryContext] in
            let historyRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: timeStamp)
            let historyResult = try #require(repositoryContext.execute(historyRequest) as? NSPersistentHistoryResult)
            let history = try #require(historyResult.result as? [NSPersistentHistoryTransaction])
            if transactionAuthor == nil {
                #expect(history.count == 0)
            } else {
                for historyTransaction in history {
                    #expect(historyTransaction.author != transactionAuthor)
                }
            }
        }
    }

    func delete(managedId: NSManagedObjectID) throws {
        try repositoryContext.performAndWait { [repositoryContext] in
            let managed = repositoryContext.object(with: managedId)
            repositoryContext.delete(managed)
            try repositoryContext.save()
        }
    }
}
