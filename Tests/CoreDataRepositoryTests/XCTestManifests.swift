import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AggregateRepositoryTests.allTests),
        testCase(BatchRepositoryTests.allTests),
        testCase(CRUDRepositoryTests.allTests),
        testCase(FetchRepositoryTests.allTests)
    ]
}
#endif
