//
//  ClipboardImportOption.swift
//  Delta
//
//  Created by Riley Testut on 5/1/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

#if !os(tvOS) && !os(macOS)

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
#if canImport(MobileCoreServices)
import MobileCoreServices
#else
import CoreServices
#endif
import Roxas
#if canImport(RoxasUIKit)
import RoxasUIKit
#endif

struct ClipboardImportOption: ImportOption {
    let title = NSLocalizedString("Clipboard", comment: "")
    let image: UIImage? = nil
    
    func `import`(withCompletionHandler completionHandler: @escaping (Set<URL>?) -> Void) {
        guard UIPasteboard.general.hasImages else { return completionHandler([]) }
                
        guard let image = UIPasteboard.general.image,
              let rotatedImage = image.rotatedToIntrinsicOrientation(),
              let data = rotatedImage.pngData()
        else { return completionHandler([]) }
        do {
            let temporaryURL = FileManager.default.uniqueTemporaryURL()
            try data.write(to: temporaryURL, options: .atomic)
            
            completionHandler([temporaryURL])
        } catch {
            print("Error: \(error.localizedDescription)")
            completionHandler([])
        }
    }
}
#endif
