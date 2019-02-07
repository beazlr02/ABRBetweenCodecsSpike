//
//  PlaylistRepository.m
//  ABRBetweenCodecsSpike
//
//  Created by Thomas Sherwood - TV&Mobile Platforms - Core Engineering on 03/10/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

#import "PlaylistRepository.h"

@implementation PlaylistRepository

+ (NSURL *)radioOne
{
    return [NSURL URLWithString:@"http://as-hls-uk-live.akamaized.net/pool_6/live/bbc_radio_one/bbc_radio_one.isml/.m3u8"];
}

+ (NSURL *)radioTwo
{
    return [NSURL URLWithString:@"http://as-dash-uk-live.akamaized.net/pool_7/live/bbc_radio_two/bbc_radio_two.isml/.m3u8"];
}

+ (NSURL *)radioThree
{
    return [NSURL URLWithString:@"http://as-dash-uk-live.akamaized.net/pool_7/live/bbc_radio_three/bbc_radio_three.isml/.m3u8"];
}

+ (NSURL *)radioFour
{
    return [NSURL URLWithString:@"http://as-dash-uk-live.akamaized.net/pool_6/live/bbc_radio_fourfm/bbc_radio_fourfm.isml/.m3u8"];
}

+ (NSURL *)radioFiveLive
{
    return [NSURL URLWithString:@"http://as-dash-uk-live.akamaized.net/pool_6/live/bbc_radio_five_live/bbc_radio_five_live.isml/.m3u8"];
}

+ (NSURL *)frankenstine
{
    return [NSURL URLWithString:@"http://a.files.bbci.co.uk/media/int/audio_abr_test.m3u8"];
}

@end
