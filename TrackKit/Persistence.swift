//
//  Persistence.swift
//  Shared
//
//  Created by Ryan Gilbert on 2/10/22.
//

import CoreData

public struct PersistenceController {
    public static let shared = PersistenceController()

    public static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newItem = GPXTrackManaged(context: viewContext)
            newItem.date = Date()
            newItem.name = "Track \(i)"
            newItem.trackDescription = "The track description"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    public let container: NSPersistentCloudKitContainer

    public init(inMemory: Bool = false) {
        let storeURL = URL.storeURL(for: "group.org.ryangilbert.GPXer", databaseName: "GPXer")
        let localStore = NSPersistentStoreDescription(url: storeURL)
        
        let bundle = Bundle(identifier: "org.ryangilbert.TrackKit")!
        let model = NSManagedObjectModel(contentsOf: bundle.url(forResource: "GPXer", withExtension: "momd")!)
        container = NSPersistentCloudKitContainer(name: "GPXer", managedObjectModel: model!)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            container.persistentStoreDescriptions = [localStore]
        }
        container.loadPersistentStores(completionHandler: { [container] (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
    }
}
