//
//  NotesViewController.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation

class NotesViewController: UIViewController {

    var note: Note?
    
    private var inkEditorViewController: EditingFixedViewController?
    private var keyboardEditorViewController: KeyboardEditorViewController?
    
    private var editingTimer: Timer?
    private var wasEditorRemovedPreviously = true
    private var isKeyboardVisible = false
    private var editorLoadCount = 0
    
    //MARK: - Deinit

    deinit {
        if let editorViewController = inkEditorViewController {
            removeViewController(editorViewController, animated: false)
        }
    }
    
    //MARK: - View Lifecycle
    
    var rightButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = FileManager.default.pathForFileInDocumentDirectory(fileName: "note_1.iink")
        self.note = Note(id: "note_1", text: "", inkFilePath: path)
        
        rightButton = UIBarButtonItem(title: "Open Keyboard", style: .plain, target: self, action: #selector(onToggleKeyboard(_:)))
        navigationItem.rightBarButtonItem = rightButton
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Modal", style: .plain, target: self, action: #selector(onOpenKeyboardAndInk(_:)))
    }
    
    @objc private func onOpenKeyboardAndInk(_ sender: Any) {
     
        let viewController = KeyboardAndInkViewController(inkNote: note!, engine: EngineProvider.sharedInstance.engine!) {
            
        }
        
        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true)
    }
    
    @objc private func onToggleKeyboard(_ sender: Any) {
        
        if isKeyboardVisible {
            
            saveKeyboardText()
            isKeyboardVisible = false
            releaseKeyboardInput()
            rightButton.title = "Open Keyboard"
        } else {
            
            saveCurrentInkNote()
            isKeyboardVisible = true
            loadKeyboardInput()
            rightButton.title = "Close Keyboard"
        }
    }
    
    var isFirstAppear: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let cached = wasEditorRemovedPreviously
        
        let offset: TimeInterval = isKeyboardAndInkViewControllerVisible ? 0.2 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
         
            self.loadEditor(forceLoad: self.isFirstAppear)
            if cached && self.isKeyboardVisible {
                self.loadKeyboardInput()
            }
            self.isFirstAppear = false
        }
    }
    
    private var isKeyboardAndInkViewControllerVisible: Bool {
        (presentedViewController as? UINavigationController)?.topViewController is KeyboardAndInkViewController
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        releaseInkEditor(saveCurrentInkNote: isKeyboardAndInkViewControllerVisible ? false : true)
        
        keyboardEditorViewController?.textView.resignFirstResponder()
    }
    
    //MARK: - Saving
    
    func saveTextInputs() {
        
        if isKeyboardVisible {
            saveKeyboardText()
        } else {
            saveCurrentInkNote()
        }
    }
    
    private func saveCurrentInkNote() {

        do {
            let writtenText = try inkEditorViewController!.writtenText()
            note?.text = writtenText
            
        } catch  {
            print(error)
        }
    }
    
    private func saveKeyboardText() {
        keyboardEditorViewController?.forceSave()
    }
    
    private func saveCurrentTextToInkNote(_ text: String) {
        
        guard let editor = inkEditorViewController?.editor else {
            return
        }
        
        note?.text = text
        
        do {
            try note!.importTextIntoEditor(text: text, editor: editor, engine: EngineProvider.sharedInstance.engine!)
        } catch {
            print("Error when importing text to INK: \(error)")
        }
    }
    
    private func releaseInkEditor(saveCurrentInkNote: Bool) {

        editingTimer?.invalidate()
        editingTimer = nil
        
        if saveCurrentInkNote {
            self.saveTextInputs()
        }

        if let editorViewController = inkEditorViewController {
            removeViewController(editorViewController, animated: true)
            self.inkEditorViewController = nil
        }
        wasEditorRemovedPreviously = true
    }

    private func loadEditor(forceLoad: Bool) {
        guard inkEditorViewController == nil else { return }
        
        guard let engine = EngineProvider.sharedInstance.engine else {
            return
        }

        inkEditorViewController = EditingFixedViewController(engine: engine)
        addChild(inkEditorViewController!)
        view.addSubview(inkEditorViewController!.view)
        inkEditorViewController!.view.autoPinEdgesToSuperviewEdges()
        inkEditorViewController!.didMove(toParent: self)
        
        let canAutoSave = editorLoadCount > 0 && isKeyboardAndInkViewControllerVisible == false
        
        if wasEditorRemovedPreviously || forceLoad {
            loadNote(self.note!, forceLoad: true, autoSaveCurrent: canAutoSave)
        }
        wasEditorRemovedPreviously = false
        editorLoadCount += 1
    }
    
    private func loadNote(_ note: InkNote, forceLoad: Bool, autoSaveCurrent: Bool = true) {

        guard inkEditorViewController != nil else { return }
        
        if autoSaveCurrent {
            saveCurrentInkNote()
        }

        if let current = self.note, forceLoad == false {
            guard current.id != note.id else {
                return
            }
        }

        do {
            try inkEditorViewController!.loadNote(note: note, engine: EngineProvider.sharedInstance.engine!)
            
        } catch {
            print(error)
        }
    }
    
    private func loadKeyboardInput() {
        
        inkEditorViewController?.editor?.waitForIdle()
        
        if let keyboardEditorViewController = keyboardEditorViewController {
            if let note = self.note {
                keyboardEditorViewController.reload(text: note.text ?? "")
                if let view = keyboardEditorViewController.view {
                    view.superview?.bringSubviewToFront(view)
                }
            }
            return
        }
                
        editingTimer?.invalidate()
        editingTimer = nil
        
        if let editorViewController = keyboardEditorViewController {
            removeViewController(editorViewController, animated: true)
            self.keyboardEditorViewController = nil
        }
        
        keyboardEditorViewController = KeyboardEditorViewController(text: self.note?.text, onInputChange: { [weak self] text in
            // Do not reload ink to often. Because of that we won't be doing it now.
            self?.saveCurrentTextToInkNote(text)
        })
        addViewController(keyboardEditorViewController!)
    }
    
    private func releaseKeyboardInput() {
        
        if let editorViewController = keyboardEditorViewController {
            editorViewController.textView?.resignFirstResponder()
            removeViewController(editorViewController, animated: true)
            self.keyboardEditorViewController = nil
        }
    }
}

extension NotesViewController {
    
    //MARK: - UIViewController Containement
    
    private func addViewController(_ viewController: UIViewController) {
        
        viewController.view.alpha = 0.0
        view.addSubview(viewController.view)
        viewController.view.autoPinEdge(.left, to: .left, of: view)
        viewController.view.autoPinEdge(.right, to: .right, of: view)
        viewController.view.autoPinEdge(.bottom, to: .bottom, of: view)
        viewController.view.autoPinEdge(.top, to: .top, of: view)
        viewController.didMove(toParent: self)

        UIView.animate(withDuration: 0.25) {
            viewController.view.alpha = 1.0
        }
    }
    
    private func removeViewController(_ viewController: UIViewController, animated: Bool) {
        
        let animations = {
            viewController.view.alpha = 0.0
        }
        
        let completion: ((Bool) -> Void) = { (_) in
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            viewController.didMove(toParent: nil)
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: animations, completion: completion)
        }
        else {
            animations()
            completion(true)
        }
    }

    //MARK: - Timer

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        scheduleTimer()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        scheduleTimer()
    }

    private func scheduleTimer() {
                
        editingTimer?.invalidate()
        editingTimer = Timer(timeInterval: 2.0, repeats: false, block: { [weak self] (_) in
            
            guard let editor = self?.inkEditorViewController?.editor else {
                return
            }
            
            if editor.idle {
                self?.saveCurrentInkNote()
            }
        })
        if let timer = editingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}
