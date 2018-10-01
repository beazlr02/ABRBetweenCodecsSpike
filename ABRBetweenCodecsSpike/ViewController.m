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
    __weak IBOutlet UISegmentedControl *_bitrateSelectionSegmentControl;
    NSArray<NSNumber *> *_availableBitratesWithinTestPlaylist;
    
    
    __weak IBOutlet UILabel *_indicatedBitrateLabel;
    __weak IBOutlet UILabel *_observedBitrateLabel;
    __weak IBOutlet UILabel *_switchBitrateLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_bitrateSelectionSegmentControl removeAllSegments];
    
    _availableBitratesWithinTestPlaylist = @[@(56000), @(112000), @(150000), @(374000)];
    [_availableBitratesWithinTestPlaylist enumerateObjectsUsingBlock:^(NSNumber *availableBitrateFromPlaylist, NSUInteger idx, __unused BOOL *stop) {
        NSString *bitrateString = [NSString stringWithFormat:@"%li", [availableBitrateFromPlaylist integerValue]];
        [self->_bitrateSelectionSegmentControl insertSegmentWithTitle:bitrateString atIndex:idx animated:NO];
    }];
    
    [_bitrateSelectionSegmentControl setSelectedSegmentIndex:0];
    
    NSURL *playlistURL = [NSURL URLWithString:@"http://as-hls-uk-live.akamaized.net/pool_6/live/bbc_radio_one/bbc_radio_one.isml/.m3u8"];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:playlistURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    
    _playerItem = playerItem;
    _player = player;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemAccessLogDidProcessNewEntry:) name:AVPlayerItemNewAccessLogEntryNotification object:_playerItem];
    
    [self updatePlayerItemBitrateWithBitrate:[_availableBitratesWithinTestPlaylist firstObject]];
    [player setVolume:1];
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
    
    _indicatedBitrateLabel.text = [NSString stringWithFormat:@"Indicated Bitrate: %i", (int)lastEvent.indicatedBitrate];
    _observedBitrateLabel.text = [NSString stringWithFormat:@"Observed Bitrate: %i", (int)lastEvent.observedBitrate];
    _switchBitrateLabel.text = [NSString stringWithFormat:@"Switch Bitrate: %i", (int)lastEvent.switchBitrate];
    
    NSLog(@"%@", info);
}

- (void)updatePlayerItemBitrateWithBitrate:(NSNumber *)bitrate
{
    _playerItem.preferredPeakBitRate = [bitrate doubleValue];
}

- (IBAction)segmentControlValueDidChange:(UISegmentedControl *)sender
{
    NSNumber *bitrate = _availableBitratesWithinTestPlaylist[sender.selectedSegmentIndex];
    [self updatePlayerItemBitrateWithBitrate:bitrate];
}

@end
