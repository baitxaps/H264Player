//
//  PCMDataPlayer.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define QUEUE_BUFFER_SIZE 6     //队列缓冲个数
#define MIN_SIZE_PER_FRAME 2000 //每帧最小数据长度

NS_ASSUME_NONNULL_BEGIN

@interface PCMDataPlayer : NSObject {
    AudioStreamBasicDescription audioDescription;               // 音频参数
    AudioQueueRef audioQueue;                                   // 音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];   // 音频缓存
    BOOL audioQueueUsed[QUEUE_BUFFER_SIZE];

    NSLock* sysnLock;
}


// 重置播放器
- (void)reset;

// 停止播放
- (void)stop;

/*
 播放PCM数据
pcmData pcm字节数据
 */
- (void)play:(char*)pcmData length:(unsigned int)length;
@end

NS_ASSUME_NONNULL_END
