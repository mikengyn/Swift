//
//  Banner.swift
//
//  Created by Harlan Haskins on 7/27/15.
//  Copyright (c) 2015 Bryx. All rights reserved.
//
//  Modified by Michael Nguyen (AppDirect) 12/15/2015

import UIKit

private enum BannerState {
    case Showing, Hidden, Gone
}


/// A level of 'springiness' for Banners.
///
/// - None: The banner will slide in and not bounce.
/// - Slight: The banner will bounce a little.
/// - Heavy: The banner will bounce a lot.
public enum BannerSpringiness {
    case None, Slight, Heavy
    private var springValues: (damping: CGFloat, velocity: CGFloat) {
        switch self {
        case .None: return (damping: 1.0, velocity: 1.0)
        case .Slight: return (damping: 0.7, velocity: 1.5)
        case .Heavy: return (damping: 0.6, velocity: 2.0)
        }
    }
}

public enum BannerType {
    case Normal, Unread
}

/// Banner is a dropdown notification view that presents above the main view controller, but below the status bar.
public class Banner: UIView {
    private class func topWindow() -> UIWindow? {
        for window in UIApplication.sharedApplication().windows.reverse() {
            if window.windowLevel == UIWindowLevelNormal && !window.hidden { return window }
        }
        return nil
    }
    
    let contentView = UIView()
    private let labelView = UIView()
    let backgroundView = UIView()

    
    /// How long the slide down animation should last.
    public var animationDuration: NSTimeInterval = 0.5
    
    /// The preferred style of the status bar during display of the banner. Defaults to `.LightContent`.
    ///
    /// If the banner's `adjustsStatusBarStyle` is false, this property does nothing.
    public var preferredStatusBarStyle = UIStatusBarStyle.LightContent
    
    /// Whether or not this banner should adjust the status bar style during its presentation. Defaults to `false`.
    public var adjustsStatusBarStyle = false
    
    /// How 'springy' the banner should display. Defaults to `.Slight`
    public var springiness = BannerSpringiness.Slight
    
    /// The color of the text as well as the image tint color if `shouldTintImage` is `true`.
    public var textColor = UIColor.whiteColor() {
        didSet {
            resetTintColor()
        }
    }
    
    /// Whether or not the banner should show a shadow when presented.
    public var hasShadows = false {
        didSet {
            resetShadows()
        }
    }
    
    /// The color of the background view. Defaults to `nil`.
    override public var backgroundColor: UIColor? {
        get { return backgroundView.backgroundColor }
        set { backgroundView.backgroundColor = newValue }
    }
    
    /// The opacity of the background view. Defaults to 0.95.
    override public var alpha: CGFloat {
        get { return backgroundView.alpha }
        set { backgroundView.alpha = newValue }
    }
    
    /// A block to call when the uer taps on the banner.
    public var didTapBlock: (() -> ())?
    
    /// A block to call after the banner has finished dismissing and is off screen.
    public var didDismissBlock: (() -> ())?
    
    /// Whether or not the banner should dismiss itself when the user taps. Defaults to `true`.
    public var dismissesOnTap = false
    
    /// Whether or not the banner should dismiss itself when the user swipes up. Defaults to `true`.
    public var dismissesOnSwipe = true
    
    /// Whether or not the banner should tint the associated image to the provided `textColor`. Defaults to `true`.
    public var shouldTintImage = true {
        didSet {
            resetTintColor()
        }
    }
    
    /// The label that displays the banner's title.
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .ByTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        }()
    
    /// The label that displays the banner's subtitle.
    public let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label.numberOfLines = 1
        label.lineBreakMode = .ByTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        }()
    
    /// The image on the left of the banner.
    let image: UIImage?
    
    // Give the banner an identifier
    let id: String?
    
    
    private var bannerState = BannerState.Hidden {
        didSet {
            if bannerState != oldValue {
                forceUpdates()
            }
        }
    }
    
    /// A Banner with the provided `title`, `subtitle`, and optional `image`, ready to be presented with `show()`.
    ///
    /// - paramter id: The identifier of the banner. Optional. Defaults to nil
    /// - parameter title: The title of the banner. Optional. Defaults to nil.
    /// - parameter subtitle: The subtitle of the banner. Optional. Defaults to nil.
    /// - parameter image: The image on the left of the banner's text. Optional. Defaults to nil.
    /// - parameter backgroundColor: The color of the banner's background view. Defaults to `UIColor.blackColor()`.
    /// - parameter didTapBlock: An action to be called when the user taps on the banner. Optional. Defaults to `nil`.
    public required init(id: String? = "", title: String? = nil, subtitle: String? = nil, attributedString: NSAttributedString? = nil, image: UIImage? = nil, backgroundColor: UIColor = UIColor.blackColor(), font: UIFont? =   UIFont.systemFontOfSize(14.0, weight: UIFontWeightMedium), placeOnTop: Bool? = true, bannerType: BannerType? = BannerType.Normal, didTapBlock: (() -> ())? = nil) {
        self.didTapBlock = didTapBlock
        self.image = image
        self.id = id
        super.init(frame: CGRectZero)
        resetShadows()
        addGestureRecognizers()
        initializeSubviews(placeOnTop, bannerType: bannerType!)
        resetTintColor()
        detailLabel.text = subtitle
        titleLabel.font = font
        titleLabel.textAlignment = .Center
        backgroundView.backgroundColor = backgroundColor
        backgroundView.alpha = 1
        
        // Use an attributedString if specified
        if (attributedString != nil) {
            self.refreshAttributedString(attributedString!)
        }
            
        // initialize text attachments for the icon/image
        else if (image != nil){
            let attachment = NSTextAttachment()
            
            attachment.bounds = CGRectMake(0, -4, image!.size.width, image!.size.height) // align the icon with the titlelabel
            attachment.image = image
            
            let labelString = NSMutableAttributedString(string: " " + title!)
            let labelWithImage = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment));
            labelWithImage.appendAttributedString(labelString)
            titleLabel.attributedText = labelWithImage
        }
        else{
            titleLabel.text = title
        }

    }
    
    // Refreshes the banner's labels (for the unread message banner)
    public func refreshAttributedString(attributedString: NSAttributedString){
        // Use an attributedString if specified
            if (image != nil){
                let attachment = NSTextAttachment()
                
                attachment.bounds = CGRectMake(0, -4, image!.size.width, image!.size.height) // align the icon with the titlelabel
                attachment.image = image
                
                let labelWithImage = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment));
                labelWithImage.appendAttributedString(NSAttributedString(string: "  "))
                labelWithImage.appendAttributedString(attributedString)
                titleLabel.attributedText = labelWithImage
            }
                
            else{
                titleLabel.attributedText = attributedString
            }
    }
    
    private func forceUpdates() {
        guard let superview = superview, showingConstraint = showingConstraint, hiddenConstraint = hiddenConstraint else { return }
        switch bannerState {
        case .Hidden:
            superview.removeConstraint(showingConstraint)
            superview.addConstraint(hiddenConstraint)
        case .Showing:
            superview.removeConstraint(hiddenConstraint)
            superview.addConstraint(showingConstraint)
        case .Gone:
            superview.removeConstraint(hiddenConstraint)
            superview.removeConstraint(showingConstraint)
            superview.removeConstraints(commonConstraints)
        }
        setNeedsLayout()
        setNeedsUpdateConstraints()
        layoutIfNeeded()
        updateConstraintsIfNeeded()
    }
    
    internal func didTap(recognizer: UITapGestureRecognizer) {
        if dismissesOnTap {
            dismiss()
        }
        didTapBlock?()
    }
    
    internal func didSwipe(recognizer: UISwipeGestureRecognizer) {
        if dismissesOnSwipe {
            dismiss()
        }
    }
    
    private func addGestureRecognizers() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        swipe.direction = .Up
        addGestureRecognizer(swipe)
    }
    
    private func resetTintColor() {
        titleLabel.textColor = textColor
        detailLabel.textColor = textColor
    }
    
    private func resetShadows() {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = self.hasShadows ? 0.5 : 0.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
    }
    
    private func initializeSubviews(placeOnTop: Bool? = true, bannerType: BannerType) {
        let views = [
            "backgroundView": backgroundView,
            "contentView": contentView,
            "labelView": labelView,
            "titleLabel": titleLabel,
            "detailLabel": detailLabel
        ]
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
        backgroundView.backgroundColor = backgroundColor
        contentView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(contentView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelView)
        labelView.addSubview(titleLabel)
        labelView.addSubview(detailLabel)
        
        let heightOffset = 0
        for format in ["H:|[contentView]|", "V:|-(\(heightOffset))-[contentView]|"] {
            backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views))
        }
        
        // Left aligned
        if (bannerType == .Unread){
            
            backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]-(<=1)-[labelView]", options: .AlignAllCenterY, metrics: nil, views: views))
            backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView]-(<=1)-[labelView]", options: .AlignAllLeading, metrics: nil, views: views))
            
            for view in [titleLabel, detailLabel] {
                let constraintFormat = "H:|-(12)-[label]-(8)-|"
                contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraintFormat, options: .AlignAllCenterY, metrics: nil, views: ["label": view]))
            }

            labelView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(22)-[titleLabel][detailLabel]-(0)-|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView(>=64)]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
        }
            
        
        else{
            backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]-(<=1)-[labelView]", options: .AlignAllCenterY, metrics: nil, views: views))
            backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView]-(<=1)-[labelView]", options: .AlignAllCenterX, metrics: nil, views: views))
            
            for view in [titleLabel, detailLabel] {
                let constraintFormat = "H:|-(15)-[label]-(8)-|"
                contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraintFormat, options: .AlignAllCenterY, metrics: nil, views: ["label": view]))
            }
            
            contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-5-[labelView]-5-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
            
            if (placeOnTop == false){
                labelView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(22)-[titleLabel][detailLabel]-(0)-|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
                addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView(>=58)]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
            }
            else{
                labelView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(10)-[titleLabel][detailLabel]-(0)-|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
                addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView(>=70)]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
            }
        }

        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var showingConstraint: NSLayoutConstraint?
    private var hiddenConstraint: NSLayoutConstraint?
    private var commonConstraints = [NSLayoutConstraint]()
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = superview where bannerState != .Gone {
            commonConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[banner]|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["banner": self])
            superview.addConstraints(commonConstraints)
            let yOffset: CGFloat = -4.0 // Offset the bottom constraint to make room for the shadow to animate off screen.
            showingConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: superview, attribute: .Top, multiplier: 1.0, constant: yOffset)
            hiddenConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: superview, attribute: .Top, multiplier: 1.0, constant: yOffset)
        }
    }
    
    /// Shows the banner. If a view is specified, the banner will be displayed at the top of that view, otherwise at top of the top window. If a `duration` is specified, the banner dismisses itself automatically after that duration elapses.
    /// - parameter view: A view the banner will be shown in. Optional. Defaults to 'nil', which in turn means it will be shown in the top window. duration A time interval, after which the banner will dismiss itself. Optional. Defaults to `nil`.
    public func show(view: UIView? = Banner.topWindow(), duration: NSTimeInterval? = nil) {
        guard let view = view else {
            print("[Banner]: Could not find view. Aborting.")
            return
        }
        view.addSubview(self)
        forceUpdates()
        let (damping, velocity) = self.springiness.springValues
        let oldStatusBarStyle = UIApplication.sharedApplication().statusBarStyle
        if adjustsStatusBarStyle {
            UIApplication.sharedApplication().setStatusBarStyle(preferredStatusBarStyle, animated: true)
        }
        UIView.animateWithDuration(animationDuration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .AllowUserInteraction, animations: {
            self.bannerState = .Showing
            DLog("Showing banner: " + self.id!)
            }, completion: { finished in
                guard let duration = duration else { return }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    self.dismiss(self.adjustsStatusBarStyle ? oldStatusBarStyle : nil)
                }
        })
    }
    
    /// Dismisses the banner.
    public func dismiss(oldStatusBarStyle: UIStatusBarStyle? = nil) {
        let (damping, velocity) = self.springiness.springValues
        UIView.animateWithDuration(animationDuration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .AllowUserInteraction, animations: {
            self.bannerState = .Hidden
            if let oldStatusBarStyle = oldStatusBarStyle {
                UIApplication.sharedApplication().setStatusBarStyle(oldStatusBarStyle, animated: true)
            }
            }, completion: { finished in
                self.bannerState = .Gone
                self.removeFromSuperview()
                self.didDismissBlock?()
        })
    }
}