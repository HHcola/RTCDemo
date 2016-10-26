//
//  MusicViewController.h
//  RTCDemo
//
//  Created by GongYuhua on 2016/10/18.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>

@class MusicViewController;

typedef NS_ENUM(NSUInteger, MusicMixingStatus) {
    MusicMixingStatusStopped = 0,
    MusicMixingStatusMixing,
    MusicMixingStatusPaused,
};

@protocol MusicVCDelegate <NSObject>
- (void)musicVC:(MusicViewController *)musicVC didChangeToStatus:(MusicMixingStatus)status;
- (void)musicVC:(MusicViewController *)musicVC didChangeReplace:(BOOL)shouldReplace;
@end

@interface MusicViewController : UIViewController
@property (strong, nonatomic) AgoraRtcEngineKit *rtcEngine;
@property (assign, nonatomic) MusicMixingStatus mixingStatus;
@property (assign, nonatomic) BOOL shouldReplace;
@property (weak, nonatomic) id<MusicVCDelegate> delegate;
@end
