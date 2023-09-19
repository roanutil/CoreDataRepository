// SwiftDataRepository.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation
import SwiftData

public actor SwiftDataRepository: ModelActor {
    public nonisolated var modelContainer: ModelContainer {
        modelExecutor.modelContext.container
    }

    public var context: ModelContext {
        modelExecutor.modelContext
    }

    public let modelExecutor: ModelExecutor

    public init(container: ModelContainer) {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    public enum Failure: Error, Equatable, Hashable, Sendable {
        case unknown(NSError)
        case swiftData(SwiftDataError)
        case noPersistentId
        case noModelFoundForId(PersistentIdentifier)

        public var localizedDescription: String {
            switch self {
            case let .unknown(nsError):
                return nsError.localizedDescription
            case let .swiftData(swiftDataError):
                return swiftDataError.localizedDescription
            case .noPersistentId:
                return "PersistentIdentifier required but not found on proxy."
            case let .noModelFoundForId(id):
                return "No model found in context for id \(id.id) and entity \(id.entityName)."
            }
        }
    }

    public func create<Proxy>(_ item: Proxy) -> Result<Proxy, Failure> where Proxy: PersistentModelProxy {
        do {
            var item = item
            let repoItem = item.asPersistentModel(in: context)
            context.insert(repoItem)
            try context.save()
            item.persistentId = repoItem.persistentModelID
            return .success(item)
        } catch let error as SwiftDataError {
            context.rollback()
            return .failure(.swiftData(error))
        } catch {
            context.rollback()
            return .failure(.unknown(error as NSError))
        }
    }

    public func read<Proxy>(identifier: PersistentIdentifier, as _: Proxy.Type) -> Result<Proxy, Failure>
        where Proxy: PersistentModelProxy
    {
        guard let repoItem: Proxy.Persistent = context.model(for: identifier) as? Proxy.Persistent else {
            return .failure(.noModelFoundForId(identifier))
        }
        return .success(Proxy(persisted: repoItem))
    }

    public func readSubscription<Proxy>(identifier: PersistentIdentifier, as _: Proxy.Type) -> AsyncStream<Result<
        Proxy,
        Failure
    >> where Proxy: PersistentModelProxy {
        guard let repoItem: Proxy.Persistent = context.model(for: identifier) as? Proxy.Persistent else {
            return AsyncStream(unfolding: { .failure(.noModelFoundForId(identifier)) })
        }
        return repoItem.subscription()
    }

    public func readThrowingSubscription<Proxy>(
        identifier: PersistentIdentifier,
        as _: Proxy.Type
    ) -> AsyncThrowingStream<Proxy, Error> where Proxy: PersistentModelProxy {
        guard let repoItem: Proxy.Persistent = context.model(for: identifier) as? Proxy.Persistent else {
            return AsyncThrowingStream(unfolding: { throw Failure.noModelFoundForId(identifier) })
        }
        return repoItem.throwingSubscription()
    }

    public func update<Proxy>(_ item: Proxy) -> Result<Proxy, Failure> where Proxy: PersistentModelProxy {
        guard let persistentId = item.persistentId else {
            return .failure(.noPersistentId)
        }
        guard let object = context.model(for: persistentId) as? Proxy.Persistent else {
            return .failure(.noModelFoundForId(persistentId))
        }
        item.updating(persisted: object)

        do {
            try context.save()
            return .success(Proxy(persisted: object))
        } catch let error as SwiftDataError {
            context.rollback()
            return .failure(.swiftData(error))
        } catch {
            context.rollback()
            return .failure(.unknown(error as NSError))
        }
    }

    public func delete(identifier: PersistentIdentifier) -> Result<Void, Failure> {
        let object = context.model(for: identifier)
        context.delete(object)
        if !object.isDeleted {
            fatalError()
        }
        do {
            try context.save()
            context.processPendingChanges()
            return .success(())
        } catch let error as SwiftDataError {
            context.rollback()
            return .failure(.swiftData(error))
        } catch {
            context.rollback()
            return .failure(.unknown(error as NSError))
        }
    }

    public func fetch<Proxy: PersistentModelProxy>(_ request: FetchDescriptor<Proxy.Persistent>)
        -> Result<[Proxy], Failure>
    {
        do {
            return try .success(context.fetch(request).map(Proxy.init(persisted:)))
        } catch let error as SwiftDataError {
            return .failure(.swiftData(error))
        } catch {
            return .failure(.unknown(error as NSError))
        }
    }

    public func fetch<Proxy: PersistentModelProxy>(
        _ request: FetchDescriptor<Proxy.Persistent>,
        batchSize: Int
    ) -> Result<[Proxy], Failure> {
        do {
            return try .success(context.fetch(request, batchSize: batchSize).map(Proxy.init(persisted:)))
        } catch let error as SwiftDataError {
            return .failure(.swiftData(error))
        } catch {
            return .failure(.unknown(error as NSError))
        }
    }
}

extension PersistentModel {
    func subscription<Proxy, Failure>() -> AsyncStream<Result<Proxy, Failure>> where Proxy: PersistentModelProxy,
        Proxy.Persistent == Self, Failure: Error
    {
        AsyncStream { continuation in
            continuation.yield(.success(Proxy(persisted: self)))
            withObservationTracking {
                _ = self.hasChanges
            } onChange: {
                continuation.yield(.success(Proxy(persisted: self)))
            }
        }
    }

    func throwingSubscription<Proxy>() -> AsyncThrowingStream<Proxy, Error> where Proxy: PersistentModelProxy,
        Proxy.Persistent == Self
    {
        AsyncThrowingStream { continuation in
            continuation.yield(Proxy(persisted: self))
            withObservationTracking {
                _ = self.hasChanges
            } onChange: {
                continuation.yield(Proxy(persisted: self))
            }
        }
    }
}
