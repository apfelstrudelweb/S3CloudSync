//
//  Shell.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class S3CMD: NSObject {
    
    // in order to get this script working, disable Sandbox Capabilities in target!
    @discardableResult
    func execute(_ args: String) -> String {
        var outstr = ""
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", args]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            outstr = output as String
            print(outstr)
        }
        task.waitUntilExit()
        return outstr
    }
    
    func downloadRemoteJSON(to localPath: String) {
        execute("\(Constants.s3cmd) get s3://\(Constants.bucket)/\(Constants.jsonFilename) --force \(localPath)")
    }
    
    func uploadLocalJSON() {
        execute("\(Constants.s3cmd) put --mime-type=application/json \(Constants.localFilepath)/\(Constants.jsonFilename) s3://\(Constants.bucket)")
    }
    
    func uploadLocalAsset(_ filename: String) {
        
        let num = filename.components(separatedBy: "/").count
        let subdir = filename.components(separatedBy: "/")[num - 2]
        let mimetype = Utils().mimeTypeForPath(path: filename)
        
        execute("\(Constants.s3cmd) put --mime-type=\(mimetype) \(filename) s3://\(Constants.bucket)/\(subdir)/")
    }
    
    func uploadAllLocalAssets() {
        
        let paths = CoreDataManager.sharedInstance.getAllLocaleElementPaths()
        
        for path in paths {
            uploadLocalAsset(path)
        }
    }
    
    // returns array of strings such as "2018-10-24 19:13    921595   s3://visualbacktrainer/image/Barren.png"
    func getAllRemoteAssetsInfo() -> [String] {
        
        let result = execute("\(Constants.s3cmd) ls --preserve --recursive s3://\(Constants.bucket)")
        let fileArray = result.components(separatedBy: "\n")

        return fileArray.filter{ $0.belongsToAllowedAssetTypes() }
    }
    
}
