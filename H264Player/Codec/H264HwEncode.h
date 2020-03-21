//
//  H264HwEncode.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@protocol H264HwEncodeDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface H264HwEncode : NSObject

@property (weak, nonatomic) NSString *error;
@property (weak, nonatomic) id<H264HwEncodeDelegate> delegate;

- (void)initWithConfiguration;
- (void)initEncode:(int)width  height:(int)height;
- (void)encode:(CMSampleBufferRef )sampleBuffer;
- (void)end;


@end

NS_ASSUME_NONNULL_END
