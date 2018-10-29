//
//  LibraryAPI.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 29.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

final class LibraryAPI: NSObject {

    static let shared = LibraryAPI()
    private let jsonHelper = JSONHelper()
    private let fileHelper = FileHelper()
    private let persistencyManager = PersistencyManager()
    private let cloudHandler = S3CMD()
    
    // MARK: cloud
    func downloadJSON() {
        // TODO: compare timestamps first
        cloudHandler.downloadRemoteJSON(to: Constants.localFilepath)
    }
    
    func uploadJSON() {
        cloudHandler.uploadLocalJSON()
    }
    
    func uploadAllUpdatedAssets() {
        
        let updatedElements = PersistencyManager.shared.getAllUpdatedElements()
        for element in updatedElements {
            cloudHandler.uploadLocalAsset(element)
        }
    }
    
    // Mark: filesystem to CoreData
    func mapLocalFileSystemToCoreData() {
        self.fileHelper.mapLocalFilesToCoreData()
    }
    
    // Mark: JSON to CoreData
    func mapJSONToCoreData() {
        self.jsonHelper.mapJSONToCoreData()
    }
    
    // Mark: CoreData
//    func updateCoreData() {
//        jsonHelper.mapJSONToCoreData {
//            self.fileHelper.mapLocalFilesToCoreData()
//        }
//    }
    
    func hasUpdatedAssets() -> Bool {
        return PersistencyManager.shared.getAllUpdatedElements().count > 0
    }
    
    // Mark: JSON
    func updateJSON() {
        jsonHelper.updateLocalJSON()
    }

}
