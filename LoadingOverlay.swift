//
//  LoadingOverlay.swift
//  Michael Nguyen
//  mikenguyen.me
//

import UIKit

public class LoadingOverlay {
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    public func showOverlay(view: UIView, delay: Bool? = true, blockUserInteraction: Bool? = true) {
        
        overlayView.frame = CGRectMake(0, 0, 80, 80)
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        overlayView.alpha = 0.8
        overlayView.clipsToBounds = true
        overlayView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRectMake(0, 0, 40, 40)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.center = CGPointMake(overlayView.bounds.width / 2, overlayView.bounds.height / 2)
        
        overlayView.addSubview(activityIndicator)
        view.addSubview(overlayView)
        
        activityIndicator.startAnimating()

        if (blockUserInteraction == true) {
            UIApplication.sharedApplication().keyWindow?.userInteractionEnabled = false
        }
        
        // Delay it, in cases where loading is faster than the delay time the overlay will not show!
        // On by default
        if (delay == true){
            overlayView.fadeIn(0.2, delay: 0.7, fromAlpha: 0)
        }
        
    }


    public func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
        UIApplication.sharedApplication().keyWindow?.userInteractionEnabled = true
    }


    public func show(view: UIView!, yPos: CGFloat? = 0) {
        
        // For tableviews, override the yPos and set it to -44 to center it
        
        overlayView = UIView(frame: CGRectMake(0, yPos!, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        let transform = CGAffineTransformMakeScale(1.1, 1.1)
        overlayView.transform = transform
        overlayView.alpha = 0
        overlayView.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.6)
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = overlayView.center
        overlayView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        view.addSubview(overlayView)

        overlayView.fadeIn(0.4, fromAlpha: 0)
    }
}


