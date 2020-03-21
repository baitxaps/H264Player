//
//  VideoFileParser.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPacket : NSObject

@property uint8_t* buffer;
@property NSInteger size;

@end


@interface VideoFileParser : NSObject

-(BOOL)open:(NSString*)fileName;
-(VideoPacket *)nextPacket;
-(void)close;

@end

NS_ASSUME_NONNULL_END
