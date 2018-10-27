//
//  Asset.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class JSONElement: NSObject {
    
    // get from JSON
    var alias: String?
    var id: Int?
    var fileName: String?
    var sha256_mp4: String?
    var sha256_png: String?
    var sha256_srt: String?
    
    // get from s3cmd request
    var size_mp4: Int?
    var size_png: Int?
    var size_srt: Int?
    // get from s3cmd request
    var modDate_mp4: Date?
    var modDate_png: Date?
    var modDate_srt: Date?
    
    var modificationDate: Date?
    var size: Int?
    
    init?(json: [String: Any]) {
        
        guard let alias = json["alias"] as? String,
            let id = json["id"] as? Int,
            let fileName = json["fileName"] as? String,
            let sha256_mp4 = json["sha256_mp4"] as? String,
            let sha256_png = json["sha256_png"] as? String,
            let sha256_srt = json["sha256_srt"] as? String
            else {
                return nil
        }
        
        self.alias = alias
        self.id = id
        self.fileName = fileName
        self.sha256_mp4 = sha256_mp4
        self.sha256_png = sha256_png
        self.sha256_srt = sha256_srt
    }
}
