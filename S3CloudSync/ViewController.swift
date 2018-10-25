//
//  ViewController.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 23.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {
    
    let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
    
    let s3cmd = S3CMD()

    var assetsToUploadDict = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //CoreDataManager.sharedInstance.clearDB()
        
        // TODO: perfom initial upload from JSON with inital sha256 values from locale filesystem -> maybe generate JSON automatically
        
        // get actual JSON from Cloud
        s3cmd.downloadRemoteJSON(to: Constants.localFilepath)

        JSONHelper().mapJSONToCoreData {
            FileHelper().mapLocalFilesToCoreData()
        }
        
        let updatedElements = CoreDataManager.sharedInstance.getAllUpdatedElements()
        print("number of updated elements: \(updatedElements.count)")
        
        for element in updatedElements {
            s3cmd.uploadLocalAsset(element)
        }
        
        CoreDataManager.sharedInstance.syncAllRemoteSha256 {
            JSONHelper().updateJSON()
        }
        

 
        //s3cmd.uploadAllLocalAssets()

    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}
