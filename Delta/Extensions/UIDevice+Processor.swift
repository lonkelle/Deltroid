	//
	//  UIDevice+Processor.swift
	//  Delta
	//
	//  Created by Riley Testut on 9/21/19.
	//  Copyright © 2019 Riley Testut. All rights reserved.
	//

#if canImport(UIKit)
import UIKit

#if canImport(ARKit)
import ARKit
#endif
import Metal

extension UIDevice {
	private static var mtlDevice: MTLDevice? = MTLCreateSystemDefaultDevice()

	var hasA9ProcessorOrBetter: Bool {
			// ARKit is only supported by devices with an A9 processor or better, according to the documentation.
			// https://developer.apple.com/documentation/arkit/arconfiguration/2923553-issupported
#if canImport(ARKit)
		return ARConfiguration.isSupported
#else
			// TODO: This needs another method to find
		return true
#endif
	}

	var hasA11ProcessorOrBetter: Bool {
		guard let mtlDevice = UIDevice.mtlDevice else { return false }
#if os(tvOS)
			// TODO: This is wrong for tvOS, A10+ is the only way to use mtl features
			// need another api
		return mtlDevice.supportsFeatureSet(.tvOS_GPUFamily2_v2) // iOS GPU Family 4 = A11 GPU
#elseif targetEnvironment(macCatalyst)
		return true
#else
		return mtlDevice.supportsFeatureSet(.iOS_GPUFamily4_v1) // iOS GPU Family 4 = A11 GPU
#endif
	}

	var supportsJIT: Bool {
#if targetEnvironment(macCatalyst)
		return true
#else
		guard #available(iOS 14.0, tvOS 14.0, *) else { return false }

			// JIT is supported on devices with an A12 processor or better running iOS 14.0 or later.
			// ARKit 3 is only supported by devices with an A12 processor or better, according to the documentation.
#if canImport(ARKit)
		return ARBodyTrackingConfiguration.isSupported
#else
			// TODO: Figure out equivlant for tvOS
		return true
#endif
#endif // Catalyst
	}
}
#endif // UIKit
