//
//  mGBAEmulatorBridge.h
//  mGBABridge
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import "mGBAEmulatorBridge.h"

//@import mGBA;
#include <mgba-util/common.h>

#include <mgba/core/blip_buf.h>
#include <mgba/core/core.h>
#include <mgba/core/cheats.h>
#include <mgba/core/serialize.h>
#include <mgba/gba/core.h>
#include <mgba/internal/gba/cheats.h>
#include <mgba/internal/gba/input.h>
#include <mgba-util/circle-buffer.h>
#include <mgba-util/memory.h>
#include <mgba-util/vfs.h>

#define SAMPLES 1024

@import Foundation;

@import DeltaCore;
@import mGBASwift;
//@import mGBA;

const char* const binaryName = "mGBA";

@interface mGBAEmulatorBridge ()
{
    struct mCore* core;
}

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;
@property (nonatomic, copy, nonnull, readonly) NSURL *gameSaveDirectoryURL;
@property (nonatomic, readonly) NSMutableData *videoBuffer;

@end

static void _log(struct mLogger* log,
                 int category,
                 enum mLogLevel level,
                 const char* format,
                 va_list args)
{}

static struct mLogger logger = { .log = _log };

@implementation mGBAEmulatorBridge
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;
@synthesize saveUpdateHandler = _saveUpdateHandler;

+ (instancetype)sharedBridge
{
    static mGBAEmulatorBridge *_emulatorBridge = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emulatorBridge = [[self alloc] init];
    });
    
    return _emulatorBridge;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        core = GBACoreCreate();
        mCoreInitConfig(core, nil);
        
        mLogSetDefaultLogger(&logger);
        
        struct mCoreOptions options = { .skipBios = true };
        mCoreConfigLoadDefaults(&core->config, &options);
        core->init(core);
    }
    
    return self;
}

#pragma mark - Emulation State -

- (void)startWithGameURL:(NSURL *)URL
{
    self.gameURL = URL;
    
    if (core->dirs.save) {
        core->dirs.save->close(core->dirs.save);
    }
    core->dirs.save = VDirOpen(self.gameSaveDirectoryURL.fileSystemRepresentation);
    
    struct VFile* rom = VFileOpen(URL.fileSystemRepresentation, O_RDONLY);
    core->loadROM(core, rom);
    
    unsigned width, height;
    core->desiredVideoDimensions(core, &width, &height);
    _videoBuffer = [[NSMutableData alloc] initWithLength:(width * height * BYTES_PER_PIXEL)];
    core->setVideoBuffer(core, _videoBuffer.mutableBytes, width);
    core->setAudioBufferSize(core, SAMPLES);

    blip_set_rates(core->getAudioChannel(core, 0), core->frequency(core), 32768);
    blip_set_rates(core->getAudioChannel(core, 1), core->frequency(core), 32768);
    
    mCoreAutoloadSave(core); // handles saving/loading battery saves automatically

    core->reset(core);
    
    return YES;
}

- (void)stop
{
    NSLog(@"<><><><><><><><> mGBA <> stop");
}

- (void)pause
{
    NSLog(@"<><><><><><><><> mGBA <> pause");
}

- (void)resume
{
    NSLog(@"<><><><><><><><> mGBA <> resume");
}

#pragma mark - Game Loop -

- (void)runFrameAndProcessVideo:(BOOL)processVideo
{
    core->runFrame(core);

    int16_t samples[SAMPLES * 2];
    size_t available = 0;
    available = blip_samples_avail(core->getAudioChannel(core, 0));
    blip_read_samples(core->getAudioChannel(core, 0), samples, (int)available, true);
    blip_read_samples(core->getAudioChannel(core, 1), samples + 1, (int)available, true);
    
    [self.audioRenderer.audioBuffer writeBuffer:samples size:available * 4];
    
    if (processVideo)
    {
        memcpy(self.videoRenderer.videoBuffer, self.videoBuffer.mutableBytes, self.videoBuffer.length);
        [self.videoRenderer processFrame];
    }
}

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)inputValue value:(double)value at:(NSInteger)playerIndex
{
    core->addKeys(core, 1 << inputValue);
}

- (void)deactivateInput:(NSInteger)inputValue at:(NSInteger)playerIndex
{
    core->clearKeys(core, 1 << inputValue);
}

- (void)resetInputs
{
    core->clearKeys(core, 1 << mGBAGameInputUp);
    core->clearKeys(core, 1 << mGBAGameInputDown);
    core->clearKeys(core, 1 << mGBAGameInputLeft);
    core->clearKeys(core, 1 << mGBAGameInputRight);
    core->clearKeys(core, 1 << mGBAGameInputA);
    core->clearKeys(core, 1 << mGBAGameInputB);
    core->clearKeys(core, 1 << mGBAGameInputL);
    core->clearKeys(core, 1 << mGBAGameInputR);
    core->clearKeys(core, 1 << mGBAGameInputStart);
    core->clearKeys(core, 1 << mGBAGameInputSelect);
}

#pragma mark - Game Saves -

- (void)saveGameSaveToURL:(NSURL *)URL
{
    NSLog(@"<><><><><><><><> mGBA <> saveGameSaveToURL");
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
    NSLog(@"<><><><><><><><> mGBA <> loadGameSaveFromURL");
}

#pragma mark - Save States -

- (void)saveSaveStateToURL:(NSURL *)URL
{
    struct VFile* vf = VFileOpen([URL fileSystemRepresentation], O_CREAT | O_TRUNC | O_RDWR);
    mCoreSaveStateNamed(core, vf, 0);
    vf->close(vf);
}

- (void)loadSaveStateFromURL:(NSURL *)URL
{
    struct VFile* vf = VFileOpen([URL fileSystemRepresentation], O_RDONLY);
    mCoreLoadStateNamed(core, vf, 0);
    vf->close(vf);
}

#pragma mark - Cheats -

- (BOOL)addCheatCode:(NSString *)cheatCode type:(NSString *)type
{
    return YES;
}

- (void)resetCheats
{
    NSLog(@"<><><><><><><><> mGBA <> resetCheats");
}

- (void)updateCheats
{
    NSLog(@"<><><><><><><><> mGBA <> updateCheats");
}

#pragma mark - Getters/Setters -

- (NSTimeInterval)frameDuration
{
    return (1.0 / 59.7275);
}

#pragma mark - Getters/Setters -

- (NSURL *)gameSaveDirectoryURL
{
    // the nature of using SPM doesn't allow the circular dependency of
    // exposing DeltaCore properties to Objective-C from mGBA.swift :(
    // since we cannot access mGBA.core.resourceBundle from here, create
    // a directory "Saves" alongside "Games" and "Save States" instead
    
    NSURL *gameSaveDirectoryURL = [[[[self.gameURL URLByDeletingPathExtension] URLByDeletingLastPathComponent] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"Saves" isDirectory:YES];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:gameSaveDirectoryURL withIntermediateDirectories:YES attributes:nil error:nil])
    {
        NSLog(@"Unable to create Game Save Directory. %@", error);
    }
    
    return gameSaveDirectoryURL;
}

@end
