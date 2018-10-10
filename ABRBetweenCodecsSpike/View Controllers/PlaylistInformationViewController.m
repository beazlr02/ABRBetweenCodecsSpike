//
//  PlaylistInformationViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 01/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "PlaylistInformationViewController.h"
#import "ChooseItemTableViewController.h"
#import "PlaylistRepository.h"
#import "Player.h"

@interface PlaylistInformationViewController () <PlayerDelegate>
@end

@implementation PlaylistInformationViewController {
    Player *_player;
    NSURL *_defaultPlayableItemURL;
    id _variantChangedFeedbackGenerator;
    UILongPressGestureRecognizer *_longPressCurrentPlaylistLabel;
    
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
    
    [_player beginPlaybackOfContentsFromURL:URL];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark Action Outlets

- (IBAction)segmentControlValueDidChange:(UISegmentedControl *)sender
{
    [_player capPlaybackBitrateToBitrateAtIndex:[sender selectedSegmentIndex]];
}

#pragma mark Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _player = [[Player alloc] init];
    [_player setDelegate:self];
    
    _defaultPlayableItemURL = [PlaylistRepository radioOne];
    
    if (@available(iOS 10.0, *)) {
        _variantChangedFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    }
    
    _longPressCurrentPlaylistLabel = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedPlaylistURLLabel:)];
    [_currentPlaylistLabel addGestureRecognizer:_longPressCurrentPlaylistLabel];
    
    [_player beginPlaybackOfContentsFromURL:_defaultPlayableItemURL];
}

#pragma mark PlayerDelegate

- (void)player:(Player *)player willTransitionToPlayingFromContentsAtURL:(NSURL *)URL
{
    [_currentPlaylistLabel setText:[URL absoluteString]];
}

- (void)player:(Player *)player didProducePlaybackBitrateData:(PlayerBitrateData *)bitrateData
{
    [_variantChangedFeedbackGenerator impactOccurred];
    
    _indicatedBitrateLabel.text = [self stringRepresentationFromBitrate:bitrateData.indicatedBitrate];
    _switchBitrateLabel.text = [self stringRepresentationFromBitrate:bitrateData.switchBitrate];
}

- (void)player:(Player *)player didProduceAvailableVariantBitrates:(NSArray<NSNumber *> *)variantBitrates
{
    [_bitrateSelectionSegmentControl removeAllSegments];
    
    [variantBitrates enumerateObjectsUsingBlock:^(NSNumber *availableBitrateFromPlaylist, NSUInteger idx, __unused BOOL *stop) {
        NSString *bitrateString = [NSString stringWithFormat:@"%li", (long)[availableBitrateFromPlaylist integerValue]];
        [self->_bitrateSelectionSegmentControl insertSegmentWithTitle:bitrateString atIndex:idx animated:NO];
    }];
}

- (void)player:(Player *)player didCapPlaybackBitrateToVariantBitrateAtIndex:(NSUInteger)index
{
    [_bitrateSelectionSegmentControl setSelectedSegmentIndex:index];
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

- (NSString *)stringRepresentationFromBitrate:(double)bitrate
{
    return [NSString stringWithFormat:@"%i bits/s", (int)bitrate];
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
