//
//  FadeSegue.swift
//
//  Created by Michael Nguyen on 2016-01-04.
//

import UIKit
import QuartzCore

public class FadeSegue : UIStoryboardSegue {
    
    override public func perform() {
        
        let transition = CATransition()
        transition.duration = 0.27;
        transition.type = kCATransitionFade;
        
        self.sourceViewController.view.window?.layer.addAnimation(transition, forKey: kCATransitionFade)
        
        self.sourceViewController.presentViewController(self.destinationViewController, animated: false, completion: nil)
    }
}