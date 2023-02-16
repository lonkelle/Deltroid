//
//  CheatTableViewCell.swift
//  Delta
//
//  Created by Riley Testut on 8/8/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif



class CheatTableViewCell: UITableViewCell
{
    @IBOutlet private var vibrancyView: UIVisualEffectView!
    
    override func layoutSubviews()
    {
        if let textLabel = self.textLabel
        {
            self.vibrancyView.contentView.addSubview(textLabel)
        }
        
        if let detailTextLabel = self.detailTextLabel
        {
            self.vibrancyView.contentView.addSubview(detailTextLabel)
        }
        
        super.layoutSubviews()
    }
}
