//
//  Element+CoreDataProperties.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Element {
    
    private enum CodingKeys: String, CodingKey { case id, alias, fileName, sha256_mp4, sha256_png, sha256_srt }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Element> {
        return NSFetchRequest<Element>(entityName: self.className())
    }

    @NSManaged public var alias: String?
    @NSManaged public var fileName: String?
    @NSManaged public var id: Int64
    @NSManaged public var hasLocalChanges: Bool
    @NSManaged public var assets: NSSet?

}

// MARK: Generated accessors for assets
extension Element {

    @objc(addAssetsObject:)
    @NSManaged public func addToAssets(_ value: Asset)

    @objc(removeAssetsObject:)
    @NSManaged public func removeFromAssets(_ value: Asset)

    @objc(addAssets:)
    @NSManaged public func addToAssets(_ values: NSSet)

    @objc(removeAssets:)
    @NSManaged public func removeFromAssets(_ values: NSSet)

}


extension Element: Encodable {

    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(alias, forKey: .alias)
        try container.encodeIfPresent(fileName, forKey: .fileName)
        
        try assets?.compactMap({ $0 as? Asset }).forEach {
            if $0.type == AssetType.mp4.rawValue {
                try container.encodeIfPresent($0.remote_sha256, forKey: .sha256_mp4)
            } else if $0.type == AssetType.png.rawValue {
                try container.encodeIfPresent($0.remote_sha256, forKey: .sha256_png)
            } else if $0.type == AssetType.srt.rawValue {
                try container.encodeIfPresent($0.remote_sha256, forKey: .sha256_srt)
            }
        }
    }
    
}
