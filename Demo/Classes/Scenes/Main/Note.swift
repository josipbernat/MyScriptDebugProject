//
//  Note.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation

class Note: InkNote {
    
    var id: String
    var text: String?
    var inkFilePath: String

    init(id: String, text: String? = nil, inkFilePath: String) {
        self.id = id
        self.text = text
        self.inkFilePath = inkFilePath
    }
}
