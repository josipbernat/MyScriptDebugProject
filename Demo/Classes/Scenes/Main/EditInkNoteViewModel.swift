//
//  EditInkNoteViewModel.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation
import MyScriptInteractiveInk_Runtime

struct EditInkNoteViewModel {
    
    var note: InkNote
    
    mutating func updateText(_ text: String?, editor: IINKEditor?, engine: IINKEngine) throws {
        guard let text = text else { return }
        
        note.text = text
        
        if let editor = editor {
            try note.importTextIntoEditor(text: text, editor: editor, engine: engine)
        }
    }
}
