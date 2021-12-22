// XCTestManifests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(AggregateRepositoryTests.allTests),
            testCase(BatchRepositoryTests.allTests),
            testCase(CRUDRepositoryTests.allTests),
            testCase(FetchRepositoryTests.allTests),
        ]
    }
#endif
