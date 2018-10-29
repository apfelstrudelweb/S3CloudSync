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
    
    func mapJSONToCoreData()  {

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath), options: .mappedIfSafe)
            let json = try Array<ElementDecodable>.decode(data: data)
            _ = json.compactMap {
                Element.generateFromJson(element: $0, inContext: PersistencyManager.shared.managedObjectContext)
            }
 
        } catch {
            print(error)
        }
    }
    
    func updateLocalJSON() {
        
        do {
            let records = try PersistencyManager.shared.getAllRemoteElements()
            
            // Swift 4 has the advantage of the Encodable protocol
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(records)

            //let file = try FileHandle(forWritingTo: URL(fileURLWithPath: self.jsonPath))
            try jsonData.write(to: URL(fileURLWithPath: self.jsonPath), options: [])
            
            print("JSON data was written to the local file successfully!")
            //S3CMD().uploadLocalJSON()
            
        } catch {
            print(error)
        }
    }
}
