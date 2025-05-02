// coredata-repository-benchmarks.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

// swiftlint:disable file_length

import Benchmark
import CoreData
import CoreDataRepository
import Foundation
import Internal

extension Benchmark.Configuration {
    static let shared = Self(metrics: .default, scalingFactor: .kilo)
}

let benchmarks = {
    Benchmark("Vanilla CoreData Read By NSManagedObjectID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let objectIds = try managedModel.objects(in: context, scale: scale).map(\.objectID)
        let objectId = objectIds.randomElement()!

        benchmark.startMeasurement()
        try blackHole(managedModel.object(managedId: objectId, in: context))
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Read By NSManagedObjectID URL", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let unmanagedModel = FetchableModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let objectIds = try managedModel.objects(in: context, scale: scale).map(\.objectID)
        let objectId = objectIds.randomElement()!
        let repository = CoreDataRepository(context: context)

        benchmark.startMeasurement()
        try blackHole(managedModel.object(managedId: objectId, in: context))
        try await blackHole(repository.read(objectId.uriRepresentation(), of: unmanagedModel).get())
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("Vanilla CoreData Fetch By ID, UUID ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_UuidId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let ids = try managedModel.objects(in: context, scale: scale).map(\.id)
        let id = ids.randomElement()!

        benchmark.startMeasurement()
        let fetchRequest = managedModel.fetchRequest()
        fetchRequest.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: managedModel.idKeyPath()),
            rightExpression: NSExpression(forConstantValue: id),
            modifier: .direct,
            type: .equalTo
        )
        try blackHole(managedModel.fetch(request: fetchRequest, in: context).first!)
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("Vanilla CoreData Fetch By ID, Int ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let ids = try managedModel.objects(in: context, scale: scale).map(\.id)
        let id = ids.randomElement()!

        benchmark.startMeasurement()
        let fetchRequest = ManagedModel_IntId.fetchRequest()
        fetchRequest.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: managedModel.idKeyPath()),
            rightExpression: NSExpression(forConstantValue: id),
            modifier: .direct,
            type: .equalTo
        )
        try blackHole(managedModel.fetch(request: fetchRequest, in: context).first!)
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Fetch By ID, Int ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let unmanagedModel = FetchableModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let ids = try managedModel.objects(in: context, scale: scale).map(\.id)
        let repository = CoreDataRepository(context: context)
        let id = ids.randomElement()!
        let fetchRequest = unmanagedModel.managedFetchRequest()
        fetchRequest.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: managedModel.idKeyPath()),
            rightExpression: NSExpression(forConstantValue: id),
            modifier: .direct,
            type: .equalTo
        )

        benchmark.startMeasurement()
        let result = await repository.fetch(fetchRequest, as: unmanagedModel)
        try blackHole(result.get().first!)
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Fetch By ID, UUID ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_UuidId.self
        let unmanagedModel = FetchableModel_UuidId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let ids = try managedModel.objects(in: context, scale: scale).map(\.id)
        let repository = CoreDataRepository(context: context)
        let id = ids.randomElement()!
        let fetchRequest = unmanagedModel.managedFetchRequest()
        fetchRequest.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: managedModel.idKeyPath()),
            rightExpression: NSExpression(forConstantValue: id),
            modifier: .direct,
            type: .equalTo
        )

        benchmark.startMeasurement()
        let result = await repository.fetch(fetchRequest, as: unmanagedModel)
        try blackHole(result.get().first!)
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("Vanilla CoreData Update By NSManagedObjectID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let objectIds = try managedModel.objects(in: context, scale: scale).map(\.objectID)
        let objectId = objectIds.randomElement()!

        benchmark.startMeasurement()
        let object = try managedModel.object(managedId: objectId, in: context)
        object.bool.toggle()
        try context.save()
        try context.parent?.save()
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Update By ID, UUID ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_UuidId.self
        let unmanagedModel = IdentifiableModel_UuidId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let items = try managedModel.objects(in: context, scale: scale).map(unmanagedModel.init(managed:))
        let repository = CoreDataRepository(context: context)
        var item = items.randomElement()!
        item.bool.toggle()

        benchmark.startMeasurement()
        try await blackHole(repository.update(with: item).get())
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Update By ID, Int ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let unmanagedModel = IdentifiableModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let items = try managedModel.objects(in: context, scale: scale).map(unmanagedModel.init(managed:))
        let repository = CoreDataRepository(context: context)
        var item = items.randomElement()!
        item.bool.toggle()

        benchmark.startMeasurement()
        try await blackHole(repository.update(with: item).get())
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Delete By ID, Int ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let unmanagedModel = IdentifiableModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let items = try managedModel.objects(in: context, scale: scale).map(unmanagedModel.init(managed:))
        let repository = CoreDataRepository(context: context)
        var item = items.randomElement()!
        item.bool.toggle()

        benchmark.startMeasurement()
        try await blackHole(repository.delete(item).get())
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("Vanilla CoreData Delete By NSManagedObjectID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let objects = try managedModel.objects(in: context, scale: scale)
        let object = objects.randomElement()!

        benchmark.startMeasurement()
        context.delete(object)
        try context.save()
        try context.parent?.save()
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("Vanilla CoreData Create", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let maxInt = try managedModel.objects(in: context, scale: scale).max(by: { $0.int < $1.int })!.int
        benchmark.startMeasurement()
        let newModel = managedModel.init(context: context)
        newModel.seeded(maxInt + 1)
        try context.save()
        try context.parent?.save()
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Create, Int ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_IntId.self
        let unmanagedModel = IdentifiableModel_IntId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let maxInt = try managedModel.objects(in: context, scale: scale).max(by: { $0.int < $1.int })!.int
        let repository = CoreDataRepository(context: context)
        let newItem = unmanagedModel.seeded(maxInt + 1)
        benchmark.startMeasurement()
        try await blackHole(repository.create(newItem).get())
        benchmark.stopMeasurement()

        try stack.destroy()
    }

    Benchmark("CoreDataRepository Create, UUID ID", configuration: .shared) { benchmark in
        let managedModel = ManagedModel_UuidId.self
        let unmanagedModel = IdentifiableModel_UuidId.self
        let scale = benchmark.configuration.scalingFactor.rawValue
        let stack = managedModel.stack()
        let context = stack.container.newBackgroundContext()
        let maxInt = try managedModel.objects(in: context, scale: scale).max(by: { $0.int < $1.int })!.int
        let repository = CoreDataRepository(context: context)
        let newItem = unmanagedModel.seeded(maxInt + 1)
        benchmark.startMeasurement()
        try await blackHole(repository.create(newItem).get())
        benchmark.stopMeasurement()

        try stack.destroy()
    }
}

extension NSManagedObjectContext {
    func setupForBenchmark_IntId(scale: Int) throws -> [ManagedModel_IntId] {
        let data: [[String: Any]] = (0 ..< scale).map { index in
            [
                "id": index,
                "bool": index.isMultiple(of: 2) ? true : false,
                "date": Date(timeIntervalSinceReferenceDate: TimeInterval(index)),
                "decimal": Decimal(index),
                "double": Double(exactly: index)!,
                "float": Float(exactly: index)!,
                "int": index,
                "string": index.description,
                "uuid": UUID(),
            ]
        }
        return try performAndWait {
            let insertRequest = NSBatchInsertRequest(entity: ManagedModel_IntId.entity(), objects: data)
            try execute(insertRequest)
            try save()
            try parent?.save()
            let fetchRequest = ManagedModel_IntId.fetchRequest()
            // swiftlint:disable:next force_cast
            return try fetch(fetchRequest) as! [ManagedModel_IntId]
        }
    }

    func setupForBenchmark_UuidId(scale: Int) throws -> [ManagedModel_UuidId] {
        let data: [[String: Any]] = (0 ..< scale).map { index in
            [
                "id": UUID(),
                "bool": index.isMultiple(of: 2) ? true : false,
                "date": Date(timeIntervalSinceReferenceDate: TimeInterval(index)),
                "decimal": Decimal(index),
                "double": Double(exactly: index)!,
                "float": Float(exactly: index)!,
                "int": index,
                "string": index.description,
                "uuid": UUID(),
            ]
        }
        return try performAndWait {
            let insertRequest = NSBatchInsertRequest(entity: ManagedModel_UuidId.entity(), objects: data)
            try execute(insertRequest)
            try save()
            try parent?.save()
            let fetchRequest = ManagedModel_UuidId.fetchRequest()
            // swiftlint:disable:next force_cast
            return try fetch(fetchRequest) as! [ManagedModel_UuidId]
        }
    }
}

extension ManagedModel_IntId {
    static func stack() -> CoreDataStack {
        CoreDataStack(
            storeName: "coredata_repository_benchmark",
            type: .sqliteEphemeral,
            container: CoreDataStack.persistentContainer(
                storeName: "coredata_repository_benchmark",
                type: .sqliteEphemeral,
                model: .model_IntId
            )
        )
    }

    static func objects(in context: NSManagedObjectContext, scale: Int) throws -> [ManagedModel_IntId] {
        try context.setupForBenchmark_IntId(scale: scale)
    }

    static func object(managedId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> Self {
        // swiftlint:disable:next force_cast
        try context.existingObject(with: managedId) as! Self
    }

    static func fetch(
        request: NSFetchRequest<ManagedModel_IntId>,
        in context: NSManagedObjectContext
    ) throws -> [ManagedModel_IntId] {
        try context.fetch(request)
    }

    static func fetch(
        request: NSFetchRequest<any NSFetchRequestResult>,
        in context: NSManagedObjectContext
    ) throws -> [ManagedModel_IntId] {
        // swiftlint:disable:next force_cast
        try context.fetch(request) as! [Self]
    }

    static func idKeyPath() -> KeyPath<ManagedModel_IntId, Int> {
        \.id
    }
}

extension ManagedModel_UuidId {
    static func stack() -> CoreDataStack {
        CoreDataStack(
            storeName: "coredata_repository_benchmark",
            type: .sqliteEphemeral,
            container: CoreDataStack.persistentContainer(
                storeName: "coredata_repository_benchmark",
                type: .sqliteEphemeral,
                model: .model_UuidId
            )
        )
    }

    static func objects(in context: NSManagedObjectContext, scale: Int) throws -> [ManagedModel_UuidId] {
        try context.setupForBenchmark_UuidId(scale: scale)
    }

    static func object(managedId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> Self {
        // swiftlint:disable:next force_cast
        try context.existingObject(with: managedId) as! Self
    }

    static func fetch(
        request: NSFetchRequest<ManagedModel_UuidId>,
        in context: NSManagedObjectContext
    ) throws -> [ManagedModel_UuidId] {
        try context.fetch(request)
    }

    static func fetch(
        request: NSFetchRequest<any NSFetchRequestResult>,
        in context: NSManagedObjectContext
    ) throws -> [ManagedModel_UuidId] {
        // swiftlint:disable:next force_cast
        try context.fetch(request) as! [Self]
    }

    static func idKeyPath() -> KeyPath<ManagedModel_UuidId, UUID> {
        \.id
    }
}

// swiftlint:enable file_length
