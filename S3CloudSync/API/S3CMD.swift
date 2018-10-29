//
//  Shell.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class S3CMD: NSObject {
    
    var output: FileHandle!
    var task: Process!
    
    // in order to get this script working, disable Sandbox Capabilities in target!
    @discardableResult
    func execute(_ args: String) -> String {
        
        var outstr = ""
        task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", args]
        let pipe = Pipe()
        task.standardOutput = pipe

//        output = pipe.fileHandleForReading
//
//        NotificationCenter.default.addObserver(self, selector: #selector(notifiedForOutput(_:)), name: FileHandle.readCompletionNotification, object: output)
//        NotificationCenter.default.addObserver(self, selector: #selector(notifiedForComplete(_:)), name: Process.didTerminateNotification, object: task)
//        output.readInBackgroundAndNotify()
        
        
        task.launch()
        print(task.processIdentifier)

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            outstr = output as String
            print(outstr)
        }
        task.waitUntilExit()

        return outstr
    }
    
    @objc func notifiedForComplete(_ notification:Notification) {
        //task.suspend()
    }
    
    @objc func notifiedForOutput(_ notification:Notification) {
        
        if let info = notification.userInfo as? Dictionary<String, Any> {
            // Check if value present before using it
            if let data = info[NSFileHandleNotificationDataItem] as? Data {
                print(data.count)
            }
            else {
                print("no value for key\n")
            }
        }
        else {
            print("wrong userInfo type")
        }

        if task.isRunning == true {
            output.readInBackgroundAndNotify()
        }

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
        
        let paths = PersistencyManager.shared.getAllLocaleElementPaths()
        
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
