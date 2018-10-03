//
//  FetchBitratesOperation.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 03/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "FetchBitratesOperation.h"

@implementation FetchBitratesOperation {
    NSURL *_playlistURL;
    void(^_fetchFinishedHandler)(NSArray<NSNumber *> *);
}

- (instancetype)initWithPlaylistURL:(NSURL *)playlistURL
                  completionHandler:(void(^)(NSArray<NSNumber *> *))completionHandler
{
    self = [super init];
    if (self) {
        _playlistURL = playlistURL;
        _fetchFinishedHandler = [completionHandler copy];
    }
    
    return self;
}

- (void)main
{
    NSMutableArray<NSNumber *> *bitrates = [NSMutableArray array];
    
    NSError *error;
    NSData *playlistData = [NSData dataWithContentsOfURL:_playlistURL options:0 error:&error];
    if (playlistData) {
        NSString *playlistContents = [[NSString alloc] initWithData:playlistData encoding:NSUTF8StringEncoding];
        NSRegularExpression *bandwidthExpression = [NSRegularExpression regularExpressionWithPattern:@"#EXT-X-STREAM-INF:BANDWIDTH=(\\d+)," options:0 error:nil];
        
        NSCharacterSet *seperatorCharacters = [NSCharacterSet characterSetWithCharactersInString:@"=,"];
        [bandwidthExpression enumerateMatchesInString:playlistContents options:0 range:NSMakeRange(0, [playlistContents length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSString *captureGroup = [playlistContents substringWithRange:[result range]];
            NSArray<NSString *> *components = [captureGroup componentsSeparatedByCharactersInSet:seperatorCharacters];
            NSString *bitrateString = components[1];
            NSScanner *scanner = [NSScanner scannerWithString:bitrateString];
            int bitrate;
            if ([scanner scanInt:&bitrate]) {
                [bitrates addObject:@(bitrate)];
            }
        }];
    }
    else {
        NSLog(@"%@", error);
    }
    
    _fetchFinishedHandler(bitrates);
}

@end
