//
//  UIImage+SymbolFallback.swift
//  Delta
//
//  Created by Riley Testut on 2/5/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

extension UIImage
{
    convenience init?(symbolNameIfAvailable name: String)
    {
        if #available(iOS 13, tvOS 13, *)
        {
            self.init(systemName: name)
        }
        else
        {
            return nil
        }
    }
}
