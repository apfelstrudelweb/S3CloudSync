//
//  JSONHelper.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 25.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class JSONHelper: NSObject {
    
    let jsonPath = "\(Constants.localFilepath)/\(Constants.jsonFilename)"
    
    func mapJSONToCoreData(completion: @escaping () -> ())  {
        
        var jsonElements = [JSONElement]()
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath), options: .mappedIfSafe)
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any], let els = json![Constants.json_root_element] as? [[String: Any]] {
                
                for el in els {
                    if let element = JSONElement.init(json: el) {
                        jsonElements.append(element)
                    }
                }
            }
            
        } catch {
            // handle error
        }
        
        CoreDataManager.sharedInstance.insertOrUpdateElement(jsonElements)
        completion()
    }
    
    func updateLocalAndRemoteJSON() {
        
        let allElements = CoreDataManager.sharedInstance.getAllRemoteElements()
        let mp4s = allElements.filter { $0.type == Int(AssetType.mp4.rawValue) }
        let pngs = allElements.filter { $0.type == Int(AssetType.png.rawValue) }
        let srts = allElements.filter { $0.type == Int(AssetType.srt.rawValue) }
        
        DispatchQueue.main.async(execute: {
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: self.jsonPath), options: .mappedIfSafe)
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: [.mutableLeaves]) as? [String: Any], let videos = json![Constants.json_root_element] as? [[String: Any]] {
                    
                    var dict = [[String: Any]]()
                    dict = videos
                    
                    for (index, video) in dict.enumerated() {
                        if let asset = RemoteAsset.init(json: video) {
                            
                            if let name: String = asset.fileName {
                                
                                if let srt = srts.first(where: { $0.fileName == name }) {
                                    dict[index]["sha256_srt"] = srt.sha256
                                }
                                if let mp4 = mp4s.first(where: { $0.fileName == name }) {
                                    dict[index]["sha256_mp4"] = mp4.sha256
                                }
                                if let png = pngs.first(where: { $0.fileName == name }) {
                                    dict[index]["sha256_png"] = png.sha256
                                }
                            }
                        }
                    }
                    
                    var newJSON: [String: Any] = json!
                    newJSON[Constants.json_root_element] = dict
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: newJSON, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let file = try FileHandle(forWritingTo: URL(fileURLWithPath: self.jsonPath))
                    file.write((jsonData))
                    print("JSON data was written to the file successfully!")
                    S3CMD().uploadLocalJSON()
                }
                
            } catch {
                // handle error
            }
        })
    }
    
}

// it's a mixture of coredata and json -> maybe better creating two classes?
class RemoteAsset {
    
    var alias: String?
    var id: Int?
    var fileName: String?
    var sha256_mp4: String?
    var sha256_png: String?
    var sha256_srt: String?
    
    var modificationDate: Date?
    var size: Int?
    
    // from CoreData
    var type: Int?
    var sha256: String?
    
    init?(asset: Asset) {
        self.id = Int(asset.element!.id)
        self.type = Int(asset.type)
        self.sha256 = asset.remote_sha256
        self.fileName = asset.element?.fileName
    }
    
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
