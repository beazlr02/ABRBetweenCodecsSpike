//
//  ViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 01/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@implementation ViewController {
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    NSArray<NSNumber *> *_indexedBitratesWithinSegmentControl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _indexedBitratesWithinSegmentControl = @[@(56000), @(112000), @(150000), @(374000)];
    
    NSURL *playlistURL = [NSURL URLWithString:@"http://as-hls-uk-live.akamaized.net/pool_6/live/bbc_radio_one/bbc_radio_one.isml/.m3u8"];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:playlistURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    
    _playerItem = playerItem;
    _player = player;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemAccessLogDidProcessNewEntry:) name:AVPlayerItemNewAccessLogEntryNotification object:_playerItem];
    
    [self updatePlayerItemBitrateWithBitrate:[_indexedBitratesWithinSegmentControl firstObject]];
    [player setVolume:0.01];
    [player play];
}

- (void)playerItemAccessLogDidProcessNewEntry:(NSNotification *)notification
{
    AVPlayerItemAccessLog *accessLog = [_playerItem accessLog];
    AVPlayerItemAccessLogEvent *lastEvent = [[accessLog events] lastObject];
    
    NSDictionary *info = @{@"observedBitrate": @(lastEvent.observedBitrate),
                           @"switchBitrate": @(lastEvent.switchBitrate),
                           @"indicatedBitrate": @(lastEvent.indicatedBitrate)
                           };
    
    NSLog(@"%@", info);
}

- (void)updatePlayerItemBitrateWithBitrate:(NSNumber *)bitrate
{
    _playerItem.preferredPeakBitRate = [bitrate doubleValue];
}

- (IBAction)segmentControlValueDidChange:(UISegmentedControl *)sender
{
    NSNumber *bitrate = _indexedBitratesWithinSegmentControl[sender.selectedSegmentIndex];
    [self updatePlayerItemBitrateWithBitrate:bitrate];
}

@end
