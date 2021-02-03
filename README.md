# CoreDataRepository
[![Build Status](https://travis-ci.com/roanutil/CoreDataRepository.svg?branch=main)](https://travis-ci.com/roanutil/CoreDataRepository) [![codecov](https://codecov.io/gh/roanutil/CoreDataRepository/branch/main/graph/badge.svg?token=WRO4CXYWRG)](https://codecov.io/gh/roanutil/CoreDataRepository) 

CoreDataRepository is a reactive library (Combine) for using CoreData on a background queue. It features endpoints for CRUD, batch, fetch multiple, and aggregate operations. Also, it offers a stream like subscription function for wrapping a fetch multiple call that will send updates that match the fetch request.

Since ```NSManagedObject```s are not thread safe, a value type model must exist for each ```NSMangaedObject``` subclass.


## Why the hell did you make this?
When I started learning more about application architecture, I ran into things like Clean Architecture that insist that the models, business logic, and views should be far away from platform specific frameworks. Your view should have no concern over the implementation details of persistence. When I compared that to how things are usually done on iOS, I noticed a big difference.

After some time passed I came across Composable Architecture which is a Swift library and seemingly meant for iOS. I was really confused how anybody could take it seriously since all of the app state is value types and the Apple frameworks are object oriented. Finally I found somebody discussing CoreData and ComposableArchitecture on the Swift Forums and they seemed to be mapping NSManagedObjects to structs which seemed insane but clever. After reading that, I did my best to suppress my inner rage at the inefficiency of it all and got to work.

The result is this library which in some form is actually used in production for my app. Going forward, when given the choice, I will always use this library rather than the old way. NSManagedObjects can be tricky. Fetching any real number of them on the main queue freezes the UI.

To give some weight to this idea, here's a quote from the Q&A portion of [this](https://academy.realm.io/posts/andy-matuschak-controlling-complexity/) talk by Andy Matuschak:

> Q: How do dependencies work out? It seems like the greatest value of using values is in the model layer, yet that’s the layer at which you have the most dependencies across the rest of your app, which is probably in Objective-C.

> Andy: In my experience, we had a CoreData stack, which is the opposite of isolation. Our strategy was putting a layer about the CoreData layer that would perform queries and return values. But where would we add functionality in the model layer? As far as using values in the view layer, we do a lot of that actually. We have a table view cell all the way down the stack that will render some icon and a label. The traditional thing to do would be to pass the ManagedObject for that content to the cell, but it doesn’t need that. There’s no reason to create this dependency between the cell and everything the model knows about, and so we make these lightweight little value types that the view needs. The owner of the view can populate that value type and give it to the view. We make these things called presenters that given some model can compute the view data. Then the thing which owns the presenter can pass the results into the view.


## Basic Usage

### Model Bridging
There are two protocols that handle bridging between the value type and managed models.

#### RepositoryManagedModel
```swift
@objc(RepoMovie)
final class RepoMovie: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var releaseDate: Date
    @NSManaged var boxOffice: NSDecimalNumber
}

extension RepoMovie: RepositoryManagedModel {
    var asUnmanaged: Movie {
        return Movie(
            id: id,
            title: title,
            releaseDate: releaseDate,
            boxOffice: boxOffice as Decimal,
            objectID: objectID
        )
    }

    func update(from unmanaged: Movie) {
        self.id = unmanaged.id
        self.title = unmanaged.title
        self.releaseDate = unmanaged.releaseDate
        self.boxOffice = unmanaged.boxOffice as NSDecimalNumber
    }

    static func fetchRequest() -> NSFetchRequest<RepoMovie> {
        NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
    }
}
```
#### UnmanagedModel
```swift
public struct Movie {
    public let id: UUID
    public var title: String = ""
    public var releaseDate: Date
    public var boxOffice: Decimal = 0
    public var objectID: NSManagedObjectID?
}

extension Movie: UnmanagedModel {
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
let result: AnyPublisher<Success, Failure> = repository.fetch(fetchRequest)
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
let result: AnyPublisher<Success, Failure> = repository.fetch(fetchRequest).subscription(repository)
...
cancellable.cancel()
```

### Aggregate
```swift
let result: AnyPublisher<Success<Decimal>, Failure> = repository.sum(
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


## TODO
- Add a subscription feature for aggregate functions


## Contributing
I welcome any feedback or contributions. I'm not eager to mess with the API a lot but let's be honest, it could probably be better. As always more tests wouldn't hurt.
