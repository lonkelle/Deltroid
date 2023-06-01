//
//  PopoverMenuController.swift
//  Delta
//
//  Created by Riley Testut on 9/5/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

private var popoverMenuControllerKey: UInt8 = 0

#if canImport(UIKit)
extension UINavigationItem
{
    var popoverMenuController: PopoverMenuController? {
        get { return objc_getAssociatedObject(self, &popoverMenuControllerKey) as? PopoverMenuController }
        set {
            self.titleView = newValue?.popoverMenuButton
            objc_setAssociatedObject(self, &popoverMenuControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
#endif

class PopoverMenuController: NSObject
{
    let popoverViewController: UIViewController
    
    let popoverMenuButton: PopoverMenuButton
    
    var isActive: Bool = false {
        willSet {
            guard newValue != self.isActive else { return }
            
            if newValue
            {
                self.presentPopoverViewController()
            }
            else
            {
                self.dismissPopoverViewController()
            }
        }
    }

    init(popoverViewController: UIViewController)
    {
        self.popoverViewController = popoverViewController
        
        self.popoverMenuButton = PopoverMenuButton()
        
        super.init()
        
        self.popoverMenuButton.addTarget(self, action: #selector(PopoverMenuController.pressedPopoverMenuButton(_:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PopoverMenuController {
    @objc func pressedPopoverMenuButton(_ button: PopoverMenuButton) {
        self.isActive = !self.isActive
    }
    
    func presentPopoverViewController() {
        guard !self.isActive else { return }
        
        guard let presentingViewController = self.popoverMenuButton.parentViewController else { return }
#if !os(tvOS) && !os(macOS)
        self.popoverViewController.modalPresentationStyle = .popover
        self.popoverViewController.popoverPresentationController?.delegate = self
#else
        self.popoverViewController.modalPresentationStyle = .overCurrentContext
        self.popoverViewController.popoverPresentationController?.delegate = nil
#endif
        self.popoverViewController.popoverPresentationController?.sourceView = self.popoverMenuButton.superview
        self.popoverViewController.popoverPresentationController?.sourceRect = self.popoverMenuButton.frame
        
        presentingViewController.present(self.popoverViewController, animated: true, completion: nil)
    }
    
    func dismissPopoverViewController() {
        guard self.isActive else { return }
        
        self.popoverViewController.dismiss(animated: true, completion: nil)
    }
}
#if !os(tvOS) && !os(macOS)
extension PopoverMenuController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Force popover presentation, regardless of trait collection.
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.isActive = false
    }
}
#endif
