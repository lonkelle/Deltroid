//
//  TVSwitch.swift
//  Deltroid
//
//  Created by Joseph Mattiello on 2/10/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

#if os(tvOS)
import Foundation
import UIKit

public typealias UISwitch = TVSwitch

@objc
@objcMembers
public class TVSwitch : UIButton {
    public var isOn: Bool = false {
        didSet {
            titleLabel?.text = isOn ? "On" : "Off"
            updateColor()
        }
    }
    var onTintColor: UIColor? = .systemGreen {
        didSet {
            updateColor()
        }
    }

    var offTintColor: UIColor? = .systemRed {
        didSet {
            updateColor()
        }
    }

    private func updateColor() {
        if isOn {
            titleLabel?.textColor = onTintColor ?? .label
        } else {
            titleLabel?.textColor = offTintColor ?? .label
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
		super.init(coder: coder)
    }
}

public typealias UISlider = TVSlider

public class TVSlider : UIButton {
    var value: Float = 0 {
        didSet {
            titleLabel?.text = "\(value)"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
		super.init(coder: coder)
    }
}
#endif
