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
#import "PlaylistRepository.h"
#import <AVFoundation/AVFoundation.h>

typedef NSArray<NSNumber *> BitratesArray;

@implementation ViewController {
    NSURL *_defaultPlayableItemURL;
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
    NSURL *URL = _defaultPlayableItemURL;
    ChooseItemTableViewController *chooseItemViewController = (ChooseItemTableViewController *)[segue sourceViewController];
    if ([chooseItemViewController isKindOfClass:[ChooseItemTableViewController class]]) {
        NSURL *chosenURL = [chooseItemViewController playlistURL];
        if (chosenURL) {
            URL = chosenURL;
        }
    }
    
    [self beginPlayingContentAtURL:URL];
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
    
    _defaultPlayableItemURL = [PlaylistRepository radioOne];
    
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

- (void)beginPlayingContentAtURL:(NSURL *)playableItem
{
    AVAsset *asset = [AVURLAsset URLAssetWithURL:playableItem options:nil];
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
    
    _currentPlaylistLabel.text = [playableItem absoluteString];
    
    __weak typeof(self) weakSelf = self;
    FetchBitratesOperation *fetchBitratesOperation = [[FetchBitratesOperation alloc] initWithPlaylistURL:playableItem completionHandler:^(NSArray<NSNumber *> *bitrates) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateVariantBitratesWithBitrates:bitrates];
        });
    }];
    
    [_parseBitratesOperationQueue addOperation:fetchBitratesOperation];
}

- (void)swapToDefaultTestPlaylist
{
    [self beginPlayingContentAtURL:_defaultPlayableItemURL];
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
