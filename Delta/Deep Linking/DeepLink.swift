//
//  DeepLink.swift
//  Delta
//
//  Created by Riley Testut on 12/29/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

extension URL
{
    init(action: DeepLink.Action)
    {
        switch action
        {
        case .launchGame(let identifier):
            let deepLinkURL = URL(string: "delta://\(action.type.rawValue)/\(identifier)")!
            self = deepLinkURL
        }
    }
}

#if !os(tvOS) && !os(macOS)
extension UIApplicationShortcutItem
{
    convenience init(localizedTitle: String, action: DeepLink.Action)
    {
        var userInfo: [String: NSSecureCoding]?
        
        switch action
        {
        case .launchGame(let identifier): userInfo = [DeepLink.Key.identifier.rawValue: identifier as NSString]
        }
        
        self.init(type: action.type.rawValue, localizedTitle: localizedTitle, localizedSubtitle: nil, icon: nil, userInfo: userInfo)
    }
}
#endif

extension DeepLink
{
    enum Action
    {
        case launchGame(identifier: String)
        
        var type: ActionType {
            switch self
            {
            case .launchGame: return .launchGame
            }
        }
    }
    
    enum ActionType: String
    {
        case launchGame = "game"
    }
    
    enum Key: String
    {
        case identifier
        case game
    }
}

enum DeepLink
{
    case url(URL)
#if !os(tvOS) && !os(macOS)
    case shortcut(UIApplicationShortcutItem)
#endif
    var actionType: ActionType? {
        switch self
        {
        case .url(let url):
            guard let host = url.host else { return nil }
            
            let type = ActionType(rawValue: host)
            return type
#if !os(tvOS) && !os(macOS)
        case .shortcut(let shortcut):
            let type = ActionType(rawValue: shortcut.type)
            return type
            #endif
        }
    }
    
    var action: Action? {
        guard let type = self.actionType else { return nil }
        
        switch (self, type)
        {
        case (.url(let url), .launchGame):
            let identifier = url.lastPathComponent
            return .launchGame(identifier: identifier)
#if !os(tvOS) && !os(macOS)
        case (.shortcut(let shortcut), .launchGame):
            guard let identifier = shortcut.userInfo?[Key.identifier.rawValue] as? String else { return nil }
            return .launchGame(identifier: identifier)
#endif
        }
    }
}
