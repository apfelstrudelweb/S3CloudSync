//
//  FileHelper.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa
import CommonCrypto


public struct LocaleFileMetadata: CustomDebugStringConvertible, Equatable {
    
    let name: String
    let date: Date
    let size: Int64
    let color: NSColor
    let url: URL
    let sha256: String
    
    init(fileURL: URL, name: String, date: Date, size: Int64, color: NSColor, sha256: String) {
        self.name = name
        self.date = date
        self.size = size
        self.color = color
        self.url = fileURL
        self.sha256 = sha256
    }
    
    public var debugDescription: String {
        return name + " " + " Size: \(size)"
    }
    
}


// MARK:  Metadata  Equatable

public func ==(lhs: LocaleFileMetadata, rhs: LocaleFileMetadata) -> Bool {
    return (lhs.url == rhs.url)
}


public struct LocalFiles  {
    
    let url: URL
    
    var totalSize: Int64 = 0
    
    public enum FileOrder: String {
        case Name
        case Date
        case Size
    }
    
    public init() {
        let url = URL(fileURLWithPath: Constants.localFilepath)
        self.init(folderURL: url)
    }
    
    public init(folderURL: URL) {
        url = folderURL
        print(url.path)
        let requiredAttributes = [URLResourceKey.localizedNameKey, URLResourceKey.effectiveIconKey,
                                  URLResourceKey.typeIdentifierKey, URLResourceKey.contentModificationDateKey,
                                  URLResourceKey.fileSizeKey, URLResourceKey.isDirectoryKey,
                                  URLResourceKey.isPackageKey]
        
        parseFolder(folderURL, requiredAttributes){ (totalsize) in
            print("mainfolder parsed: \(totalsize)")
        }
    }
    
    fileprivate mutating func parseFolder(_ folderURL: URL, _ requiredAttributes: [URLResourceKey], completion: @escaping (Int64) -> ()) {
        
        var result =  self
        
        if let enumerator = FileManager.default.enumerator(at: folderURL,
                                                           includingPropertiesForKeys: requiredAttributes,
                                                           options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants],
                                                           errorHandler: nil) {
            
            while let url = enumerator.nextObject() as? URL {
                //print("\(url)")
                
                do {
                    let properties = try  (url as NSURL).resourceValues(forKeys: requiredAttributes)
                    
                    let isFolder = (properties[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue ?? false
                    
                    if isFolder == true {
                        self.parseFolder(url, requiredAttributes) { (_) in
                            print("subfolder parsed")
                        }
                    } else {
                        
                        let fileExtension = ".".appending(url.pathExtension)
                        if Constants.allowedAssetTypes.contains(fileExtension) == false { continue }

                        var sha256: String? {
                            
                            do {
                                let data = try Data(contentsOf: url)
                                let hash = data.withUnsafeBytes { (bytes: UnsafePointer<Data>) -> [UInt8] in
                                    var hash: [UInt8] = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                                    CC_SHA256(bytes, CC_LONG(data.count), &hash)
                                    return hash
                                }
                                return hash.map { String(format: "%02x", $0) }.joined()
                            } catch {
                                print(error)
                                return ""
                            }
                        }
                        
                        let filename = properties[URLResourceKey.localizedNameKey] as? String ?? ""

                        let metadata = LocaleFileMetadata(fileURL: url,
                                                name: filename.removeExtension(),
                                                date: properties[URLResourceKey.contentModificationDateKey] as? Date ?? Date.distantPast,
                                                size: (properties[URLResourceKey.fileSizeKey] as? NSNumber)?.int64Value ?? 0,
                                                color: NSColor(), sha256: sha256 ?? "-- not available --")
                        
                        CoreDataManager.sharedInstance.updateElementWithLocaleData(metadata)
                        
                        totalSize = totalSize + ((properties[URLResourceKey.fileSizeKey] as? NSNumber)?.int64Value)!
                        
                        NotificationCenter.default.post(name:Notification.Name(rawValue: "FileUpdateNotification"),
                                                        object: nil,
                                                        userInfo: ["totalsize": totalSize, "directory": self])
                    }
                }
                catch {
                    print("Error reading file attributes")
                }
            }
        }
        completion(totalSize)
    }
}

class FileHelper: NSObject {
    
    public enum FileOrder: String {
        case Name
        case Date
        case Size
    }
    
    func mapLocalFilesToCoreData() {
        let dir = LocalFiles(folderURL: URL(fileURLWithPath: "\(Constants.localFilepath)/"))
        print(dir)
    }

}
