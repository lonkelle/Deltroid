//
//  NSFetchedResultsController+Conveniences.swift
//  Delta
//
//  Created by Joseph Mattiello on 2/21/23.
//  Copyright © 2023 Joseph Mattiello. All rights reserved.
//

import Roxas
import CoreData
import os.log

internal extension NSFetchedResultsController {
	@objc func performFetchIfNeeded() -> Bool {
		guard self.sections == nil else { return false }
		do {
			_ = try performFetch()
			return true
		} catch {
			os_log("%@", type: .error, error.localizedDescription)
			return false
		}
	}
}
