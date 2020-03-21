//
//  G711.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface G711 : NSObject

int g711u_decode(short amp[], const unsigned char g711u_data[], int g711u_bytes);

int G711Decode(char* pRawData,const unsigned char* pBuffer, int nBufferSize);

void G711Encoder(const void *pcm,unsigned char *code,int size,int lawflag);

@end

NS_ASSUME_NONNULL_END
