//
//  AgoraHelper.h
//  AgoraDuo
//
//  Created by Qin Cindy on 9/2/16.
//  Copyright © 2016 Qin Cindy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AgoraHelper : NSObject

+ (NSString *) calcToken:(NSString *)_vendorKey signKey:(NSString *)signKey account:(NSString*)account expiredTime:(unsigned)expiredTime;
@end
