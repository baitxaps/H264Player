//
//  packed_struct.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#ifndef packed_struct_h
#define packed_struct_h

#include <stdio.h>

struct Packed {
    unsigned int uWidth:16;
    unsigned int uHeight:16;
    unsigned int  dwTimeStamp:32;
    unsigned int dwTimeStampHigh:32;
    unsigned int nYear:32;
    unsigned int nMonth:32;
    unsigned int  nDay:32;
    unsigned int nHour:32;
    unsigned int nMinute:32;
    unsigned int nSecond:32;
    unsigned int nMillisecond:32;
    unsigned int dwFrameNum:32;
    unsigned int dwFrameRate:32;
    unsigned int dwFlag:32;
    unsigned int dwFilePos:32;
    unsigned int nPacketType:32;
    unsigned int dwPacketSize:32;
};

#endif /* packed_struct_h */
