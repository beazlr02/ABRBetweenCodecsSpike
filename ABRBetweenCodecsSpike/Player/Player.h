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
@class Recording;

@protocol PlayerDelegate <NSObject>

- (void)player:(Player *)player willTransitionToPlayingFromContentsAtURL:(NSURL *)URL;
- (void)player:(Player *)player didProducePlaybackBitrateData:(PlayerBitrateData *)bitrateData;
- (void)player:(Player *)player didProduceAvailableVariantBitrates:(NSArray<NSNumber *> *)variantBitrates;
- (void)player:(Player *)player didCapPlaybackBitrateToVariantBitrateAtIndex:(NSUInteger)index;
- (void)playerDidBeginRecording:(Player *)player;
- (void)player:(Player *)player didProduceRecording:(Recording *)recording;

@end

@interface Player : NSObject

@property (nonatomic, weak, nullable) id<PlayerDelegate> delegate;
@property (nonatomic, assign, readonly, getter=isRecording) BOOL recording;

- (void)beginPlaybackOfContentsFromURL:(NSURL *)URL;
- (void)capPlaybackBitrateToBitrateAtIndex:(NSUInteger)variantIndex;
- (void)startRecording;
- (void)stopRecording;

@end

@interface PlayerBitrateData : NSObject

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) double indicatedBitrate;
@property (nonatomic, readonly) double switchBitrate;

@end

@interface Recording : NSObject
@end
