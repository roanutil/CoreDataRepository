# CoreDataRepository
[![CI](https://github.com/roanutil/CoreDataRepository/actions/workflows/ci.yml/badge.svg)](https://github.com/roanutil/CoreDataRepository/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/roanutil/CoreDataRepository/branch/main/graph/badge.svg?token=WRO4CXYWRG)](https://codecov.io/gh/roanutil/CoreDataRepository) 
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Froanutil%2FCoreDataRepository%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/roanutil/CoreDataRepository)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Froanutil%2FCoreDataRepository%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/roanutil/CoreDataRepository)

CoreDataRepository is a reactive library (Combine) for using CoreData on a background queue. It features endpoints for CRUD, batch, fetch, and aggregate operations. Also, it offers a stream like subscription for fetch and read.

Since ```NSManagedObject```s are not thread safe, a value type model must exist for each ```NSMangaedObject``` subclass.


## Motivation

CoreData is a great framework for local persistence on Apple's platforms. However, it can be tempting to create strong dependencies on it throughout an app. Even worse, the `viewContext` runs on the main `DispatchQueue` along with the UI. Even fetching data from the store can be enough to cause performance problems.

The goals of `CoreDataRepository` are:
- Ease isolation of `CoreData` related code away from the rest of the app.
- Improve ergonomics by providing an asynchronous API with `Combine`.
- Improve usability of private contexts to relieve load from the main `DispatchQueue`.
- Make local persistence with `CoreData` feel more 'Swift-like' by allowing the model layer to use value types.

### Mapping `NSManagedObject`s to value types

It may feel convoluted to add this layer of abstraction over local persistence and the overhead of mapping between objects and value types. Similar to the motivation for only exposing views to the minimum data they need, why should the model layer be concerned with the details of the persistence layer? `NSManagedObject`s are complicated types that really should be isolated as much as possible.

To give some weight to this idea, here's a quote from the Q&A portion of [this](https://academy.realm.io/posts/andy-matuschak-controlling-complexity/) talk by Andy Matuschak:

> Q: How do dependencies work out? It seems like the greatest value of using values is in the model layer, yet that’s the layer at which you have the most dependencies across the rest of your app, which is probably in Objective-C.

> Andy: In my experience, we had a CoreData stack, which is the opposite of isolation. Our strategy was putting a layer about the CoreData layer that would perform queries and return values. But where would we add functionality in the model layer? As far as using values in the view layer, we do a lot of that actually. We have a table view cell all the way down the stack that will render some icon and a label. The traditional thing to do would be to pass the ManagedObject for that content to the cell, but it doesn’t need that. There’s no reason to create this dependency between the cell and everything the model knows about, and so we make these lightweight little value types that the view needs. The owner of the view can populate that value type and give it to the view. We make these things called presenters that given some model can compute the view data. Then the thing which owns the presenter can pass the results into the view.


## Basic Usage

### Model Bridging
There are two protocols that handle bridging between the value type and managed models.

#### RepositoryManagedModel
```swift
@objc(RepoMovie)
public final class RepoMovie: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var releaseDate: Date?
    @NSManaged var boxOffice: NSDecimalNumber?
}

extension RepoMovie: RepositoryManagedModel {
    public func create(from unmanaged: Movie) {
        update(from: unmanaged)
    }

    public typealias Unmanaged = Movie
    public var asUnmanaged: Movie {
        Movie(
            id: id ?? UUID(),
            title: title ?? "",
            releaseDate: releaseDate ?? Date(),
            boxOffice: (boxOffice ?? 0) as Decimal,
            url: objectID.uriRepresentation()
        )
    }

    public func update(from unmanaged: Movie) {
        id = unmanaged.id
        title = unmanaged.title
        releaseDate = unmanaged.releaseDate
        boxOffice = NSDecimalNumber(decimal: unmanaged.boxOffice)
    }

    static func fetchRequest() -> NSFetchRequest<RepoMovie> {
        let request = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        return request
    }
}
```
#### UnmanagedModel
```swift
public struct Movie: Hashable {
    public let id: UUID
    public var title: String = ""
    public var releaseDate: Date
    public var boxOffice: Decimal = 0
    public var url: URL?
}

extension Movie: UnmanagedModel {
    public var managedRepoUrl: URL? {
        get {
            url
        }
        set(newValue) {
            url = newValue
        }
    }

    public func asRepoManaged(in context: NSManagedObjectContext) -> RepoMovie {
        let object = RepoMovie(context: context)
        object.id = id
        object.title = title
        object.releaseDate = releaseDate
        object.boxOffice = boxOffice as NSDecimalNumber
        return object
    }
}
```

### CRUD
```swift
var movie = Movie(id: UUID(), title: "The Madagascar Penguins in a Christmas Caper", releaseDate: Date(), boxOffice: 100)
_ = repository.create(movie).subscribe(on: self.userInitSerialQueue)
    .receive(on: mainQueue)
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                os_log("Successfully created new movie")
            case .failure:
                fatalError("Failed to create new movie")
            }
        },
        receiveValue: { result in
            switch result {
            case .create(let resultMovie):
                os_log("Created movie with title - \(resultMovie.title)")
            default:
                fatalError("I asked for a create operation!")
            }
        }
    )
```
### Fetch
```swift
let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \RepoMovie.title, ascending: true)]
fetchRequest.predicate = NSPredicate(value: true)
let result: AnyPublisher<[Movie], Error> = repository.fetch(fetchRequest)
let cancellable = result.subscribe(on: userInitSerialQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    os_log("Fetched a bunch of moview")
                default:
                    fatalError("Failed to fetch all the movies!")
                }
        }, receiveValue: { value in
            os_log("Fetched \(value.items.count) movies")
        })
```
### Fetch Subscription
Similar to a regular fetch:
```swift
...
let result: AnyPublisher<[Movie], Error> = repository.fetchSubscription(fetchRequest)
...
cancellable.cancel()
```

### Aggregate
```swift
let result: AnyPublisher<[[String: Decimal]], Error> = repository.sum(
    predicate: NSPredicate(value: true),
    entityDesc: RepoMovie.entity(),
    attributeDesc: RepoMovie.entity().attributesByName.values.first(where: { $0.name == "boxOffice" })!
)
_ = result.subscribe(on: backgroundQueue)
    .receive(on: mainQueue)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            os_log("Finished getting the sum all the movies' boxOffice")
        default:
            fatalError("Failed to get the sum")
        }
    }, receiveValue: { value in
        os_log("The sum of all movies' boxOffice is \(value.result.first!.values.first!)")
    })
```

### Batch
```swift
let movies: [[String: Any]] = [
    ["id": UUID(), "title": "A", "releaseDate": Date()],
    ["id": UUID(), "title": "B", "releaseDate": Date()],
    ["id": UUID(), "title": "C", "releaseDate": Date()],
    ["id": UUID(), "title": "D", "releaseDate": Date()],
    ["id": UUID(), "title": "E", "releaseDate": Date()]
]
let request = NSBatchInsertRequest(entityName: RepoMovie.entity().name!, objects: movies)
_ = self.repository.insert(request)
    .subscribe(on: userInitSerialQueue)
    .receive(on: mainQueue)
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                os_log("Finished inserting A LOT of movies")
            default:
                fatalError("Failed to insert a lot of movies")
            }
        },
        receiveValue: { value in
            switch value {
            case let .insert(_, result):
                switch result.resultType {
                  case .count:
                    if let count = result.result as? Int {
                      os_log("Batch inserted \(count) movies!")
                    }
                  case .objectIDs:
                    if let objectIDs = result.result as? [NSManagedObjectID] {
                      os_log("Batch inserted \(objectIDs.count) movies!")
                    }
                  case .statusOnly:
                  let resultIsSuccessful = result.result as? Bool ?? false
                  os_log("Batch insert - isSuccessful = \(resultIsSuccessful)")
                }
            default:
                fatalError("I asked for a batch INSERT!")
            }
        }
    )
```

#### OR

```swift
let movies: [[String: Any]] = [
    Movie(id: UUID(), title: "A", releaseDate: Date()),
    Movie(id: UUID(), title: "B", releaseDate: Date()),
    Movie(id: UUID(), title: "C", releaseDate: Date()),
    Movie(id: UUID(), title: "D", releaseDate: Date()),
    Movie(id: UUID(), title: "E", releaseDate: Date())
]
let publisher: AnyPublisher<(success: [Movie], failed: [Movie]), Never> = repository.create(movies)
_ = publisher
    .subscribe(on: backgroundQueue)
    .receive(on: mainQueue)
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                os_log("Finished inserting A LOT of movies")
            default:
                fatalError("Failed to insert a lot of movies")
            }
        },
        receiveValue: { createdMovies in
            os_log("Created these movies: \(createdMovies)")
        }
    )_
```


## TODO
- Add a subscription feature for aggregate functions


## Contributing
I welcome any feedback or contributions. It's probably best to create an issue where any possible changes can be discussed before doing the work and creating a PR.
