//
//  ChooseItemTableViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 02/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "ChooseItemTableViewController.h"

@implementation ChooseItemTableViewController {
    NSArray<NSString *> *_predefinedPlaylistURLs;
    __weak IBOutlet UITextField *_playlistURLTextField;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _predefinedPlaylistURLs = @[@"http://as-hls-uk-live.akamaized.net/pool_6/live/bbc_radio_one/bbc_radio_one.isml/.m3u8",
                                @"http://as-dash-uk-live.akamaized.net/pool_7/live/bbc_radio_two/bbc_radio_two.isml/.m3u8",
                                @"http://as-dash-uk-live.akamaized.net/pool_7/live/bbc_radio_three/bbc_radio_three.isml/.m3u8",
                                @"http://as-dash-uk-live.akamaized.net/pool_6/live/bbc_radio_fourfm/bbc_radio_fourfm.isml/.m3u8",
                                @"http://as-dash-uk-live.akamaized.net/pool_6/live/bbc_radio_five_live/bbc_radio_five_live.isml/.m3u8"
                                ];
}

- (NSURL *)playlistURL
{
    NSString *textFieldContents = [_playlistURLTextField text];
    NSURL *playlistURL = [NSURL URLWithString:textFieldContents];
    
    return playlistURL;
}

- (IBAction)radioButtonTapped:(UIButton *)sender
{
    NSString *selectedURL = _predefinedPlaylistURLs[sender.tag];
    _playlistURLTextField.text = selectedURL;
}

@end
