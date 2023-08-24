//
//  KeyboardAndInkViewController.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation
import PureLayout

final class KeyboardAndInkViewController: EditInkNoteViewController {
    
    private var keyboardEditorViewController: KeyboardEditorViewController!
    private var centeringView: UIView!
    
    //MARK: - Initialization
    
    init(inkNote: InkNote,
          engine: IINKEngine,
          completion: (() -> Void)?) {
        
        super.init(inkNote: inkNote, engine: engine, completion: completion, onNoteDeleted: nil)
        
        autoSaveNote = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        
        centeringView = UIView()
        centeringView.isHidden = true
        view.addSubview(centeringView)
        centeringView.autoPinEdge(.top, to: .top, of: view)
        centeringView.autoPinEdge(.bottom, to: .bottom, of: view)
        centeringView.autoSetDimension(.width, toSize: 1.0)
        centeringView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        super.viewDidLoad()
        
        view.backgroundColor = .white
                
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Save", comment: "").uppercased(),
                                                            primaryAction: UIAction(handler: { [weak self] _ in
            
            guard let text = self?.keyboardEditorViewController?.forceSave(),
                  let editor = self?.editorViewController?.editor,
                    let engine = self?.engine else {
                return
            }
                        
            do {
                try self?.viewModel.updateText(text, editor: editor, engine: engine)
                
                self?.releaseEditor()
                self?.autoSaveNote = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.navigationController?.dismiss(animated: true)
                    self?.completion?()
                }
            } catch {
                print(error)
            }
        }))
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "").uppercased(),
                                                           primaryAction: UIAction(handler: { [weak self] _ in
        
            self?.releaseEditor()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.navigationController?.dismiss(animated: true)
            }
        }))
        
        keyboardEditorViewController = KeyboardEditorViewController(text: viewModel.note.text, leftInsetsMultiplier: 0.0, onInputChange: nil)
        addChild(keyboardEditorViewController)
        view.addSubview(keyboardEditorViewController.view)
        keyboardEditorViewController.view.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .left)
        keyboardEditorViewController.view.autoPinEdge(.left, to: .right, of: centeringView, withOffset: 16 / 2)
        keyboardEditorViewController.didMove(toParent: self)
                
//        editorViewController?._viewModel.model?.neboInputView?.enableWriting = false
    }
    
    override func configureInkEditorConstraints(viewController: UIViewController) {
        viewController.view.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .right)
        viewController.view.autoPinEdge(.right, to: .left, of: centeringView, withOffset: -16 / 2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        keyboardEditorViewController.textView.becomeFirstResponder()
    }
}
