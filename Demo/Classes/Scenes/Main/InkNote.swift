//
//  InkNote.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation

protocol InkNote {

    var id: String { get }
    var text: String? { get set }
    var inkFilePath: String { get }
}

extension InkNote {
        
    static var tempInkFilePath: String {
        FileManager.default.pathForFileInDocumentDirectory(fileName: "tempNote") + ".iink"
    }

    func importPredefinedTextIntoEditorIfNeeded(_ editor: IINKEditor?, text: String, engine: IINKEngine) throws {

        guard let editor = editor else {
            return
        }
        try importTextIntoEditor(text: text, editor: editor, engine: engine)
    }
    
    func loadIntoEditor(editor: IINKEditor, engine: IINKEngine) throws {
        
        guard let package = try type(of: self).loadPackage(from: inkFilePath, using: engine) else {
            return
        }
        
        let part = try package.part(at: 0)
        try editor.set(part: part)
    }
    
    func importTextIntoEditor(text: String, editor: IINKEditor, engine: IINKEngine) throws {
        
//        if doesInkFileExists == false {
//            // Maybe user used keyboard before even using INK. Editor will create file for us.
//            try loadIntoEditor(editor: editor)
//        }
        
        if text.isEmpty {
            /// @see https://developer-support.myscript.com/support/discussions/topics/16000032250
            
            if doesInkFileExists {
                try eraseInkFile(editor: editor, engine: engine)
            }
            
        } else {
            /// @see https://developer.myscript.com/docs/interactive-ink/2.0/ios/fundamentals/import-and-export/
            
            if let rootBlock = editor.rootBlock {
                try editor.import(mimeType: .text, data: text, selection: rootBlock)
            } else {
                
                let _ = try Self.loadPackage(from: inkFilePath, using: engine)
                try editor.import(mimeType: .text, data: text, selection: nil)
            }
            
            try editor.saveAll()
        }
    }
    
    func eraseInkFile(editor: IINKEditor?, engine: IINKEngine) throws {
                
        if let editor = editor {
            editor.clear()
            try editor.saveAll()
        } else {
         
            guard doesInkFileExists else {
                return
            }

            guard let package = try Self.loadPackage(from: inkFilePath, using: engine) else {
                fatalError()
            }

            let part = try package.part(at: 0)
            try package.removePart(part)

//            if package.partCount() == 0 {
//                try package.createPart(with: "Text")
//            }

            try package.save()
        }
    }
    
    func deleteInkFile(editor: IINKEditor?, engine: IINKEngine) throws {
        
        guard doesInkFileExists else {
            return
        }
                
        try eraseInkFile(editor: editor, engine: engine)
        try FileManager.default.removeItem(atPath: inkFilePath)
    }
}

extension InkNote {
    
    //MARK: - Ink Loading
    // This was previously global func which I them moved here because I think we should
    // generally avoid having global functions.
    static func loadPackage(from path: String, using engine: IINKEngine) throws -> IINKContentPackage? {
        
        var resultPackage: IINKContentPackage?
        resultPackage = try engine.openPackage(path.decomposedStringWithCanonicalMapping, openOption: .create)
        
        guard let uPackage = resultPackage else { return nil }
        if uPackage.partCount() == 0 {
            try uPackage.createPart(with: "Text") //createPart("Text Document")
        }
        return resultPackage
    }

    var doesInkFileExists: Bool {
        FileManager.default.fileExists(atPath: inkFilePath)
    }
}
