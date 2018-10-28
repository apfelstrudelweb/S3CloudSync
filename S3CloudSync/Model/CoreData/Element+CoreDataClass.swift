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
    
    class func generateFromJsonDecodedModel(element: ElementDecodable,
                                            inContext context:NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.className())
        fetchRequest.predicate = NSPredicate(format: "fileName == %@", element.fileName)
        
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
            
            elementCD?.id = Int64(element.id)
            elementCD?.alias = element.alias
            elementCD?.fileName = element.fileName
            elementCD?.hasLocalChanges = false
            elementCD?.assets = assetsCD
            
            try context.save()
        } catch {
            print(error)
        }
        
    }
    
}
