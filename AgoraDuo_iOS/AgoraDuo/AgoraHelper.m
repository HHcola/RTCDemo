//
//  AgoraHelper.m
//  AgoraDuo
//
//  Created by Qin Cindy on 9/2/16.
//  Copyright © 2016 Qin Cindy. All rights reserved.
//

#import "AgoraHelper.h"
#import <CommonCrypto/CommonDigest.h>
@implementation AgoraHelper

+ (NSString*)MD5:(NSString*)s
{
    // Create pointer to the string as UTF8
    const char *ptr = [s UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+ (NSString *) calcToken:(NSString *)_vendorKey signKey:(NSString *)signKey account:(NSString*)account expiredTime:(unsigned)expiredTime {
    // Token = 1:vendorKey:expiredTime:sign
    // Token = 1:vendorKey:expiredTime:md5(account + vendorID + signKey + expiredTime)
    
    NSString * sign = [AgoraHelper MD5:[NSString stringWithFormat:@"%@%@%@%d", account, _vendorKey, signKey, expiredTime]];
    return [NSString stringWithFormat:@"1:%@:%d:%@", _vendorKey, expiredTime, sign];
}

@end
