//
//  PlaylistRepository.h
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 03/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlaylistRepository : NSObject

+ (NSURL *)radioOne;
+ (NSURL *)radioTwo;
+ (NSURL *)radioThree;
+ (NSURL *)radioFour;
+ (NSURL *)radioFiveLive;

@end
