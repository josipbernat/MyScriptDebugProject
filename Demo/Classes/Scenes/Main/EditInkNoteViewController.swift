//
//  EditInkNoteViewController.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation
import PureLayout

class EditInkNoteViewController: UIViewController {
    
    var viewModel: EditInkNoteViewModel
    private(set) var editorViewController: EditingFixedViewController?
    private(set) var completion: (() -> Void)?
    private var onNoteDeleted: ((InkNote) -> Void)?
    
    var autoSaveNote = true
    let engine: IINKEngine
    
    //MARK: - Initialization
    
    init(inkNote: InkNote,
          engine: IINKEngine,
          completion: (() -> Void)?,
          onNoteDeleted: ((InkNote) -> Void)?) {

        self.viewModel = EditInkNoteViewModel(note: inkNote)
        self.engine = engine
        
        super.init(nibName: nil, bundle: nil)
        
        self.completion = completion
        self.onNoteDeleted = onNoteDeleted
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Deinit
    
    deinit {
        toggleSheetDismissRecognizer(enable: true)
    }
        
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editorViewController = EditingFixedViewController(engine: engine, smartGuideDisabled: true)
        addChild(editorViewController!)
        view.addSubview(editorViewController!.view)
        configureInkEditorConstraints(viewController: editorViewController!)
        editorViewController!.didMove(toParent: self)

        loadNote(viewModel.note)
        
        toggleSheetDismissRecognizer(enable: false)
    }
    
    func configureInkEditorConstraints(viewController: UIViewController) {
        viewController.view.autoPinEdgesToSuperviewSafeArea()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        guard autoSaveNote else { return }
        
        saveCurrentInkNote()
        completion?()
    }
    
    func toggleSheetDismissRecognizer(enable: Bool) {
        if let gestures = self.navigationController?.presentationController?.presentedView?.gestureRecognizers {
            for item in gestures {
                if let name = item.name, name.contains("SheetInteractionBackground") {
                    item.isEnabled = enable
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        toggleSheetDismissRecognizer(enable: false)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        toggleSheetDismissRecognizer(enable: false)
    }
}

extension EditInkNoteViewController {

    private func loadNote(_ note: InkNote) {
        
        do {
            try editorViewController?.loadNote(note: note, engine: engine)
        } catch {
            print(error)
        }
    }

    func saveCurrentInkNote() {

        guard let editor = editorViewController?.editor,
                editor.part != nil else {
            return
        }
        
        do {
            let writtenText = try editorViewController!.writtenText()
            try viewModel.updateText(writtenText, editor: editor, engine: engine)
        } catch  {
            print(error)
        }
    }
    
    func releaseEditor() {
        
        editorViewController?.willMove(toParent: nil)
        editorViewController?.view.removeFromSuperview()
        editorViewController?.removeFromParent()
        editorViewController?.didMove(toParent: nil)
        editorViewController = nil
    }
}
