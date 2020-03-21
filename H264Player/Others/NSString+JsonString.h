//
//  NSString+JsonString.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (JsonString)

+ (NSString*)jsonStringWithObject:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
