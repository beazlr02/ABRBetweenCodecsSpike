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
    AVPlayerItem *_currentlyPlayingPlayerItem;
    NSOperationQueue *_playlistVariantBitratesParsingQueue;
    NSArray<NSNumber *> *_availableVariantBitratesFromCurrentPlaylist;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _player = [[AVPlayer alloc] init];
        
        _playlistVariantBitratesParsingQueue = [[NSOperationQueue alloc] init];
        [_playlistVariantBitratesParsingQueue setName:@"Parse Bitrates From Playlist"];
        [_playlistVariantBitratesParsingQueue setQualityOfService:NSQualityOfServiceUtility];
    }
    
    return self;
}

#pragma mark Bitrate Capping

- (void)capPlaybackBitrateToBitrateAtIndex:(NSUInteger)variantIndex
{
    [self setPeakBitrateToAvailableVariantBitrateAtIndex:variantIndex];
    [[self delegate] player:self didCapPlaybackBitrateToVariantBitrateAtIndex:variantIndex];
}

- (void)setPeakBitrateToAvailableVariantBitrateAtIndex:(NSUInteger)variantIndex
{
    NSNumber *variantBitrate = [_availableVariantBitratesFromCurrentPlaylist objectAtIndex:variantIndex];
    [_currentlyPlayingPlayerItem setPreferredPeakBitRate:[variantBitrate doubleValue]];
}

#pragma mark Playback

- (void)beginPlaybackOfContentsFromURL:(NSURL *)URL
{
    [self stopObservingNewAccessLogEntriesFromCurrentPlayerItem];
    [self beginPlayingContentAtURL:URL];
    [self fetchVariantBitratesFromPlaylistAtURL:URL];
}

- (void)stopObservingNewAccessLogEntriesFromCurrentPlayerItem
{
    if (_currentlyPlayingPlayerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemNewAccessLogEntryNotification
                                                      object:_currentlyPlayingPlayerItem];
    }
}

- (void)beginPlayingContentAtURL:(NSURL *)URL
{
    [[self delegate] player:self willTransitionToPlayingFromContentsAtURL:URL];
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    _currentlyPlayingPlayerItem = playerItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemAccessLogDidProcessNewEntry:)
                                                 name:AVPlayerItemNewAccessLogEntryNotification
                                               object:_currentlyPlayingPlayerItem];
    
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    [_player play];
}

- (void)fetchVariantBitratesFromPlaylistAtURL:(NSURL *)URL
{
    __weak typeof(self) weakSelf = self;
    __block NSArray<NSNumber *> *variantBitrates;
    FetchBitratesOperation *fetchBitratesOperation = [[FetchBitratesOperation alloc] initWithPlaylistURL:URL completionHandler:^(NSArray<NSNumber *> *bitrates) {
        variantBitrates = bitrates;
    }];
    
    NSBlockOperation *updateVariantBitratesOperation = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf updateCurrentVariantBitrates:variantBitrates];
    }];
    
    [updateVariantBitratesOperation addDependency:fetchBitratesOperation];
    [_playlistVariantBitratesParsingQueue addOperation:fetchBitratesOperation];
    [[NSOperationQueue mainQueue] addOperation:updateVariantBitratesOperation];
}

- (void)playerItemAccessLogDidProcessNewEntry:(NSNotification *)notification
{
    PlayerBitrateData * data = [self createCurrentBitrateDataFromNewAccessLogEntryNotification:notification];
    [[self delegate] player:self didProducePlaybackBitrateData:data];
}

- (void)updateCurrentVariantBitrates:(NSArray<NSNumber *> *)variantBitrates
{
    _availableVariantBitratesFromCurrentPlaylist = variantBitrates;
    [[self delegate] player:self didProduceAvailableVariantBitrates:variantBitrates];
    [self capPlaybackBitrateToFirstAvailableVariant];
}

- (void)capPlaybackBitrateToFirstAvailableVariant
{
    if ([_availableVariantBitratesFromCurrentPlaylist count] > 0) {
        [self capPlaybackBitrateToBitrateAtIndex:0];
    }
}

- (PlayerBitrateData *)createCurrentBitrateDataFromNewAccessLogEntryNotification:(NSNotification *)notification
{
    AVPlayerItem *playerItem = (AVPlayerItem *)[notification object];
    AVPlayerItemAccessLog *accessLog = [playerItem accessLog];
    AVPlayerItemAccessLogEvent *lastEvent = [[accessLog events] lastObject];
    
    return [[PlayerBitrateData alloc] initWithIndicatedBitrate:lastEvent.indicatedBitrate
                                                 switchBitrate:lastEvent.switchBitrate];
}

#pragma mark Recording

- (void)startRecording
{
    _recording = YES;
    [[self delegate] playerDidBeginRecording:self];
}

- (void)stopRecording
{
    _recording = NO;
    
    Recording *recording = [[Recording alloc] init];
    [[self delegate] player:self didProduceRecording:recording];
}

@end

#pragma mark -

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

#pragma mark -

@implementation Recording
@end
