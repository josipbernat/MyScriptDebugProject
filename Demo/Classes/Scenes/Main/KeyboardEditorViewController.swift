//
//  KeyboardEditorViewController.swift
//  Demo
//
//  Created by Josip Bernat on 24.08.2023..
//  Copyright © 2023 MyScript. All rights reserved.
//

import Foundation
import PureLayout
import Combine

class KeyboardEditorViewController: UIViewController {
    
    private(set) var textView: LinedTextView!
    
    typealias OnChange = ((_ text: String) -> Void)
    private var onInputChange: OnChange?
    
    @Published private var inputText: String = ""
    private var cancellable: AnyCancellable?
    
    private var initialText: String?
    private let leftInsetsMultiplier: CGFloat
    
    //MARK: - Deinit
    
    deinit {
        
        cancellable?.cancel()
        cancellable = nil
        
        onInputChange = nil
        cancellBinding()
    }
    
    //MARK: - Initialization
    
    init(text: String?, leftInsetsMultiplier: CGFloat = 1.7, onInputChange: OnChange?) {
        
        self.leftInsetsMultiplier = leftInsetsMultiplier
        
        super.init(nibName: nil, bundle: nil)
        
        self.onInputChange = onInputChange
        self.inputText = text ?? ""
        self.initialText = text
        
        bindToInputText()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        textView = LinedTextView(frame: .zero)
        textView.backgroundColor = .systemBackground
        textView.delegate = self
        textView.text = inputText
        view.addSubview(textView)
        textView.autoPinEdgesToSuperviewEdges(with: .zero)
        
        var insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        insets.top = 16 * 6
        insets.left = 16 * leftInsetsMultiplier
        textView.textContainerInset = insets
    }
    
    //MARK: - Controls
    
    func clear() {
        textView.text = ""
    }
    
    func reload(text: String) {
        
        textView.text = text
        initialText = text
        
        cancellBinding()
        inputText = text
        bindToInputText()
    }
    
    @discardableResult
    func forceSave() -> String {
        cancellBinding()
        
        var hasChanges = true
        if let initialText = initialText, textView.text == initialText {
            hasChanges = false
        }
        
        inputText = textView.text
        if hasChanges {
            onInputChange?(inputText)
        }
        bindToInputText()
                
        return inputText
    }
    
    private func cancellBinding() {
        cancellable?.cancel()
        cancellable = nil
    }
    
    private func bindToInputText() {
        
        cancellable = $inputText
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .dropFirst()
            .sink(receiveValue: { [weak self] newValue in
                self?.onInputChange?(newValue)
            })
    }
    
    override func removeFromParent() {
        super.removeFromParent()
        
        onInputChange = nil
        cancellBinding()
    }
}

extension KeyboardEditorViewController: UITextViewDelegate {
    
    //MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        inputText = textView.text
        self.textView.updatePlaceholder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.setNeedsDisplay()
    }
}

class LinedTextView: UITextView {
    
    override var font: UIFont? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            setNeedsDisplay()
            placeholderTop.constant = textContainerInset.top
            placeholderLeading.constant = textContainerInset.left
        }
    }
    
    override var text: String! {
        didSet {
            updatePlaceholder()
        }
    }
    
    //MARK: - Initialization
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private var placeholerLabel: UILabel!
    private var placeholderLeading: NSLayoutConstraint!
    private var placeholderTop: NSLayoutConstraint!
    
    private func setup() {
    
        contentMode = .redraw
        font = .systemFont(ofSize: 30, weight: .regular)
        
        placeholerLabel = UILabel()
        placeholerLabel.text = NSLocalizedString("Take notes...", comment: "")
        placeholerLabel.font = self.font
        placeholerLabel.textColor = .placeholderText
        placeholerLabel.backgroundColor = .clear
        addSubview(placeholerLabel)
        placeholderTop = placeholerLabel.autoPinEdge(.top, to: .top, of: self, withOffset: textContainerInset.top)
        placeholderLeading = placeholerLabel.autoPinEdge(.left, to: .left, of: self, withOffset: textContainerInset.left)
    }
    
    func updatePlaceholder() {
        placeholerLabel.isHidden = text.isEmpty ? false : true
    }
    
    //MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext(), let font = self.font else {
            return
        }
        ctx.setStrokeColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
        ctx.setLineWidth(0.7)
        ctx.beginPath()
                
        // Create un-mutated floats outside of the for loop.
        // Reduces memory access.
        let baseOffset = self.textContainerInset.top + font.descender
        let boundsX = self.bounds.origin.x
        let boundsWidth = self.bounds.size.width
        let screenScale = window?.screen.scale ?? 2.0
        
        // Only draw lines that are visible on the screen.
        // (As opposed to throughout the entire view's contents)
        let firstVisibleLine = max(1, (self.contentOffset.y / font.lineHeight));
        let lastVisibleLine = CGFloat(ceilf(Float((self.contentOffset.y + self.bounds.size.height) / font.lineHeight)))
        
        for line in Int(firstVisibleLine)..<Int(lastVisibleLine) {
            
            let linePointY: CGFloat = (baseOffset + (font.lineHeight * CGFloat(line)))
            let roundedLinePointY = CGFloat(roundf(Float(linePointY * screenScale))) / screenScale;
            ctx.move(to: CGPoint(x: boundsX, y: roundedLinePointY))
            ctx.addLine(to: CGPoint(x: boundsWidth, y: roundedLinePointY))
        }
                
        ctx.closePath()
        ctx.strokePath()
        
        updatePlaceholder()
    }
}
