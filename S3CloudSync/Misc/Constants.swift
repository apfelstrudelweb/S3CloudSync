//
//  Constants.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

enum AssetType: Int16 {
    case mp4 = 1
    case png = 2
    case srt = 3
}

class Constants: NSObject {
    
    // TODO: user must select path
    static let localFilepath = "/Users/ulrich/VideoProjekt/Amazon_S3"
    
    static let bucket = "visualbacktrainer"
    static let s3cmd = "/usr/local/bin/s3cmd"
    
    static let allowedAssetTypes = [".png", ".mp4", ".srt"]
    static let jsonFilename = "videos.json"
    static let json_root_element = "videos"
}
