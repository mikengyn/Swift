//
//  Animations.swift
//
//  Created by Michael Nguyen on 2016-02-03.
//  mikenguyen.me

import Foundation

// A bunch of useful animations I created
extension UIView {
    
    func fadeOut(duration: NSTimeInterval){
        
        UIView.animateWithDuration(duration ,
            animations: {
                self.alpha = 0.0
            },
            completion: { finish in
                UIView.animateWithDuration(duration){
                    self.alpha = 0.0
                }
        })
    }
    
    func fadeIn(duration: NSTimeInterval, delay: NSTimeInterval? = 0, fromAlpha: CGFloat? = 0.0){
        
        self.alpha = fromAlpha!

        
        UIView.animateWithDuration(duration, delay: delay!, options: .CurveEaseInOut,
            animations: {
                self.alpha = 1.0
            },
            completion: { finish in
                UIView.animateWithDuration(duration){
                    self.alpha = 1.0
                }
        })
    }
    
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.28 // my magic animation number
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.addAnimation(animation, forKey: "shake")
    }
    
    func bounce() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.duration = 0.24 // my magic animation number
        animation.values = [0.0, -10.0, 0]
        layer.addAnimation(animation, forKey: "bounce")
    }
    

    
    func pop(){
        
        UIView.animateWithDuration(0.3,
                                   delay: 0,
                                   usingSpringWithDamping: 0.2,
                                   initialSpringVelocity: 2.0,
                                   options: UIViewAnimationOptions.AllowUserInteraction,
                                   animations: {
                                    self.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
}

