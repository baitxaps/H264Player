//
//  PCMAudioQueuePlay.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCMAudioQueuePlay : NSObject

// 播放并顺带附上数据
- (void)playWithData: (NSData *)data;
 
// reset
- (void)resetPlay;

@end

NS_ASSUME_NONNULL_END
