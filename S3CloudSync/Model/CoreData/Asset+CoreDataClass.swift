//
//  Asset+CoreDataClass.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Asset)
public class Asset: NSManagedObject {
    
    convenience init(type: Int16, context: NSManagedObjectContext) {
        self.init(context: context)
        self.type = type
    }

}
