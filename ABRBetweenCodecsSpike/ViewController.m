//
//  ViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 01/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "ViewController.h"
#import "ChooseItemTableViewController.h"
#import <AVFoundation/AVFoundation.h>

typedef NSArray<NSNumber *> BitratesArray;

@interface PlayableItem : NSObject

@property (nonatomic, strong, readonly) NSURL *playlistURL;
@property (nonatomic, copy, readonly) BitratesArray *variantBitrates;

+ (instancetype)defaultPlayableItem;
+ (instancetype)playableItemWithPlaylistURL:(NSURL *)playlistURL variantBitrates:(BitratesArray *)variantBitrates;

@end

@implementation PlayableItem

+ (instancetype)defaultPlayableItem
{
    NSURL *URL = [NSURL URLWithString:@"http://as-hls-uk-live.akamaized.net/pool_6/live/bbc_radio_one/bbc_radio_one.isml/.m3u8"];
    NSArray *availableBitrates = @[@(56000), @(112000), @(150000), @(374000)];
    
    return [self playableItemWithPlaylistURL:URL variantBitrates:availableBitrates];
}

+ (instancetype)playableItemWithPlaylistURL:(NSURL *)playlistURL variantBitrates:(BitratesArray *)variantBitrates
{
    PlayableItem *item = [[self alloc] init];
    item->_playlistURL = playlistURL;
    item->_variantBitrates = [variantBitrates copy];
    
    return item;
}

@end

@implementation ViewController {
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    BitratesArray *_availableBitratesWithinTestPlaylist;
    
    __weak IBOutlet UISegmentedControl *_bitrateSelectionSegmentControl;
    __weak IBOutlet UILabel *_currentPlaylistLabel;
    __weak IBOutlet UILabel *_indicatedBitrateLabel;
    __weak IBOutlet UILabel *_switchBitrateLabel;
}

#pragma mark Unwind Segues

- (IBAction)unwindFromSelectItemSegue:(UIStoryboardSegue *)segue
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)unwindFromSelectItemViewControllerWithSelectedURLSegue:(UIStoryboardSegue *)segue
{
    PlayableItem *item = [PlayableItem defaultPlayableItem];
    ChooseItemTableViewController *chooseItemViewController = (ChooseItemTableViewController *)[segue sourceViewController];
    if ([chooseItemViewController isKindOfClass:[ChooseItemTableViewController class]]) {
        NSURL *URL = [chooseItemViewController playlistURL];
        if (URL) {
            item = [PlayableItem playableItemWithPlaylistURL:URL variantBitrates:item.variantBitrates];
        }
    }
    
    [self swapPlayingItemToItem:item];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark Action Outlets

- (IBAction)segmentControlValueDidChange:(UISegmentedControl *)sender
{
    NSNumber *bitrate = _availableBitratesWithinTestPlaylist[sender.selectedSegmentIndex];
    [self updatePlayerItemBitrateWithBitrate:bitrate];
}

#pragma mark Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _player = [[AVPlayer alloc] init];
    [self swapToDefaultTestPlaylist];
}

#pragma mark Private

- (void)playerItemAccessLogDidProcessNewEntry:(NSNotification *)notification
{
    AVPlayerItemAccessLog *accessLog = [_playerItem accessLog];
    AVPlayerItemAccessLogEvent *lastEvent = [[accessLog events] lastObject];
    
    NSDictionary *info = @{@"switchBitrate": @(lastEvent.switchBitrate),
                           @"indicatedBitrate": @(lastEvent.indicatedBitrate)
                           };
    
    _indicatedBitrateLabel.text = [self stringRepresentationFromBitrate:lastEvent.indicatedBitrate];
    _switchBitrateLabel.text = [self stringRepresentationFromBitrate:lastEvent.switchBitrate];
    
    NSLog(@"%@", info);
}

- (void)updatePlayerItemBitrateWithBitrate:(NSNumber *)bitrate
{
    _playerItem.preferredPeakBitRate = [bitrate doubleValue];
}

- (NSString *)stringRepresentationFromBitrate:(double)bitrate
{
    return [NSString stringWithFormat:@"%i bits/s", (int)bitrate];
}

- (void)swapPlayingItemToItem:(PlayableItem *)playableItem
{
    [_bitrateSelectionSegmentControl removeAllSegments];
    _availableBitratesWithinTestPlaylist = playableItem.variantBitrates;
    
    [_availableBitratesWithinTestPlaylist enumerateObjectsUsingBlock:^(NSNumber *availableBitrateFromPlaylist, NSUInteger idx, __unused BOOL *stop) {
        NSString *bitrateString = [NSString stringWithFormat:@"%li", [availableBitrateFromPlaylist integerValue]];
        [self->_bitrateSelectionSegmentControl insertSegmentWithTitle:bitrateString atIndex:idx animated:NO];
    }];
    
    [_bitrateSelectionSegmentControl setSelectedSegmentIndex:0];
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:playableItem.playlistURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemNewAccessLogEntryNotification
                                                      object:_playerItem];
    }
    
    _playerItem = playerItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemAccessLogDidProcessNewEntry:)
                                                 name:AVPlayerItemNewAccessLogEntryNotification
                                               object:_playerItem];

    [self updatePlayerItemBitrateWithBitrate:[_availableBitratesWithinTestPlaylist firstObject]];
    [_player play];
    
    _currentPlaylistLabel.text = [playableItem.playlistURL absoluteString];
}

- (void)swapToDefaultTestPlaylist
{
    PlayableItem *defaultItem = [PlayableItem defaultPlayableItem];
    [self swapPlayingItemToItem:defaultItem];
}

@end
