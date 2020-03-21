//
//  AAPLEAGLLayer.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface AAPLEAGLLayer : CAEAGLLayer

@property CVPixelBufferRef pixelBuffer;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)resetRenderBuffer;

@end

NS_ASSUME_NONNULL_END
