//
//  EditingFixedViewController.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation
import MyScriptInteractiveInk_Runtime

class EditingFixedViewController: EditorViewController {
    
    private(set) var _viewModel: EditorViewModel
    fileprivate weak var _engine: IINKEngine!
    private var textToImport: String?
    
    var editor: IINKEditor? {
        _viewModel.editor
    }

    //MARK: - Memory Management
    deinit {
        
        do {
            try editor?.set(part: nil)
        } catch {
            print(error)
        }
        
        _viewModel.model?.smartGuideViewController?.delegate = nil
        _viewModel.model?.smartGuideViewController?.editor = nil

        let controllersToRemove = children
        for item in controllersToRemove {
            item.view.removeFromSuperview()
            item.removeFromParent()
        }
    }
    
    //MARK: - Initialization
    
    init(engine: IINKEngine?, smartGuideDisabled: Bool = false) {
        let viewModel = EditorViewModel(engine: engine,
                                        inputMode: .auto,
                                        editorDelegate: nil,
                                        smartGuideDelegate: nil,
                                        smartGuideDisabled: smartGuideDisabled)
        self._viewModel = viewModel
        self._engine = engine
        
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditingFixedViewController {
    
    func loadNote(note: InkNote, engine: IINKEngine) throws {
        
        guard let editor = editor else { return }
        
        try note.loadIntoEditor(editor: editor, engine: engine)
        
        if let textToImport = textToImport {
            try note.importPredefinedTextIntoEditorIfNeeded(editor, text: textToImport, engine: engine)
        }
    }
    
    func writtenText() throws -> String? {
        
        guard let editor = editor else { return nil }

        /// @see https://developer-support.myscript.com/support/discussions/topics/16000026267
        /// Before exporting, ensure you call the waitForIdle function: https://developer-support.myscript.com/support/discussions/topics/16000022498
        try editor.saveAll()
        
        // Don't wait for idle because it may freeze the app!!!
        //editor.waitForIdle()

        return try editor.export(selection: nil, mimeType: .text)
    }
}
extension IINKEditor {
    
    func saveAll() throws {
        
        try part?.package.saveToTemp()
        try part?.package.save()
    }
}

