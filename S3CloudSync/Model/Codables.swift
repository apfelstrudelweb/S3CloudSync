//
//  Exercise.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 28.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa

class ElementDecodable: Decodable {
    
    let id: Int
    let alias: String
    let fileName: String
    let sha256_mp4: String
    let sha256_png: String
    let sha256_srt: String
}

extension Decodable {
    static func decode(data: Data) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: data)
    }
}

extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }
}
