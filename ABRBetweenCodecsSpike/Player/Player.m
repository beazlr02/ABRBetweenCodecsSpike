//
//  Player.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 03/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "Player.h"
#import "FetchBitratesOperation.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerBitrateData ()

- (instancetype)initWithIndicatedBitrate:(double)indicatedBitrate switchBitrate:(double)switchBitrate;

@end

@implementation Player {
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    NSOperationQueue *_parseBitratesOperationQueue;
    NSArray<NSNumber *> *_variantBitrates;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _player = [[AVPlayer alloc] init];
        
        _parseBitratesOperationQueue = [[NSOperationQueue alloc] init];
        [_parseBitratesOperationQueue setName:@"Parse Bitrates From Playlist"];
        [_parseBitratesOperationQueue setQualityOfService:NSQualityOfServiceUtility];
    }
    
    return self;
}

- (void)capPlaybackBitrateToBitrateAtIndex:(NSUInteger)variantIndex
{
    NSNumber *variantBitrate = [_variantBitrates objectAtIndex:variantIndex];
    [_playerItem setPreferredPeakBitRate:[variantBitrate doubleValue]];
    [[self delegate] player:self didCapPlaybackBitrateToVariantBitrateAtIndex:variantIndex];
}

- (void)beginPlaybackOfContentsFromURL:(NSURL *)URL
{
    [[self delegate] player:self willTransitionToPlayingFromContentsAtURL:URL];
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemNewAccessLogEntryNotification
                                                      object:_playerItem];
    }
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    _playerItem = playerItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemAccessLogDidProcessNewEntry:)
                                                 name:AVPlayerItemNewAccessLogEntryNotification
                                               object:_playerItem];
    
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    [_player play];
    
    __weak typeof(self) weakSelf = self;
    FetchBitratesOperation *fetchBitratesOperation = [[FetchBitratesOperation alloc] initWithPlaylistURL:URL completionHandler:^(NSArray<NSNumber *> *bitrates) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf variantBitratesAvailable:bitrates];
        });
    }];
    
    [_parseBitratesOperationQueue addOperation:fetchBitratesOperation];
}

- (void)playerItemAccessLogDidProcessNewEntry:(NSNotification *)notification
{
    AVPlayerItem *playerItem = (AVPlayerItem *)[notification object];
    AVPlayerItemAccessLog *accessLog = [playerItem accessLog];
    AVPlayerItemAccessLogEvent *lastEvent = [[accessLog events] lastObject];
    
    PlayerBitrateData *data = [[PlayerBitrateData alloc] initWithIndicatedBitrate:lastEvent.indicatedBitrate
                                                                    switchBitrate:lastEvent.switchBitrate];
    [[self delegate] player:self didProducePlaybackBitrateData:data];
}

- (void)variantBitratesAvailable:(NSArray<NSNumber *> *)variantBitrates
{
    _variantBitrates = variantBitrates;
    [[self delegate] player:self didProduceAvailableVariantBitrates:variantBitrates];
    
    if ([variantBitrates count] > 0) {
        [self capPlaybackBitrateToBitrateAtIndex:0];
    }
}

@end

@implementation PlayerBitrateData

- (instancetype)initWithIndicatedBitrate:(double)indicatedBitrate switchBitrate:(double)switchBitrate
{
    self = [super init];
    if (self) {
        _indicatedBitrate = indicatedBitrate;
        _switchBitrate = switchBitrate;
    }
    
    return self;
}

@end
