//
//  Asset+CoreDataProperties.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Asset { //} : Encodable {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Asset> {
        return NSFetchRequest<Asset>(entityName: Asset.className())
    }

    @NSManaged public var type: Int16
    @NSManaged public var size: Int64
    @NSManaged public var modDate: NSDate?
    @NSManaged public var local_sha256: String?
    @NSManaged public var remote_sha256: String?
    @NSManaged public var hasLocalChanges: Bool
    @NSManaged public var localeFilePath: String?
    @NSManaged public var element: Element?

}
