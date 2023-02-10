//
//  DeltaCoreProtocol+Delta.swift
//  Delta
//
//  Created by Riley Testut on 4/30/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import DeltaCore

#if canImport(SNESDeltaCore)
import SNESDeltaCore
#endif
#if canImport(GBADeltaCore)
import GBADeltaCore
#endif
#if canImport(GBCDeltaCore)
import GBCDeltaCore
#endif
#if canImport(NESDeltaCore)
import NESDeltaCore
#endif
#if canImport(N64DeltaCore)
import N64DeltaCore
#endif
#if canImport(melonDSDeltaCore)
import melonDSDeltaCore
#endif
#if canImport(GBCDeltaCore)
import GBCDeltaCore
#endif
#if canImport(GPGXDeltaCore)
import GPGXDeltaCore
#endif

// Legacy Cores
#if canImport(DSDeltaCore)
import struct DSDeltaCore.DS
#endif

@dynamicMemberLookup
struct DeltaCoreMetadata
{
    enum Key: CaseIterable
    {
        case name
        case developer
        case source
        case donate
    }
    
    struct Item
    {
        var value: String
        var url: URL?
    }
    
    var name: Item { self.items[.name]! }
    private let items: [Key: Item]
    
    init?(_ items: [Key: Item])
    {
        guard items.keys.contains(.name) else { return nil }
        self.items = items
    }
    
    subscript(dynamicMember keyPath: KeyPath<Key.Type, Key>) -> Item?
    {
        let key = Key.self[keyPath: keyPath]
        return self[key]
    }
    
    subscript(_ key: Key) -> Item?
    {
        let item = self.items[key]
        return item
    }
}

extension DeltaCoreProtocol
{
    var supportedRates: ClosedRange<Double> {
        return 1...self.maximumFastForwardSpeed
    }
    
    private var maximumFastForwardSpeed: Double {
        switch self
        {
#if canImport(NESDeltaCore)
        case NES.core: return 4
#endif
#if canImport(SNESDeltaCore)
        case SNES.core: return 4
#endif
#if canImport(GBCDeltaCore)
        case GBC.core: return 4
#endif
#if canImport(GBADeltaCore)
        case GBA.core: return 3
#endif
#if canImport(N64DeltaCore)
        case N64.core where UIDevice.current.hasA11ProcessorOrBetter: return 3
        case N64.core where UIDevice.current.hasA9ProcessorOrBetter: return 1.5
#endif
#if canImport(melonDSDeltaCore)
        case MelonDS.core where ProcessInfo.processInfo.isJITAvailable: return 3
        case MelonDS.core where UIDevice.current.hasA11ProcessorOrBetter: return 1.5
#endif
#if canImport(GPGXDeltaCore)
        case GPGX.core: return 4
#endif
        default: return 1
        }
    }
    
    var metadata: DeltaCoreMetadata? {
        switch self
        {
#if canImport(DSDeltaCore)
        case DS.core:
            return DeltaCoreMetadata([.name: .init(value: NSLocalizedString("DeSmuME (Legacy)", comment: ""), url: URL(string: "http://desmume.org")),
                                      .developer: .init(value: NSLocalizedString("DeSmuME team", comment: ""), url: URL(string: "https://wiki.desmume.org/index.php?title=DeSmuME:About")),
                                      .source: .init(value: NSLocalizedString("GitHub", comment: ""), url: URL(string: "https://github.com/TASVideos/desmume"))])
#endif
#if canImport(melonDSDeltaCore)
        case MelonDS.core:
            return DeltaCoreMetadata([.name: .init(value: NSLocalizedString("melonDS", comment: ""), url: URL(string: "http://melonds.kuribo64.net")),
                                      .developer: .init(value: NSLocalizedString("Arisotura", comment: ""), url: URL(string: "https://twitter.com/Arisotura")),
                                      .source: .init(value: NSLocalizedString("GitHub", comment: ""), url: URL(string: "https://github.com/Arisotura/melonDS")),
                                      .donate: .init(value: NSLocalizedString("Patreon", comment: ""), url: URL(string: "https://www.patreon.com/staplebutter"))])
#endif
        default: return nil
        }
    }
}
