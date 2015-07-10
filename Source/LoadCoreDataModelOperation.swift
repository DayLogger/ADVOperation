/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file contains the code to create the Core Data stack.
*/

import CoreData

struct CoreDataModelConfiguration {
    /// The folder in which the store will be created
    var folder: NSURL = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

    /// The name of the store file
    var modelName: String

    /// The bundle that contains the model to load
    var modelBundle = NSBundle(forClass: LoadCoreDataModelOperation.self)

    /// Whether an existing store should be destroyed before creating the new one
    var shouldReset = false

    /// If creating a new store fails, indicate whether we're allowed to destroy it and try again
    var shouldResetAfterFailure = true

    /// Any options to be passed when creating the store
    var options = Dictionary<NSObject, AnyObject>()

    init(modelName: String) {
        self.modelName = modelName
    }
}

class LoadCoreDataModelOperation: Operation {
    let loadHandler: NSManagedObjectContext -> Void
    let configuration: CoreDataModelConfiguration

    // MARK: Initialization

    init(configuration: CoreDataModelConfiguration, loadHandler: NSManagedObjectContext -> Void) {
        self.configuration = configuration
        self.loadHandler = loadHandler

        super.init()

        // We only want one of these going at a time.
        addCondition(MutuallyExclusive<LoadCoreDataModelOperation>())
    }

    override func execute() {
        let storeURL = configuration.folder.URLByAppendingPathComponent(configuration.modelName)

        let model = NSManagedObjectModel.mergedModelFromBundles([configuration.modelBundle])!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator

        if configuration.shouldReset {
            // we want to destroy the store, if it exists
            destroyStore(persistentStoreCoordinator, atURL: storeURL, options: configuration.options)
        }

        var error = createStore(persistentStoreCoordinator, atURL: storeURL, options: configuration.options)

        if persistentStoreCoordinator.persistentStores.isEmpty && configuration.shouldResetAfterFailure {
            // we failed to add a store, and we're allowed to reset it, so try again
            destroyStore(persistentStoreCoordinator, atURL: storeURL, options: configuration.options)
            error = createStore(persistentStoreCoordinator, atURL: storeURL, options: configuration.options)
        }

        if persistentStoreCoordinator.persistentStores.isEmpty {
            NSLog("Error creating SQLite store: \(error).")
            NSLog("Falling back to `.InMemory` store.")
            error = createStore(persistentStoreCoordinator, atURL: nil, type: NSInMemoryStoreType, options: configuration.options)
        }

        if !persistentStoreCoordinator.persistentStores.isEmpty {
            loadHandler(context)
            error = nil
        }

        finishWithError(error)
    }

    private func createStore(persistentStoreCoordinator: NSPersistentStoreCoordinator, atURL URL: NSURL?, type: String = NSSQLiteStoreType, options: Dictionary<NSObject, AnyObject>) -> NSError? {
        var error: NSError?
        do {
            let _ = try persistentStoreCoordinator.addPersistentStoreWithType(type, configuration: nil, URL: URL, options: options)
        }
        catch let storeError as NSError {
            error = storeError
        }

        return error
    }

    private func destroyStore(persistentStoreCoordinator: NSPersistentStoreCoordinator, atURL URL: NSURL, type: String = NSSQLiteStoreType, options: Dictionary<NSObject, AnyObject>) {
        do {
            let _ = try persistentStoreCoordinator.destroyPersistentStoreAtURL(URL, withType: type, options: options)
        }
        catch { }
    }
}
