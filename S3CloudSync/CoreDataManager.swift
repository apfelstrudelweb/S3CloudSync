//
//  CoreDataManager.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class CoreDataManager: NSObject {
    
    static let sharedInstance = CoreDataManager()
    static let entityElement = "Element"
    static let entityAsset = "Asset"
    
    func insertOrUpdateElement(_ elements: ([JSONElement])) {
        
        for element in elements {
            
            guard let filename = element.fileName else { continue }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityElement)
            fetchRequest.predicate = NSPredicate(format: "fileName == %@", filename)
            
            var elementCD: Element!
            var assetMP4: Asset!
            var assetPNG: Asset!
            var assetSRT: Asset!
            
            do {
                
                if let fetchedElement = try (self.managedObjectContext.fetch(fetchRequest) as! [Element]).first {
                    elementCD = fetchedElement
                } else {
                    elementCD = (NSEntityDescription.insertNewObject(forEntityName: CoreDataManager.entityElement, into: self.managedObjectContext) as! Element)
                }
                
                if elementCD?.assets?.count ?? 0 == 0 {
                    assetMP4 = (NSEntityDescription.insertNewObject(forEntityName: CoreDataManager.entityAsset, into: self.managedObjectContext) as! Asset)
                    assetPNG = (NSEntityDescription.insertNewObject(forEntityName: CoreDataManager.entityAsset, into: self.managedObjectContext) as! Asset)
                    assetSRT = (NSEntityDescription.insertNewObject(forEntityName: CoreDataManager.entityAsset, into: self.managedObjectContext) as! Asset)
                    elementCD.addToAssets(assetMP4)
                    elementCD.addToAssets(assetPNG)
                    elementCD.addToAssets(assetSRT)
                } else {
                    assetMP4 = elementCD.assets?.first { ($0 as! Asset).type == AssetType.mp4.rawValue } as? Asset
                    assetPNG = elementCD.assets?.first { ($0 as! Asset).type == AssetType.png.rawValue } as? Asset
                    assetSRT = elementCD.assets?.first { ($0 as! Asset).type == AssetType.srt.rawValue } as? Asset
                }
                
                assetMP4.type = AssetType.mp4.rawValue
                assetPNG.type = AssetType.png.rawValue
                assetSRT.type = AssetType.srt.rawValue
                
                assetMP4.hasLocalChanges = false
                assetPNG.hasLocalChanges = false
                assetSRT.hasLocalChanges = false

                
                elementCD?.alias = element.alias
                elementCD?.id = Int64(element.id ?? -1)
                elementCD?.fileName = element.fileName
                elementCD?.hasLocalChanges = false // will be set later after parsing the local file system
                
                try self.managedObjectContext.save()
                
            } catch {
                print("video \(filename) could not be fetched")
            }
        }
    }
    
    func updateElementWithLocaleData( _ metadata: LocaleFileMetadata) {

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityElement)
        fetchRequest.predicate = NSPredicate(format: "fileName == %@", metadata.name)
        
        do {
            // only upddate elements which are already registered in JSON and thus in CoreData
            if let fetchedElement = try (self.managedObjectContext.fetch(fetchRequest) as! [Element]).first {
                
                var asset: Asset?
                // TODO: don't forget to reset the flag "hasLocalChanges" before uploading the new JSON file
                if metadata.url.isMP4() {
                    asset = fetchedElement.assets?.first { ($0 as! Asset).type == AssetType.mp4.rawValue } as? Asset
                } else if metadata.url.isPNG() {
                    asset = fetchedElement.assets?.first { ($0 as! Asset).type == AssetType.png.rawValue } as? Asset
                } else if metadata.url.isSRT() {
                    asset = fetchedElement.assets?.first { ($0 as! Asset).type == AssetType.srt.rawValue } as? Asset
                } else {
                    return
                }
                
                if metadata.url.path.contains("Seitbeugen.srt") {
                    print(metadata.name)
                }
                
                asset?.localeFilePath = metadata.url.path
                asset?.local_sha256 =  metadata.sha256
                
                // for the first time - JSON does not contain sha256 values
                if asset?.remote_sha256 == nil {
                    asset?.remote_sha256 = metadata.sha256
                }
                asset?.size = metadata.size
                asset?.modDate = metadata.date as NSDate
                //asset?.hasLocalChanges = asset?.remote_sha256 != asset?.local_sha256
                
                if !(asset?.remote_sha256?.elementsEqual(metadata.sha256))! {
                    //fetchedElement.hasLocalChanges = true
                    asset?.hasLocalChanges = true
                }
            }

            try self.managedObjectContext.save()

        } catch {
            print("video \(metadata.name) could not be fetched")
        }
    }
    
    func getAllUpdatedElements() -> [String] {
        
        var changedElements = [String]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        fetchRequest.predicate = NSPredicate(format: "hasLocalChanges == 1")
        
        do {
            if let fetchedAssets = try (self.managedObjectContext.fetch(fetchRequest) as? [Asset]) {
                
                for asset in fetchedAssets {
                    changedElements.append(asset.localeFilePath ?? "")
                }
            }
        } catch {
            print("changed assets could not be fetched")
        }
        
        return changedElements
    }
    
    func getAllLocaleElementPaths() -> [String] {
        
        var allElements = [String]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        
        do {
            if let fetchedAssets = try (self.managedObjectContext.fetch(fetchRequest) as? [Asset]) {
                
                for asset in fetchedAssets {
                    allElements.append(asset.localeFilePath!)
                }
            }
        } catch {
            print("changed assets could not be fetched")
        }
        
        return allElements
    }
    
    func getAllRemoteElements() -> [RemoteAsset] {
        
        var allElements = [RemoteAsset]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        
        do {
            if let fetchedAssets = try (self.managedObjectContext.fetch(fetchRequest) as? [Asset]) {
                
                for asset in fetchedAssets {
                    
                    let remoteAsset = RemoteAsset.init(asset: asset)
                    allElements.append(remoteAsset!)
                }
            }
        } catch {
            print("changed assets could not be fetched")
        }
        
        return allElements
    }
    
    func getLocalSha256FromFile(localeFilePath: String) -> String {
        
        var sha256: String! = ""
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        fetchRequest.predicate = NSPredicate(format: "localeFilePath == %@", localeFilePath)
        
        do {
            if let fetchedAsset = try (self.managedObjectContext.fetch(fetchRequest) as? [Asset])?.first {
                sha256 = fetchedAsset.local_sha256
            }
        } catch {
            print("changed assets could not be fetched")
        }
        
        return sha256
    }
    
    func syncAllRemoteSha256(completion: @escaping () -> ()) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        fetchRequest.predicate = NSPredicate(format: "hasLocalChanges == 1")
        
        do {
            if let fetchedAssets = try (self.managedObjectContext.fetch(fetchRequest) as? [Asset]) {
                
                for asset in fetchedAssets {
                    asset.remote_sha256 = asset.local_sha256
                    asset.hasLocalChanges = false
                }
                try self.managedObjectContext.save()
            }
        } catch {
            print("changed assets could not be fetched")
        }
        completion()
    }
    
    func syncRemoteSha256FromFile(localeFilePath: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        fetchRequest.predicate = NSPredicate(format: "localeFilePath == %@", localeFilePath)
        
        do {
            if let fetchedAsset = try (self.managedObjectContext.fetch(fetchRequest) as? [Asset])?.first {
                fetchedAsset.remote_sha256 = fetchedAsset.local_sha256
                fetchedAsset.hasLocalChanges = false
                try self.managedObjectContext.save()
            }
        } catch {
            print("changed assets could not be fetched")
        }
    }
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func clearDB() {
        
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityElement)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                managedObjectContext.delete(objectData)
                try managedObjectContext.save()
            }
        } catch let error {
            print("Detele all data error :", error)
        }
        
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataManager.entityAsset)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                managedObjectContext.delete(objectData)
                try managedObjectContext.save()
            }
        } catch let error {
            print("Detele all data error :", error)
        }
    }

    // MARK: - Core Data stack
    
    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.andrewcbancroft.Zootastic" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "S3CloudSync", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        //        let url = self.applicationDocumentsDirectory.appendingPathComponent("Trainingsplan.sqlite")
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let storeURL = url?.appendingPathComponent("S3CloudSync.sqlite")
        
        print("SQLite in \(String(describing: storeURL))")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let options = [NSInferMappingModelAutomaticallyOption:true,
                           NSMigratePersistentStoresAutomaticallyOption:true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .terminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}
