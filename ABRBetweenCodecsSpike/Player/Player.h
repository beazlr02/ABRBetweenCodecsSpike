//
//  Player.h
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 03/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Player;
@class PlayerBitrateData;

@protocol PlayerDelegate <NSObject>

- (void)player:(Player *)player willTransitionToPlayingFromContentsAtURL:(NSURL *)URL;
- (void)player:(Player *)player didProducePlaybackBitrateData:(PlayerBitrateData *)bitrateData;
- (void)player:(Player *)player didProduceAvailableVariantBitrates:(NSArray<NSNumber *> *)variantBitrates;
- (void)player:(Player *)player didCapPlaybackBitrateToVariantBitrateAtIndex:(NSUInteger)index;

@end

@interface Player : NSObject

@property (nonatomic, weak, nullable) id<PlayerDelegate> delegate;

- (void)beginPlaybackOfContentsFromURL:(NSURL *)URL;
- (void)capPlaybackBitrateToBitrateAtIndex:(NSUInteger)variantIndex;

@end

@interface PlayerBitrateData : NSObject

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) double indicatedBitrate;
@property (nonatomic, readonly) double switchBitrate;

@end
