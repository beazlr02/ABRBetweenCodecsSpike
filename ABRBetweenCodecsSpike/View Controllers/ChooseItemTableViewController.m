//
//  ChooseItemTableViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 02/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "ChooseItemTableViewController.h"
#import "PlaylistRepository.h"

@implementation ChooseItemTableViewController {
    NSArray<NSURL *> *_predefinedPlaylistURLs;
    __weak IBOutlet UITextField *_playlistURLTextField;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _predefinedPlaylistURLs = @[[PlaylistRepository radioOne],
                                [PlaylistRepository radioTwo],
                                [PlaylistRepository radioThree],
                                [PlaylistRepository radioFour],
                                [PlaylistRepository radioFiveLive],
                                [PlaylistRepository frankenstine],
                                [PlaylistRepository radioThreeBreakfast]];
}

- (NSURL *)playlistURL
{
    NSString *textFieldContents = [_playlistURLTextField text];
    NSURL *playlistURL = [NSURL URLWithString:textFieldContents];
    
    return playlistURL;
}

- (IBAction)radioButtonTapped:(UIButton *)sender
{
    NSURL *selectedURL = _predefinedPlaylistURLs[sender.tag];
    [_playlistURLTextField setText:[selectedURL absoluteString]];
    
}

@end
