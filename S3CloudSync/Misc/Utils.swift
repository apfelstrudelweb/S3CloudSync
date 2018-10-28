//
//  Utils.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class Utils: NSObject {
    
    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

public extension URL {
    
    func isPNG() -> Bool {
        return self.absoluteString.contains(".png")
    }
    func isMP4() -> Bool {
        return self.absoluteString.contains(".mp4")
    }
    func isSRT() -> Bool {
        return self.absoluteString.contains(".srt")
    }
}

public extension String {
    
    func removeExtension() -> String{
        if self.contains(".") {
            return self.components(separatedBy: ".").first!
        }
        return self
    }
    
    func belongsToAllowedAssetTypes() -> Bool {
        for type in Constants.allowedAssetTypes {
            if self.contains(type) {
                return true
            }
        }
        return false
    }
    
    func timestamp() -> [String] {
        if let regex = try? NSRegularExpression(pattern: "[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]) (2[0-3]|[01][0-9]):[0-5][0-9]", options: .caseInsensitive) {
            let string = self as NSString
            
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range)
            }
        }
        
        return []
    }
    
    func filesize() -> [String] {
        if let regex = try? NSRegularExpression(pattern: "\\s\\d+\\s", options: .caseInsensitive) {
            let string = self as NSString
            
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return []
    }
    
    func resource() -> [String] {
        if let regex = try? NSRegularExpression(pattern: "(s3)://(.*)", options: .caseInsensitive) {
            let string = self as NSString
            
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range)
            }
        }
        
        return []
    }
}
