//
//  ViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 01/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "ViewController.h"
#import "ChooseItemTableViewController.h"
#import "FetchBitratesOperation.h"
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
    UIImpactFeedbackGenerator *_variantChangedFeedbackGenerator;
    UILongPressGestureRecognizer *_longPressCurrentPlaylistLabel;
    NSOperationQueue *_parseBitratesOperationQueue;
    
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
    _variantChangedFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    
    _longPressCurrentPlaylistLabel = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedPlaylistURLLabel:)];
    [_currentPlaylistLabel addGestureRecognizer:_longPressCurrentPlaylistLabel];
    
    _parseBitratesOperationQueue = [[NSOperationQueue alloc] init];
    [_parseBitratesOperationQueue setName:@"Parse Bitrates From Playlist"];
    [_parseBitratesOperationQueue setQualityOfService:NSQualityOfServiceUtility];
    
    [self swapToDefaultTestPlaylist];
}

#pragma mark Private

- (void)longPressedPlaylistURLLabel:(UILongPressGestureRecognizer *)gestureRecognizer
{
    BOOL gestureRecognized = [gestureRecognizer state] == UIGestureRecognizerStateRecognized;
    if (gestureRecognized) {
        UIView *targetView = [gestureRecognizer view];
        [self showCopyMenuFromView:targetView];
    }
}

- (void)playerItemAccessLogDidProcessNewEntry:(NSNotification *)notification
{
    [_variantChangedFeedbackGenerator impactOccurred];
    
    AVPlayerItemAccessLog *accessLog = [_playerItem accessLog];
    AVPlayerItemAccessLogEvent *lastEvent = [[accessLog events] lastObject];
    
    _indicatedBitrateLabel.text = [self stringRepresentationFromBitrate:lastEvent.indicatedBitrate];
    _switchBitrateLabel.text = [self stringRepresentationFromBitrate:lastEvent.switchBitrate];
}

- (void)updatePlayerItemBitrateWithBitrate:(NSNumber *)bitrate
{
    _playerItem.preferredPeakBitRate = [bitrate doubleValue];
}

- (NSString *)stringRepresentationFromBitrate:(double)bitrate
{
    return [NSString stringWithFormat:@"%i bits/s", (int)bitrate];
}

- (void)updateVariantBitratesWithBitrates:(NSArray<NSNumber *> *)bitrates
{
    [_bitrateSelectionSegmentControl removeAllSegments];
    
    _availableBitratesWithinTestPlaylist = bitrates;
    [_availableBitratesWithinTestPlaylist enumerateObjectsUsingBlock:^(NSNumber *availableBitrateFromPlaylist, NSUInteger idx, __unused BOOL *stop) {
        NSString *bitrateString = [NSString stringWithFormat:@"%li", [availableBitrateFromPlaylist integerValue]];
        [self->_bitrateSelectionSegmentControl insertSegmentWithTitle:bitrateString atIndex:idx animated:NO];
    }];
    
    [_bitrateSelectionSegmentControl setSelectedSegmentIndex:0];
    [self updatePlayerItemBitrateWithBitrate:[bitrates firstObject]];
}

- (void)swapPlayingItemToItem:(PlayableItem *)playableItem
{
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
    
    [_player play];
    
    _currentPlaylistLabel.text = [playableItem.playlistURL absoluteString];
    
    [self updateVariantBitratesWithBitrates:@[]];
    
    __weak typeof(self) weakSelf = self;
    FetchBitratesOperation *fetchBitratesOperation = [[FetchBitratesOperation alloc] initWithPlaylistURL:[playableItem playlistURL] completionHandler:^(NSArray<NSNumber *> *bitrates) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateVariantBitratesWithBitrates:bitrates];
        });
    }];
    
    [_parseBitratesOperationQueue addOperation:fetchBitratesOperation];
}

- (void)swapToDefaultTestPlaylist
{
    PlayableItem *defaultItem = [PlayableItem defaultPlayableItem];
    [self swapPlayingItemToItem:defaultItem];
}

- (void)showCopyMenuFromView:(UIView *)targetView
{
    [_currentPlaylistLabel becomeFirstResponder];
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setTargetRect:[targetView frame]
                           inView:[targetView superview]];
    [menuController setMenuVisible:YES animated:YES];
}

@end
