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

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath), options: .mappedIfSafe)
            let json = try Array<ElementDecodable>.decode(data: data)
            _ = json.compactMap {
                Element.generateFromJsonDecodedModel(element: $0, inContext: CoreDataManager.sharedInstance.managedObjectContext)
            }
 
        } catch {
            print(error)
        }

        completion()
    }
    
    func updateLocalAndRemoteJSON() {
        
        do {
            let records = try CoreDataManager.sharedInstance.getAllRemoteElements()
            
            // Swift 4 has the advantage of the Encodable protocol
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(records)

            //let file = try FileHandle(forWritingTo: URL(fileURLWithPath: self.jsonPath))
            try jsonData.write(to: URL(fileURLWithPath: self.jsonPath), options: [])
            
            print("JSON data was written to the local file successfully!")
            S3CMD().uploadLocalJSON()
            
        } catch {
            print(error)
        }
    }
}
