//
//  Element+CoreDataClass.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Element)
public class Element: NSManagedObject {
    

    class func generateFromFileSystem(metadata: LocaleFileMetadata,
                                                        inContext context:NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Element.className())
        fetchRequest.predicate = NSPredicate(format: "\(PersistencyManager.predicateFileName) == %@", metadata.name)
        
        var elementCD: Element?
        var assetsCD: NSSet?
        
        do {
            
            if let fetchedElement = try (context.fetch(fetchRequest) as! [Element]).first {
                elementCD = fetchedElement
                assetsCD = elementCD?.assets
            } else {
                elementCD = Element(context: context)
                assetsCD = [Asset.init(type: AssetType.mp4.rawValue, context: context),
                            Asset.init(type: AssetType.png.rawValue, context: context),
                            Asset.init(type: AssetType.srt.rawValue, context: context)]
            }
            
            let assetMP4 = assetsCD?.first { ($0 as! Asset).type == AssetType.mp4.rawValue } as? Asset
            let assetPNG = assetsCD?.first { ($0 as! Asset).type == AssetType.png.rawValue } as? Asset
            let assetSRT = assetsCD?.first { ($0 as! Asset).type == AssetType.srt.rawValue } as? Asset
            
            if metadata.url.isMP4() {
                assetMP4?.local_sha256 = metadata.sha256
                assetMP4?.localeFilePath = metadata.url.path
                assetMP4?.size = metadata.size
                assetMP4?.modDate = metadata.date as NSDate
                assetMP4?.hasLocalChanges = false
            } else if metadata.url.isPNG() {
                assetPNG?.local_sha256 = metadata.sha256
                assetPNG?.localeFilePath = metadata.url.path
                assetPNG?.size = metadata.size
                assetPNG?.modDate = metadata.date as NSDate
                assetPNG?.hasLocalChanges = false
            } else if metadata.url.isSRT() {
                assetSRT?.local_sha256 = metadata.sha256
                assetSRT?.localeFilePath = metadata.url.path
                assetSRT?.size = metadata.size
                assetSRT?.modDate = metadata.date as NSDate
                assetSRT?.hasLocalChanges = false
            }
            
            
            elementCD?.fileName = metadata.name
            elementCD?.hasLocalChanges = false
            elementCD?.assets = assetsCD
            
            try context.save()
        } catch {
            print(error)
        }
        
    }
    
    class func generateFromJson(element: ElementDecodable,
                                            inContext context:NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.className())
        fetchRequest.predicate = NSPredicate(format: "\(PersistencyManager.predicateFileName) == %@", element.fileName)
        
        var elementCD: Element?
        var assetsCD: NSSet?
        
        do {
            
            if let fetchedElement = try (context.fetch(fetchRequest) as! [Element]).first {
                elementCD = fetchedElement
                assetsCD = elementCD?.assets
            } else {
                elementCD = Element(context: context)
                assetsCD = [Asset.init(type: AssetType.mp4.rawValue, context: context),
                            Asset.init(type: AssetType.png.rawValue, context: context),
                            Asset.init(type: AssetType.srt.rawValue, context: context)]
            }
            
            let assetMP4 = assetsCD?.first { ($0 as! Asset).type == AssetType.mp4.rawValue } as? Asset
            let assetPNG = assetsCD?.first { ($0 as! Asset).type == AssetType.png.rawValue } as? Asset
            let assetSRT = assetsCD?.first { ($0 as! Asset).type == AssetType.srt.rawValue } as? Asset
            
            assetMP4?.remote_sha256 = element.sha256_mp4
            assetPNG?.remote_sha256 = element.sha256_png
            assetSRT?.remote_sha256 = element.sha256_srt
            
            if assetMP4?.local_sha256 != element.sha256_mp4 {
                assetMP4?.hasLocalChanges = true
            }
            if assetPNG?.local_sha256 != element.sha256_png {
                assetPNG?.hasLocalChanges = true
            }
            if assetSRT?.local_sha256 != element.sha256_srt {
                assetSRT?.hasLocalChanges = true
            }
            
            elementCD?.id = Int64(element.id)
            elementCD?.alias = element.alias
            elementCD?.fileName = element.fileName
            elementCD?.hasLocalChanges = assetMP4?.hasLocalChanges ?? false || assetPNG?.hasLocalChanges ?? false  || assetSRT?.hasLocalChanges ?? false
            elementCD?.assets = assetsCD
            
            try context.save()
        } catch {
            print(error)
        }
        
    }
    
}
