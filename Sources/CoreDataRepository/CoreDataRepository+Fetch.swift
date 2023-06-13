// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CombineExt
import CoreData

extension CoreDataRepository {
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>) async
        -> Result<[Model], CoreDataRepositoryError>
    {
        await context.performInChild { fetchContext in
            try fetchContext.fetch(request).map(\.asUnmanaged)
        }
    }

    public func fetchSubscription<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.RepoManaged>,
        of _: Model.Type
    ) -> AsyncStream<Result<[Model], CoreDataRepositoryError>> {
        FetchSubscription(request: request, context: context.childContext()).stream()
    }

    public func fetchThrowingSubscription<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.RepoManaged>,
        of _: Model.Type
    ) -> AsyncThrowingStream<[Model], Error> {
        FetchSubscription(request: request, context: context.childContext()).throwingStream()
    }
}
