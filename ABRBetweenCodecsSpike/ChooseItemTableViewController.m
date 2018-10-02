//
//  ChooseItemTableViewController.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 02/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "ChooseItemTableViewController.h"

@implementation ChooseItemTableViewController {
    __weak IBOutlet UITextField *_playlistURLTextField;
}

- (NSURL *)playlistURL
{
    NSString *textFieldContents = [_playlistURLTextField text];
    NSURL *playlistURL = [NSURL URLWithString:textFieldContents];
    
    return playlistURL;
}

@end
