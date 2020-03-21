//
//  ConfigMacros.h
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#ifndef ConfigMacros_h
#define ConfigMacros_h

#define kURL @"ws://5d6a050298a3.sn.mynetname.net:9500/"

#define kNavBarHeight                44.f
#define kStatusBarHeight             (IsiPhoneX ? 44 : 20)
#define kNavBarAndStatusBarHeight    (kNavBarHeight+kStatusBarHeight)
#define kFullScreenOryY              (IsiPhoneX ? 0 : 20)

#define IsiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] == NO ? NO : \
CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) ||\
CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) ||\
CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size))


#define ScreenW    ([[UIScreen mainScreen] bounds].size.width)
#define ScreenH    ([[UIScreen mainScreen] bounds].size.height)
#define ScreenMaxL (MAX(ScreenW, ScreenH))
#define ScreenMinL (MIN(ScreenW, ScreenH))
#define ScreenB    [[UIScreen mainScreen] bounds]
#define ScreenStateH  kStatusBarHeight
#define ScreenNavBarH  kNavBarAndStatusBarHeight
#define ScreenTabBarH  (IsiPhoneX ? 83 : 44)
#define kAppWindow [[[UIApplication sharedApplication] delegate] window]

#define TTVScreenStateH CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)

#endif /* ConfigMacros_h */
