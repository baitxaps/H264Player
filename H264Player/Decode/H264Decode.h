//
//  H264Decode.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@protocol  H264DecodeFrameCallbackDelegate <NSObject>
//回调sps和pps数据
- (void)gotDecodedFrame:(CVPixelBufferRef )imageBuffer;

@end


@interface H264Decode : NSObject

@property (weak, nonatomic) id<H264DecodeFrameCallbackDelegate> delegate;

- (void)decodeData:(NSData*)data;

- (void)endDecode;

- (void)clearH264Deocder;


@end

NS_ASSUME_NONNULL_END
