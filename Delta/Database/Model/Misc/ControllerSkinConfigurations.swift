//
//  ControllerSkinConfigurations.swift
//  Deltroid
//
//  Created by ChatGPT on 2/21/23.
//  Copyright © 2023 Joseph Mattiello and the AI. All rights reserved.
//

public struct ControllerSkinConfigurations: OptionSet {
	let rawValue: Int16

	static let standardPortrait = ControllerSkinConfigurations(rawValue: 1 << 0)
	static let standardLandscape = ControllerSkinConfigurations(rawValue: 1 << 1)

	static let splitViewPortrait = ControllerSkinConfigurations(rawValue: 1 << 2)
	static let splitViewLandscape = ControllerSkinConfigurations(rawValue: 1 << 3)

	static let edgeToEdgePortrait = ControllerSkinConfigurations(rawValue: 1 << 4)
	static let edgeToEdgeLandscape = ControllerSkinConfigurations(rawValue: 1 << 5)
}
