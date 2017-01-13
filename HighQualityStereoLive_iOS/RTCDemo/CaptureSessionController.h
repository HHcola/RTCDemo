//
//  CaptureSessionController.h
//  RTCDemo
//
//  Created by YaoSiqiang on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@class CaptureSessionController;

@protocol CaptureSessionControllerDelegate <NSObject>
- (void)captureSessionController:(CaptureSessionController *)controller
                  didCaptureData:(void *)data
                           bytes:(int)bytes
                              fs:(int)fs
                              ch:(int)ch;
@end

@interface CaptureSessionController : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate> {
@private
    AVCaptureSession            *captureSession;
    AVCaptureDeviceInput        *captureAudioDeviceInput;
    AVCaptureAudioDataOutput    *captureAudioDataOutput;
}

@property (weak, nonatomic) id<CaptureSessionControllerDelegate> delegate;

- (BOOL)setupCaptureSession;
- (NSString *)getDeviceName;
- (void)startCaptureSession;
- (void)stopCaptureSession;
- (void)deallocCaptureSession;

@end
