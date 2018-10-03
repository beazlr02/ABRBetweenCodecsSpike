//
//  FetchBitratesOperation.h
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 03/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchBitratesOperation : NSOperation

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlaylistURL:(NSURL *)playlistURL
                  completionHandler:(void(^)(NSArray<NSNumber *> *))completionHandler NS_DESIGNATED_INITIALIZER;

@end
