// TransactionTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import Testing

extension CoreDataRepositoryTests {
    @Suite
    struct TransactionTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test
        func transaction_Success() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let wrongTransactionAuthor = "WRONG_AUTHOR"
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)
            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { _ in
                    let value1 = try await repository
                        .create(_value1, transactionAuthor: wrongTransactionAuthor).get()
                    let value2 = try await repository
                        .create(_value2, transactionAuthor: wrongTransactionAuthor).get()
                    let value3 = try await repository
                        .create(_value3, transactionAuthor: wrongTransactionAuthor).get()
                    return (value1, value2, value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            try await verify(value1)
            try await verify(value2)
            try await verify(value3)

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
            // In transactions individual endpoint transactionAuthor is ignored
            try verifyDoesNotExist(transactionAuthor: wrongTransactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func transaction_Failure() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date.now
            let transactionAuthor = #function

            let expectedError = NSError(
                domain: "NSCocoaErrorDomain",
                code: 133_021,
                userInfo: [
                    "NSExceptionOmitCallstacks": 1,
                    "conflictList": [
                        NSConstraintConflict(),
                    ],
                ]
            )

            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(2)
            do {
                try await repository
                    .withTransaction(transactionAuthor: transactionAuthor) { _ in
                        _ = try await repository
                            .create(_value1).get()
                        _ = try await repository
                            .create(_value2).get()
                        _ = try await repository
                            .create(_value3).get()
                    }
            } catch {
                switch error {
                case let .cocoa(_cocoaError):
                    let nsError = _cocoaError as NSError
                    expectNoDifference(nsError.code, expectedError.code)
                    expectNoDifference(nsError.domain, expectedError.domain)
                case let .unknown(nsError):
                    expectNoDifference(nsError, NSError(domain: "", code: -1))
                default:
                    Issue.record()
                }
            }

            try await verifyDoesNotExist(_value1)
            try await verifyDoesNotExist(_value2)
            try await verifyDoesNotExist(_value3)

            try verifyDoesNotExist(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func transaction_Cancel() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date.now
            let transactionAuthor: String = #function
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)
            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { transaction in
                    let value1 = try await repository
                        .create(_value1).get()
                    let value2 = try await repository
                        .create(_value2).get()
                    let value3 = try await repository
                        .create(_value3).get()
                    transaction.cancel()
                    return (value1, value2, value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            try await verifyDoesNotExist(value1)
            try await verifyDoesNotExist(value2)
            try await verifyDoesNotExist(value3)

            try verifyDoesNotExist(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func concurrentTransactions_OneFailsOtherSucceeds() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date.now
            let successAuthor = "SuccessfulTransaction"
            let failureAuthor = "FailedTransaction"

            let successValue1 = modelType.seeded(1)
            let successValue2 = modelType.seeded(2)
            let failureValue1 = modelType.seeded(3)
            let failureValue2 = modelType.seeded(3) // Duplicate ID to cause failure

            let repository = repository

            // Use actors to coordinate timing between transactions
            actor Coordinator {
                private var successStarted = false
                private var failureFinished = false

                func successDidStart() {
                    successStarted = true
                }

                func waitForSuccessToStart() async {
                    while !successStarted {
                        await Task.yield()
                    }
                }

                func failureDidFinish() {
                    failureFinished = true
                }

                func waitForFailureToFinish() async {
                    while !failureFinished {
                        await Task.yield()
                    }
                }
            }

            let coordinator = Coordinator()

            async let successTask = repository.withTransaction(transactionAuthor: successAuthor) { _ in
                await coordinator.successDidStart()
                let value1 = try await repository.create(successValue1).get()
                let value2 = try await repository.create(successValue2).get()
                // Wait for failure task to complete first
                await coordinator.waitForFailureToFinish()
                return (value1, value2)
            }

            async let failureTask: (FetchableModel_UuidId, FetchableModel_UuidId) = {
                do {
                    let result = try await repository.withTransaction(transactionAuthor: failureAuthor) { _ in
                        // Wait for success task to start
                        await coordinator.waitForSuccessToStart()
                        let value1 = try await repository.create(failureValue1).get()
                        let value2 = try await repository.create(failureValue2).get() // This should fail
                        return (value1, value2)
                    }
                    await coordinator.failureDidFinish()
                    return result
                } catch {
                    await coordinator.failureDidFinish()
                    // Expected to fail due to duplicate ID constraint
                    throw error
                }
            }()

            // Wait for both transactions to complete and handle results
            do {
                let (value1, value2) = try await successTask
                expectNoDifference(value1, successValue1)
                expectNoDifference(value2, successValue2)
                try await verify(value1)
                try await verify(value2)
                try verify(transactionAuthor: successAuthor, timeStamp: historyTimeStamp)
            } catch {
                Issue.record("Successful transaction should not have failed: \(error)")
            }

            do {
                _ = try await failureTask
                Issue.record("Failure transaction should have failed")
            } catch {
                // Expected to fail due to duplicate ID constraint
                try await verifyDoesNotExist(failureValue1)
                try await verifyDoesNotExist(failureValue2)
                try verifyDoesNotExist(transactionAuthor: failureAuthor, timeStamp: historyTimeStamp)
            }
        }

        @Test
        func transactionAcrossTasks() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let wrongTransactionAuthor = "WRONG_AUTHOR"
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)

            let repository = repository
            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { _ in
                    let value1 = try await repository
                        .create(_value1, transactionAuthor: wrongTransactionAuthor).get()
                    let value2 = try await repository
                        .create(_value2, transactionAuthor: wrongTransactionAuthor).get()
                    let value3 = try await Task {
                        try await repository
                            .create(_value3, transactionAuthor: wrongTransactionAuthor).get()
                    }.value
                    return (value1, value2, value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            try await verify(value1)
            try await verify(value2)
            try await verify(value3)

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
            // In transactions individual endpoint transactionAuthor is ignored
            try verifyDoesNotExist(transactionAuthor: wrongTransactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func transactionAcrossDetachedTasks() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let detachedTaskTransactionAuthor = "\(#function)_detached_task"
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)

            let repository = repository
            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { transaction in
                    let value1 = try await repository
                        .create(_value1).get()
                    let value2 = try await repository
                        .create(_value2).get()
                    let value3 = try await Task.detached {
                        try await repository
                            .create(_value3, transactionAuthor: detachedTaskTransactionAuthor).get()
                    }.value
                    transaction.cancel()
                    return (value1, value2, value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            // `value3` was created in a detached task which made it NOT part of the transaction
            await withKnownIssue {
                try await verify(value1)
                try await verify(value2)
            }
            try await verify(value3)

            try verify(transactionAuthor: detachedTaskTransactionAuthor, timeStamp: historyTimeStamp)
            try verifyDoesNotExist(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func transactionAcrossDispatchQueue() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let detachedTaskTransactionAuthor = "\(#function)_detached_task"
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)

            let dispatchQueue = DispatchQueue(label: "value_3", qos: .userInitiated)

            let repository = repository

            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { transaction in
                    let value1 = try await repository
                        .create(_value1).get()
                    let value2 = try await repository
                        .create(_value2).get()
                    await withCheckedContinuation { continuation in
                        dispatchQueue.async {
                            Task {
                                _ = try await repository
                                    .create(_value3, transactionAuthor: detachedTaskTransactionAuthor).get()
                                continuation.resume()
                            }
                        }
                    }
                    transaction.cancel()
                    return (value1, value2, _value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            // `value3` was created in a DispatchQueue which made it NOT part of the transaction
            await withKnownIssue {
                try await verify(value1)
                try await verify(value2)
            }
            try await verify(value3)

            try verify(transactionAuthor: detachedTaskTransactionAuthor, timeStamp: historyTimeStamp)
            try verifyDoesNotExist(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func transactionAcrossDetachedTasks_ContinuingTransaction() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let detachedTaskTransactionAuthor = "\(#function)_detached_task"
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)

            let repository = repository
            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { transaction in
                    let value1 = try await repository
                        .create(_value1).get()
                    let value2 = try await repository
                        .create(_value2).get()
                    let value3 = try await Task.detached {
                        try await repository.withTransaction(continuing: transaction) { _ in
                            try await repository
                                .create(_value3, transactionAuthor: detachedTaskTransactionAuthor).get()
                        }
                    }.value
                    transaction.cancel()
                    return (value1, value2, value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            try await verifyDoesNotExist(value1)
            try await verifyDoesNotExist(value2)
            try await verifyDoesNotExist(value3)

            try verifyDoesNotExist(transactionAuthor: detachedTaskTransactionAuthor, timeStamp: historyTimeStamp)
            try verifyDoesNotExist(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func transactionAcrossDispatchQueue_ContinuingTransaction() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let detachedTaskTransactionAuthor = "\(#function)_detached_task"
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)
            let _value3 = modelType.seeded(3)

            let dispatchQueue = DispatchQueue(label: "value_3", qos: .userInitiated)

            let repository = repository

            let (value1, value2, value3) = try await repository
                .withTransaction(transactionAuthor: transactionAuthor) { transaction in
                    let value1 = try await repository
                        .create(_value1).get()
                    let value2 = try await repository
                        .create(_value2).get()
                    await withCheckedContinuation { continuation in
                        dispatchQueue.async {
                            Task {
                                try await repository.withTransaction(continuing: transaction) { _ in
                                    _ = try await repository
                                        .create(_value3, transactionAuthor: detachedTaskTransactionAuthor).get()
                                }
                                continuation.resume()
                            }
                        }
                    }
                    transaction.cancel()
                    return (value1, value2, _value3)
                }

            expectNoDifference(value1, _value1)
            expectNoDifference(value2, _value2)
            expectNoDifference(value3, _value3)

            try await verifyDoesNotExist(value1)
            try await verifyDoesNotExist(value2)
            try await verifyDoesNotExist(value3)

            try verifyDoesNotExist(transactionAuthor: detachedTaskTransactionAuthor, timeStamp: historyTimeStamp)
            try verifyDoesNotExist(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        init(
            container: NSPersistentContainer,
            repositoryContext: NSManagedObjectContext,
            repository: CoreDataRepository
        ) {
            self.container = container
            self.repositoryContext = repositoryContext
            self.repository = repository
        }
    }
}
