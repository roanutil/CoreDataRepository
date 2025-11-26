// CustomTests.swift
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
    struct CustomTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test(arguments: [false, true])
        func custom_Success(inTransaction: Bool) async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)

            let result: Result<FetchableModel_UuidId, CoreDataError> = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    await repository.custom { _, scratchPad in
                        let object = modelType.ManagedModel(context: scratchPad)
                        try _value.updating(managed: object)
                        try scratchPad.save()
                        return try modelType.init(managed: object)
                    }
                }
            } else {
                await repository.custom { context, scratchPad in
                    let object = modelType.ManagedModel(context: scratchPad)
                    try _value.updating(managed: object)
                    try scratchPad.save()
                    try context.performAndWait {
                        context.transactionAuthor = transactionAuthor
                        try context.save()
                        context.transactionAuthor = nil
                    }
                    return try modelType.init(managed: object)
                }
            }

            switch result {
            case let .success(value):
                try await verify(value)
                try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
            case let .failure(error):
                Issue.record(error)
            }
        }

        @Test(arguments: [false, true])
        func custom_Failure(inTransaction: Bool) async throws {
            let modelType = FetchableModel_UuidId.self
            let transactionAuthor: String = #function
            let _value1 = modelType.seeded(1)
            let _value2 = modelType.seeded(2)

            try repositoryContext.performAndWait {
                let object = modelType.ManagedModel(context: repositoryContext)
                try _value1.updating(managed: object)
                try repositoryContext.save()
            }

            let result: Result<(FetchableModel_UuidId, FetchableModel_UuidId), CoreDataError> = if inTransaction {
                await {
                    do {
                        let result = try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                            await repository.custom { context, scratchPad in
                                let object1 = modelType.ManagedModel(context: scratchPad)
                                try _value1.updating(managed: object1)
                                let object2 = modelType.ManagedModel(context: scratchPad)
                                try _value2.updating(managed: object2)
                                try scratchPad.save()
                                try context.performAndWait {
                                    context.transactionAuthor = transactionAuthor
                                    try context.save()
                                    context.transactionAuthor = nil
                                }
                                return try (modelType.init(managed: object1), modelType.init(managed: object2))
                            }
                        }
                        return result
                    } catch {
                        return .failure(error as! CoreDataError)
                    }
                }()
            } else {
                await repository.custom { context, scratchPad in
                    let object1 = modelType.ManagedModel(context: scratchPad)
                    try _value1.updating(managed: object1)
                    let object2 = modelType.ManagedModel(context: scratchPad)
                    try _value2.updating(managed: object2)
                    try scratchPad.save()
                    try context.performAndWait {
                        context.transactionAuthor = transactionAuthor
                        try context.save()
                        context.transactionAuthor = nil
                    }
                    return try (modelType.init(managed: object1), modelType.init(managed: object2))
                }
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                let nsError = cocoaError as NSError
                expectNoDifference(nsError.domain, "NSCocoaErrorDomain")
                expectNoDifference(nsError.code, 133_021)
            case let .failure(error):
                Issue.record(error, "Expecting different error")
            }

            try await verify(_value1)
            try await verifyDoesNotExist(_value2)
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
