//
//  UIView+ParentViewController.swift
//  Delta
//
//  Created by Riley Testut on 9/3/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

extension UIView
{
    var parentViewController: UIViewController? {
        var nextResponder = self.next
        
        while nextResponder != nil
        {
            if let parentViewController = nextResponder as? UIViewController
            {
                return parentViewController
            }
            
            nextResponder = nextResponder?.next
        }
        
        return nil
    }
}
