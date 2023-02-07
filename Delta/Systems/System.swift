//
//  System.swift
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
#if canImport(MelonDSDeltaCore.MelonDS)
import MelonDSDeltaCore
#endif
#if canImport(GPGXDeltaCore)
import GPGXDeltaCore
#endif

// Legacy Cores
#if canImport(DSDeltaCore.DS)
import struct DSDeltaCore.DS
#endif

enum System: CaseIterable
{
    case nes
    case genesis
    case snes
    case n64
    case gbc
    case gba
    case ds
    
    static var registeredSystems: [System] {
        let systems = System.allCases.filter { Delta.registeredCores.keys.contains($0.gameType) }
        return systems
    }
    
    static var allCores: [DeltaCoreProtocol] {
        var _allCores: [DeltaCoreProtocol] = [DeltaCoreProtocol]()
#if canImport(SNESDeltaCore)
        _allCores.append(SNES.core)
#endif
#if canImport(GBADeltaCore)
        _allCores.append(GBA.core)
#endif
#if canImport(GBCDeltaCore)
        _allCores.append(GBC.core)
#endif
#if canImport(NESDeltaCore)
        _allCores.append(NES.core)
#endif
#if canImport(N64DeltaCore)
        _allCores.append(N64.core)
#endif
#if canImport(MelonDSDeltaCore.MelonDS)
        _allCores.append(MelonDS.core)
#endif
#if canImport(GPGXDeltaCore)
        _allCores.append(GPGX.core)
#endif
        return _allCores
    }
}

extension System
{
    var localizedName: String {
        switch self
        {
        case .nes: return NSLocalizedString("Nintendo", comment: "")
        case .snes: return NSLocalizedString("Super Nintendo", comment: "")
        case .n64: return NSLocalizedString("Nintendo 64", comment: "")
        case .gbc: return NSLocalizedString("Game Boy Color", comment: "")
        case .gba: return NSLocalizedString("Game Boy Advance", comment: "")
        case .ds: return NSLocalizedString("Nintendo DS", comment: "")
        case .genesis: return NSLocalizedString("Sega Genesis", comment: "")
        }
    }
    
    var localizedShortName: String {
        switch self
        {
        case .nes: return NSLocalizedString("NES", comment: "")
        case .snes: return NSLocalizedString("SNES", comment: "")
        case .n64: return NSLocalizedString("N64", comment: "")
        case .gbc: return NSLocalizedString("GBC", comment: "")
        case .gba: return NSLocalizedString("GBA", comment: "")
        case .ds: return NSLocalizedString("DS", comment: "")
        case .genesis: return NSLocalizedString("Genesis (Beta)", comment: "")
        }
    }
    
    var year: Int {
        switch self
        {
        case .nes: return 1985
        case .genesis: return 1989
        case .snes: return 1990
        case .n64: return 1996
        case .gbc: return 1998
        case .gba: return 2001
        case .ds: return 2004
        }
    }
}

extension System
{
    var deltaCore: DeltaCoreProtocol {
        switch self
        {
#if canImport(SNESDeltaCore)
        case .snes: return SNES.core
#endif
#if canImport(GBADeltaCore)
        case .gba: return GBA.core
#endif
#if canImport(GBCDeltaCore)
        case .gbc: return GBC.core
#endif
#if canImport(NESDeltaCore)
        case .nes: return NES.core
#endif
#if canImport(N64DeltaCore)
        case .n64: return N64.core
#endif
#if canImport(MelonDSDeltaCore.MelonDS)
        case .ds: return Settings.preferredCore(for: .ds) ?? MelonDS.core
#endif
#if canImport(GPGXDeltaCore)
        case .genesis: return GPGX.core
#endif
        default: fatalError("Shouldn't hit a switch case we don't import")
        }
    }
    
    var gameType: DeltaCore.GameType {
        switch self
        {
#if canImport(SNESDeltaCore)
        case .snes: return .snes
#endif
#if canImport(GBADeltaCore)
        case .gba: return .gba
#endif
#if canImport(GBCDeltaCore)
        case .gbc: return .gbc
#endif
#if canImport(NESDeltaCore)
        case .nes: return .nes
#endif
#if canImport(N64DeltaCore)
        case .n64: return .n64
#endif
#if canImport(MelonDSDeltaCore.MelonDS)
        case .ds: return .ds
#endif
#if canImport(GPGXDeltaCore)
        case .genesis: return .genesis
#endif
        default: fatalError("Shouldn't hit a switch case we don't import")
        }
    }
    
    init?(gameType: DeltaCore.GameType)
    {
        switch gameType
        {
#if canImport(SNESDeltaCore)
        case GameType.snes: self = .snes
#endif
#if canImport(GBADeltaCore)
        case GameType.gba: self = .gba
#endif
#if canImport(GBCDeltaCore)
        case GameType.gbc: self = .gbc
#endif
#if canImport(NESDeltaCore)
        case GameType.nes: self = .nes
#endif
#if canImport(N64DeltaCore)
        case GameType.n64: self = .n64
#endif
#if canImport(MelonDSDeltaCore.MelonDS)
        case GameType.ds: self = .ds
#endif
#if canImport(GPGXDeltaCore)
        case GameType.genesis: self = .genesis
#endif
        default: return nil
        }
    }
}

extension DeltaCore.GameType
{
    init?(fileExtension: String)
    {
        switch fileExtension.lowercased()
        {
#if canImport(SNESDeltaCore)
        case "smc", "sfc", "fig": self = .snes
#endif
#if canImport(GBADeltaCore)
        case "gba": self = .gba
#endif
#if canImport(GBCDeltaCore)
        case "gbc", "gb": self = .gbc
#endif
#if canImport(NESDeltaCore)
        case "nes": self = .nes
#endif
#if canImport(N64DeltaCore)
        case "n64", "z64": self = .n64
#endif
#if canImport(MelonDSDeltaCore.MelonDS)
        case "ds", "nds": self = .ds
#endif
#if canImport(GPGXDeltaCore)
        case "gen", "bin", "md", "smd": self = .genesis
#endif
        default: return nil
        }
    }
}
