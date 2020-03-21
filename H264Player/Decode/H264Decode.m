//
//  H264Decode.m
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import "H264Decode.h"

@interface H264Decode(){
    // 解码
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    NSThread* thread;
    NSLock* lock;
}

@end

@implementation H264Decode
// 解码
static void didDecompress(void *decompressionOutputRefCon,
                          void *sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer,
                          CMTime presentationTimeStamp,
                          CMTime presentationDuration ) {
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
    H264Decode *decoder = (__bridge H264Decode *)decompressionOutputRefCon;
    if (decoder.delegate){
        [decoder.delegate gotDecodedFrame:pixelBuffer];
    }
    
}

static const uint8_t *avc_find_startcode_internal(const uint8_t *p, const uint8_t *end) {
    const uint8_t *a = p + 4 - ((intptr_t)p & 3);
    
    for (end -= 3; p < a && p < end; p++) {
        if (p[0] == 0 && p[1] == 0 && p[2] == 1)
            return p;
    }
    
    for (end -= 3; p < end; p += 4) {
        uint32_t x = *(const uint32_t*)p;
        if ((x - 0x01010101) & (~x) & 0x80808080) { // generic
            if (p[1] == 0) {
                if (p[0] == 0 && p[2] == 1)
                    return p;
                if (p[2] == 0 && p[3] == 1)
                    return p+1;
            }
            if (p[3] == 0) {
                if (p[2] == 0 && p[4] == 1)
                    return p+2;
                if (p[4] == 0 && p[5] == 1)
                    return p+3;
            }
        }
    }
    
    for (end += 3; p < end; p++) {
        if (p[0] == 0 && p[1] == 0 && p[2] == 1)
            return p;
    }
    
    return end + 3;
}

const uint8_t *avc_find_startcode(const uint8_t *p, const uint8_t *end) {
    const uint8_t *out= avc_find_startcode_internal(p, end);
    if(p<out && out<end && !out[-1]) out--;
    return out;
}

#pragma mark - 解码

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    if (!_sps || !_pps || _spsSize == 0 || _ppsSize == 0) {
        return NO;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        
//      kCVPixelFormatType_420YpCbCr8Planar is YUV420
//      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        NSDictionary* destinationPixelBufferAttributes = @{
            (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            // 硬解必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange 或者是kCVPixelFormatType_420YpCbCr8Planar
            // 因为iOS是nv12  其他是nv21
            , (id)kCVPixelBufferWidthKey  : [NSNumber numberWithInt:600]
            , (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:800]
            //, (id)kCVPixelBufferBytesPerRowAlignmentKey : [NSNumber numberWithInt:kH264outputWidth*2]
            , (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:NO]
            , (id)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]
            };
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, (__bridge CFDictionaryRef)destinationPixelBufferAttributes,
                                              &callBackRecord,
                                              &_deocderSession);
        
        VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
        VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
        CFRelease(attrs);
        
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", (int)status);
    }
    
    return YES;
}

-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
    
    if (thread != nil) {
        if (!thread.isCancelled) {
            [thread cancel];
        }
    }
}

-(uint8_t*)uint8FromBytes:(NSData *)fData buffer:(uint8_t*)frame {
//  NSAssert(fData.length == 1, @"uint8FromBytes: (data length != 1)");
    NSData *data = fData;
    uint8_t* val = NULL;
    [data getBytes:&frame length:data.length];
    return val;
}

- (CVPixelBufferRef)decode:(uint8_t *)frame withSize:(uint32_t)frameSize {
    if (frame == NULL || _deocderSession == nil)
        return NULL;
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                          (void *)frame,
                                                          frameSize,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          frameSize,
                                                          FALSE,
                                                          &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
//        const size_t sampleSizeArray[] = {frameSize};
//        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
//                                           blockBuffer,
//                                           _decoderFormatDescription ,
//                                           1, 0, NULL, 1, sampleSizeArray,
//                                           &sampleBuffer);
        status = CMSampleBufferCreate(NULL, blockBuffer, TRUE, 0, 0, _decoderFormatDescription, 1, 0, NULL, 0, NULL, &sampleBuffer);
        
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            status = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                       sampleBuffer,
                                                       flags,
                                                       &outputPixelBuffer,
                                                       &flagOut);
            
            if (status == kVTInvalidSessionErr) {
                NSLog(@"Invalid session, reset decoder session");
                [self resetH264Decoder];
            } else if(status == kVTVideoDecoderBadDataErr) {
                NSLog(@"decode failed status=%d(Bad data)", status);
            } else if(status != noErr) {
                NSLog(@"decode failed status=%d", status);
            }
        }
        
        if (sampleBuffer != NULL)
            CFRelease(sampleBuffer);
    }
    if (blockBuffer != NULL)
        CFRelease(blockBuffer);
    
    return outputPixelBuffer;
}

- (BOOL)resetH264Decoder {
    if(_deocderSession) {
        VTDecompressionSessionWaitForAsynchronousFrames(_deocderSession);
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    return [self initH264Decoder];
}

-(void)decodeData:(NSData*)data {
    NSData *vp = nil;
    [lock lock];
    uint8_t *_buf_out = (uint8_t*)malloc(1080 * 1920 * sizeof(uint8_t));
    
    vp = data;
    uint8_t* frame = (uint8_t*)vp.bytes;
    uint32_t frameSize = (uint32_t)vp.length;
    if (frame != NULL)
    {
        int size = frameSize;
        const uint8_t *p = frame;
        const uint8_t *end = p + size;
        const uint8_t *nal_start, *nal_end;
        int nal_len, nalu_type = 0;
        
        size = 0;
        nal_start = avc_find_startcode(p, end);
        while (![[NSThread currentThread] isCancelled]) {
            while (![[NSThread currentThread] isCancelled] && nal_start < end && !*(nal_start++));
            if (nal_start == end)
                break;
            
            nal_end = avc_find_startcode(nal_start, end);
            nal_len = nal_end - nal_start;
            
            nalu_type = nal_start[0] & 0x1f;
            if (nalu_type == 0x07) {
                if (_sps == NULL) {
                    _spsSize = nal_len;
                    _sps = (uint8_t*)malloc(_spsSize);
                    memcpy(_sps, nal_start, _spsSize);
                    NSLog(@"Nal type is SPS");
                }
            }
            else if (nalu_type == 0x08) {
                if (_pps == NULL) {
                    _ppsSize = nal_len;
                    _pps = (uint8_t*)malloc(_ppsSize);
                    memcpy(_pps, nal_start, _ppsSize);
                    NSLog(@"Nal type is PPS");
                }
            }
            else {
                NSLog(@"Nal type is %d",nalu_type);
                _buf_out[size + 0] = (uint8_t)(nal_len >> 24);
                _buf_out[size + 1] = (uint8_t)(nal_len >> 16);
                _buf_out[size + 2] = (uint8_t)(nal_len >> 8 );
                _buf_out[size + 3] = (uint8_t)(nal_len);
                
                memcpy(_buf_out + 4 + size, nal_start, nal_len);
                size += 4 + nal_len;
            }
            
            nal_start = nal_end;
        }
        
        if ([self initH264Decoder]) {
            CVPixelBufferRef pixelBuffer = NULL;
            pixelBuffer = [self decode:_buf_out withSize:size];
        }
    }
    [lock unlock];
    
    if (_sps != NULL) {
        free(_sps);
        _sps = NULL;
        _spsSize = 0;
    }
    
    if (_pps != NULL) {
        free(_pps);
        _pps = NULL;
        _ppsSize = 0;
    }
    if (_buf_out != NULL) {
        free(_buf_out);
        _buf_out = NULL;
    }
}


- (void)endDecode {
    
}

@end






