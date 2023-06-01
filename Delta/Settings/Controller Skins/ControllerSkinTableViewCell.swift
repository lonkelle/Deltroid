//
//  ControllerSkinTableViewCell.swift
//  Delta
//
//  Created by Riley Testut on 10/27/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif



class ControllerSkinTableViewCell: UITableViewCell
{
    @IBOutlet var controllerSkinImageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }

}
