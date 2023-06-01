//
//  iTunesImportOption.swift
//  Delta
//
//  Created by Riley Testut on 5/1/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

import DeltaCore
import os.log

struct iTunesImportOption: ImportOption
{
    let title = NSLocalizedString("iTunes", comment: "")
    let image: UIImage? = UIImage(symbolNameIfAvailable: "music.note")
    
    private let presentingViewController: UIViewController
    
    init(presentingViewController: UIViewController)
    {
        self.presentingViewController = presentingViewController
    }
    
    func `import`(withCompletionHandler completionHandler: @escaping (Set<URL>?) -> Void)
    {
        let alertController = UIAlertController(title: NSLocalizedString("Import from iTunes?", comment: ""), message: NSLocalizedString("Delta will import the games and controller skins copied over via iTunes.", comment: ""), preferredStyle: .alert)
        
        let importAction = UIAlertAction(title: NSLocalizedString("Import", comment: ""), style: .default) { action in
            
            var importedURLs = Set<URL>()
            
            let documentsDirectoryURL = DatabaseManager.defaultDirectoryURL().deletingLastPathComponent()
			os_log("Checking for files to import at path: <%@>", type: .info, documentsDirectoryURL.absoluteString)
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: documentsDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                let itemURLs = contents.filter { GameType(fileExtension: $0.pathExtension) != nil || $0.pathExtension.lowercased() == "zip" || $0.pathExtension.lowercased() == "deltaskin" }
                
                for url in itemURLs {
                    let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    
                    do {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        
                        try FileManager.default.moveItem(at: url, to: destinationURL)
                        importedURLs.insert(destinationURL)
                    } catch {
						os_log("Error importing file at URL %@ : %@", type: .error, url.absoluteString, error.localizedDescription)
                    }
                }
                
            } catch {
				os_log("Error importing files: %@", type: .error, error.localizedDescription)
            }
            
            completionHandler(importedURLs)
        }
        alertController.addAction(importAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { action in
            completionHandler(nil)
        }
        alertController.addAction(cancelAction)
        
        self.presentingViewController.present(alertController, animated: true, completion: nil)
    }
}
