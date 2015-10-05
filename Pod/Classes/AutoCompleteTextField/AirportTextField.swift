//
//  AutoCompleteTextField.swift
//  AutocompleteTextfieldSwift
//
//  Created by Mylene Bayan on 6/13/15.
//  Copyright (c) 2015 MaiLin. All rights reserved.
//

import Foundation
import UIKit

public class AirportTextField: UITextField, UITableViewDataSource, UITableViewDelegate {
    
    let placeholderLabel = UILabel()
    
    var tintedClearImage: UIImage?
    /// Manages the instance of tableview
    private var autoCompleteTableView:UITableView?
    /// Holds the collection of attributed strings
    private var attributedAutoCompleteStrings:[NSAttributedString]?
    /// Handles user selection action on autocomplete table view
    public var onSelect:(String, NSIndexPath)->() = {_,_ in}
    /// Handles textfield's textchanged
    public var onTextChange:(String)->() = {_ in}
    
    /// Font for the text suggestions
    public var autoCompleteTextFont = UIFont(name: "HelveticaNeue-Light", size: 12)
    /// Color of the text suggestions
    public var autoCompleteTextColor = UIColor.blackColor()
    /// Used to set the height of cell for each suggestions
    public var autoCompleteCellHeight:CGFloat = 44.0
    /// The maximum visible suggestion
    public var maximumAutoCompleteCount = 3
    /// Used to set your own preferred separator inset
    public var autoCompleteSeparatorInset = UIEdgeInsetsZero
    /// Shows autocomplete text with formatting
    public var enableAttributedText = false
    /// User Defined Attributes
    public var autoCompleteAttributes:[String:AnyObject]?
    // Hides autocomplete tableview after selecting a suggestion
    public var hidesWhenSelected = true
    /// Hides autocomplete tableview when the textfield is empty
    public var hidesWhenEmpty:Bool? {
        didSet{
            assert(hidesWhenEmpty != nil, "hideWhenEmpty cannot be set to nil")
            autoCompleteTableView?.hidden = hidesWhenEmpty!
        }
    }
    /// The table view height
    public var autoCompleteTableHeight:CGFloat?{
        didSet{
            redrawTable()
        }
    }
    /// The strings to be shown on as suggestions, setting the value of this automatically reload the tableview
    public var autoCompleteStrings:[String]?{
        didSet{ reload() }
    }
    
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        setupAutocompleteTable(superview!)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
        setupAutocompleteTable(superview!)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for view in subviews {
            if view is UIButton {
                let button = view as! UIButton
                if let uiImage = button.imageForState(.Highlighted) {
                    if tintedClearImage == nil {
                        tintedClearImage = tintImage(uiImage, color: tintColor)
                    }
                    button.setImage(tintedClearImage, forState: .Normal)
                    button.setImage(tintedClearImage, forState: .Highlighted)
                }
            }
        }
    }
    
    private func tintImage(image: UIImage, color: UIColor) -> UIImage {
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2)
        let context = UIGraphicsGetCurrentContext()
        image.drawAtPoint(CGPointZero, blendMode: .Normal, alpha: 1.0)
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextSetBlendMode(context, .SourceIn)
        CGContextSetAlpha(context, 1.0)
        
        let rect = CGRectMake(
            CGPointZero.x,
            CGPointZero.y,
            image.size.width,
            image.size.height)
        CGContextFillRect(UIGraphicsGetCurrentContext(), rect)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tintedImage
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        commonInit()
        setupAutocompleteTable(newSuperview!)
        
        if newSuperview != nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "textFieldDidEndEditing", name:UITextFieldTextDidEndEditingNotification, object: self)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "textFieldDidBeginEditing", name:UITextFieldTextDidBeginEditingNotification, object: self)
        } else {
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    private func commonInit(){
        hidesWhenEmpty = true
        autoCompleteAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        autoCompleteAttributes![NSFontAttributeName] = UIFont(name: "HelveticaNeue-Bold", size: 12)
        self.addTarget(self, action: "textFieldDidChange", forControlEvents: .EditingChanged)
        textColor = tintColor
    }
    
    private func setupAutocompleteTable(view:UIView){
        let screenSize = UIScreen.mainScreen().bounds.size
        let tableView = UITableView(frame: CGRectMake(self.frame.origin.x, self.frame.origin.y + CGRectGetHeight(self.frame), screenSize.width - (self.frame.origin.x * 2), 30.0))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = autoCompleteCellHeight
        tableView.hidden = hidesWhenEmpty ?? true
        tableView.backgroundColor = FlightColors.presqueWhite.colorWithAlphaComponent(0.1)
        tableView.scrollEnabled = false
        tableView.tableFooterView = UIView(frame: CGRectZero)
        view.addSubview(tableView)
        autoCompleteTableView = tableView
        
        autoCompleteTableHeight = CGFloat(maximumAutoCompleteCount) * autoCompleteCellHeight
    }
    
    private func redrawTable(){
        if autoCompleteTableView != nil{
            var newFrame = autoCompleteTableView!.frame
            newFrame.size.height = autoCompleteTableHeight!
            
            autoCompleteTableView!.frame = newFrame
        }
    }
    
    public func hideAutoCompleteTableView() {
        autoCompleteTableView?.hidden = true
    }
    
    //MARK: - UITableViewDataSource
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoCompleteStrings != nil ? (autoCompleteStrings!.count > maximumAutoCompleteCount ? maximumAutoCompleteCount : autoCompleteStrings!.count) : 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "autocompleteCellIdentifier"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil{
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
        }
        
        cell?.backgroundColor = UIColor.clearColor()
        cell?.selectionStyle = .None
        
        if enableAttributedText{
            cell?.textLabel?.attributedText = attributedAutoCompleteStrings![indexPath.row]
        }
        else{
            cell?.textLabel?.font = autoCompleteTextFont
            cell?.textLabel?.textColor = autoCompleteTextColor
            cell?.textLabel?.text = autoCompleteStrings![indexPath.row]
        }
        
        return cell!
    }
    
    //MARK: - UITableViewDelegate
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        onSelect(cell!.textLabel!.text!, indexPath)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            tableView.hidden = self.hidesWhenSelected
        })
    }
    
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.respondsToSelector("setSeparatorInset:"){
            cell.separatorInset = autoCompleteSeparatorInset}
        if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:"){
            cell.preservesSuperviewLayoutMargins = false}
        if cell.respondsToSelector("setLayoutMargins:"){
            cell.layoutMargins = autoCompleteSeparatorInset}
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return autoCompleteCellHeight
    }
    
    //MARK: - Private Interface
    private func reload(){
        if enableAttributedText{
            let attrs = [NSForegroundColorAttributeName:autoCompleteTextColor, NSFontAttributeName:UIFont.systemFontOfSize(12.0)]
            if attributedAutoCompleteStrings == nil{
                attributedAutoCompleteStrings = [NSAttributedString]()
            }
            else{
                if attributedAutoCompleteStrings?.count > 0 {
                    attributedAutoCompleteStrings?.removeAll(keepCapacity: false)
                }
            }
            
            if autoCompleteStrings != nil{
                for i in 0..<autoCompleteStrings!.count{
                    let str = autoCompleteStrings![i] as NSString
                    let range = str.rangeOfString(text!, options: .CaseInsensitiveSearch)
                    let attString = NSMutableAttributedString(string: autoCompleteStrings![i], attributes: attrs)
                    attString.addAttributes(autoCompleteAttributes!, range: range)
                    attributedAutoCompleteStrings?.append(attString)
                }
            }
        }
        
        if let ac = autoCompleteStrings {
            if (ac.count < 3) {
                autoCompleteTableHeight = CGFloat(ac.count) * autoCompleteCellHeight
            } else {
                autoCompleteTableHeight = CGFloat(maximumAutoCompleteCount) * autoCompleteCellHeight
            }
        } else {
            autoCompleteTableHeight = 0
        }
        
        autoCompleteTableView?.reloadData()
    }
    
    //MARK: - Internal
    func textFieldDidChange(){
        if let _ = text {
            onTextChange(text!)
        }
        if text!.isEmpty{ autoCompleteStrings = nil }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.autoCompleteTableView?.hidden =  self.hidesWhenEmpty! ? self.text!.isEmpty : false
        })
    }
    
    public var borderInactiveColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    public var borderActiveColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    public var placeholderColor: UIColor? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override public var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override public var bounds: CGRect {
        didSet {
            updateBorder()
            updatePlaceholder()
        }
    }
    
    private let borderThickness: (active: CGFloat, inactive: CGFloat) = (active: 2, inactive: 2)
    private let placeholderInsets = CGPoint(x: 0, y: 6)
    private let textFieldInsets = CGPoint(x: 0, y: 12)
    private let inactiveBorderLayer = CALayer()
    private let activeBorderLayer = CALayer()
    
    private var inactivePlaceholderPoint: CGPoint = CGPointZero
    private var activePlaceholderPoint: CGPoint = CGPointZero
    
    // MARK: - TextFieldsEffectsProtocol
    
    func drawViewsForRect(rect: CGRect) {
        let frame = CGRect(origin: CGPointZero, size: CGSize(width: rect.size.width, height: rect.size.height))
        
        placeholderLabel.frame = CGRectInset(frame, placeholderInsets.x, placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(self.font!)
        
        updateBorder()
        updatePlaceholder()
        
        layer.addSublayer(inactiveBorderLayer)
        layer.addSublayer(activeBorderLayer)
        addSubview(placeholderLabel)
        
        inactivePlaceholderPoint = placeholderLabel.frame.origin
        activePlaceholderPoint = CGPoint(x: placeholderLabel.frame.origin.x, y: placeholderLabel.frame.origin.y - placeholderLabel.frame.size.height - placeholderInsets.y)
    }
    
    private func updateBorder() {
        inactiveBorderLayer.frame = rectForBorder(borderThickness.inactive, isFill: true)
        inactiveBorderLayer.backgroundColor = borderInactiveColor?.CGColor
        
        activeBorderLayer.frame = rectForBorder(borderThickness.active, isFill: false)
        activeBorderLayer.backgroundColor = borderActiveColor?.CGColor
    }
    
    private func updatePlaceholder() {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        if isFirstResponder() || !text!.isEmpty {
            animateViewsForTextEntry()
        }
    }
    
    private func placeholderFontFromFont(font: UIFont) -> UIFont! {
        let smallerFont = UIFont(name: font.fontName, size: font.pointSize * 0.65)
        return smallerFont
    }
    
    private func rectForBorder(thickness: CGFloat, isFill: Bool) -> CGRect {
        if isFill {
            return CGRect(origin: CGPoint(x: 0, y: CGRectGetHeight(frame)-thickness), size: CGSize(width: CGRectGetWidth(frame), height: thickness))
        } else {
            return CGRect(origin: CGPoint(x: 0, y: CGRectGetHeight(frame)-thickness), size: CGSize(width: 0, height: thickness))
        }
    }
    
    private func layoutPlaceholderInTextRect() {
        let textRect = textRectForBounds(bounds)
        var originX = textRect.origin.x
        switch self.textAlignment {
        case .Center:
            originX += textRect.size.width/2 - placeholderLabel.bounds.width/2
        case .Right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        placeholderLabel.frame = CGRect(x: originX, y: textRect.height/2,
            width: placeholderLabel.bounds.width, height: placeholderLabel.bounds.height)
    }
    
    func animateViewsForTextEntry() {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: ({ [unowned self] in
            
            if self.text!.isEmpty {
                self.placeholderLabel.frame.origin = CGPoint(x: 10, y: self.placeholderLabel.frame.origin.y)
                self.placeholderLabel.alpha = 0
            }
            }), completion: { [unowned self] (completed) in
                
                self.layoutPlaceholderInTextRect()
                
                self.placeholderLabel.frame.origin = self.activePlaceholderPoint
                
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.placeholderLabel.alpha = 0.5
                })
            })
        
        self.activeBorderLayer.frame = self.rectForBorder(self.borderThickness.active, isFill: true)
    }
    
    func animateViewsForTextDisplay() {
        if text!.isEmpty {
            UIView.animateWithDuration(0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: ({ [unowned self] in
                self.layoutPlaceholderInTextRect()
                self.placeholderLabel.alpha = 1
                }), completion: nil)
            
            self.activeBorderLayer.frame = self.rectForBorder(self.borderThickness.active, isFill: false)
        }
    }
    
    // MARK: - Overrides
    
    override public func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectOffset(bounds, textFieldInsets.x, textFieldInsets.y)
    }
    
    override public func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectOffset(bounds, textFieldInsets.x, textFieldInsets.y)
    }
    
    override public func prepareForInterfaceBuilder() {
        drawViewsForRect(frame)
    }
    
    // MARK: - Overrides
    
    override public func drawRect(rect: CGRect) {
        drawViewsForRect(rect)
    }
    
    override public func drawPlaceholderInRect(rect: CGRect) {
        // Don't draw any placeholders
    }
    
    public func textFieldDidBeginEditing() {
        animateViewsForTextEntry()
    }
    
    public func textFieldDidEndEditing() {
        animateViewsForTextDisplay()
    }
}