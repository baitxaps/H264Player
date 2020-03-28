//
//  SocketViewController.m
//  H264Player
//
//  Created by hairong chen on 2020/3/21.
//  Copyright © 2020 hairong chen. All rights reserved.
//

#import "LivePlayerController.h"
#import <SocketRocket/SRWebSocket.h>
#import <VideoToolbox/VideoToolbox.h>
#import "NSString+JsonString.h"
#import "Packed.h"
#import "AAPLEAGLLayer.h"
#import "PCMAudioQueuePlay.h"
#import "G711.h"
#import "H264Decode.h"
#import "PCMDataPlayer.h"
#import "ConfigMacros.h"

@interface LivePlayerController () <H264DecodeFrameCallbackDelegate,SRWebSocketDelegate>

@property (nonatomic, strong)SRWebSocket *webSocket;

//@property (nonatomic, strong)PCMAudioQueuePlay *audioPlay;
@property (nonatomic, strong)H264Decode *h264Decoder;
@property (nonatomic, strong)AAPLEAGLLayer *playLayer;  //解码后播放layer
@property (nonatomic, strong)PCMDataPlayer* audioPlayer;  //解码后播放layer

@end

@implementation LivePlayerController

- (void)dealloc {
  //  [self closeSocket];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self closeSocket];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
//  self.audioPlay = [[PCMAudioQueuePlay alloc]init];
    self.audioPlayer = [[PCMDataPlayer alloc] init];
    
    [self reconnect];
    //socket
    [self configH264Decoder];
}

- (void)reconnect {
    self.webSocket.delegate = nil;
    [self.webSocket close];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kURL]]];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {//Hik20Test
    NSLog(@"Websocket Connected");
    NSDictionary *sendDatas = @{@"b_sn" : @"Hik20Test",@"ch" : @"2",@"client" : @"1"};
    [self.webSocket send:[NSString jsonStringWithObject:sendDatas]];
    // 解码
    self.playLayer = [[AAPLEAGLLayer alloc]initWithFrame:CGRectMake(0, ScreenNavBarH, ScreenW, ScreenW * 9/16 + ScreenStateH )] ;
    [self.view.layer addSublayer:self.playLayer];
  
//  [self.view.layer setBorderWidth:2];
//  [self.view.layer setBorderColor:[UIColor redColor].CGColor];
}


// 连接失败，打印错误信息
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@":( Websocket Failed With Error %@", error);
    self.title = @"Connection Failed! (see logs)";
    self.webSocket = nil;
    // 断开连接后每过1s重新建立一次连接
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reconnect];
    });
}

// 接收服务器发送信息
//{'b_sn':b_sn,'ch':_ch,'res':res ,'err':err}
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData* data = (NSData*)message;
    if (data.length == 53 || data.length == 85 || data.length == 32) {
        
    }else{
        struct Packed packet;
        [data getBytes:&packet length:sizeof(packet)];
        
        if (packet.nPacketType == 10 ) {
            NSData *voiceData = [data subdataWithRange:NSMakeRange(sizeof(packet), packet.dwPacketSize)];
            NSLog(@"收到声音数据 -- %@",voiceData);
            
            int dataSize = (int)voiceData.length * 2;
            short decodeBuf[dataSize];
            g711u_decode(decodeBuf, voiceData.bytes,dataSize);
            NSData *pcmData = [NSData dataWithBytes:decodeBuf length:dataSize];
            [self.audioPlayer play:pcmData.bytes length:pcmData.length];
            
//          [self.audioPlay playWithData:pcmData];
        }else{
            data = [data subdataWithRange:NSMakeRange(sizeof(packet), packet.dwPacketSize)];
            NSLog(@"收到vidoe数据 -- %@",data);
            [self.h264Decoder decodeData:data];
        }
    }
}

// 长连接关闭
- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean {
    
    NSLog(@"WebSocket closed");
    self.title = @"Connection Closed! (see logs)";
    self.webSocket = nil;
    [self.h264Decoder clearH264Deocder];
}
//该函数是接收服务器发送的pong消息
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSString *reply = [[NSString alloc] initWithData:pongPayload encoding:NSUTF8StringEncoding];
    NSLog(@"%@",reply);
}

#pragma mark - 解码回调
- (void)gotDecodedFrame:(CVPixelBufferRef)imageBuffer{
    if(imageBuffer){
        //解码回来的数据绘制播放
        self.playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}


- (void)configH264Decoder{
    if (!self.h264Decoder) {
        self.h264Decoder = [[H264Decode alloc] init];
        self.h264Decoder.delegate = self;
    }
}

#pragma mark - 编码
// Called when start/stop button is pressed
- (void)closeSocket {
    // Close WebSocket
    self.webSocket.delegate = nil;
    [self.webSocket close];
    self.webSocket = nil;
}

- (void)statusBarOrientationDidChange:(NSNotification*)notification {
  //  [self setRelativeVideoOrientation];
}

@end
