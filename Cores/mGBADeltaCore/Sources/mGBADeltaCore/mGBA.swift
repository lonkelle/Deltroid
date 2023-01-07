//
//  mGBA.swift
//  mGBADeltaCore
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

import Foundation
import AVFoundation

import DeltaCore
@_exported import mGBABridge
@_exported import mGBASwift

extension mGBAGameInput: Input
{
    public var type: InputType {
        return .game(.gba)
    }
}

public struct mGBA: DeltaCoreProtocol
{
    public static let core = mGBA()
    
    public var name: String { "mGBA" }
    public var identifier: String { "com.rileytestut.mGBADeltaCore" }
    
    public var gameType: GameType { .gba }
    public var gameInputType: Input.Type { mGBAGameInput.self }
    public var gameSaveFileExtension: String { "sav" }
    
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.rgba8), dimensions: CGSize(width: 240, height: 160))

    public var supportedCheatFormats: Set<CheatFormat> {
        return []
    }

    public var emulatorBridge: EmulatorBridging { mGBAEmulatorBridge.shared as! EmulatorBridging }
    
    public var resourceBundle: Bundle { Bundle.module }
    
    private init()
    {
    }
}
