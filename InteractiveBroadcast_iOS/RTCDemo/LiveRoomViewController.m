//
//  LiveRoomViewController.m
//  RTCDemo
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "LiveRoomViewController.h"
#import "KeyCenter.h"

@interface LiveRoomViewController () <
    AgoraRtcEngineDelegate,
    UIPopoverPresentationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *sessionButtons;
@property (weak, nonatomic) IBOutlet UIButton *audioMuteButton;

@property (weak, nonatomic) IBOutlet UIView *videoView0;
@property (weak, nonatomic) IBOutlet UIView *videoView1;
@property (weak, nonatomic) IBOutlet UIView *videoView2;
@property (weak, nonatomic) IBOutlet UIView *videoView3;
@property (weak, nonatomic) IBOutlet UIView *videoView4;
@property (weak, nonatomic) IBOutlet UIView *videoView5;
@property (weak, nonatomic) IBOutlet UIView *videoView6;

@property (strong, nonatomic) AgoraRtcEngineKit *rtcEngine;
@property (assign, nonatomic) BOOL isBroadcaster;
@property (assign, nonatomic) BOOL isMuted;
@property (assign, nonatomic) BOOL shouldStereo;
@property (strong, nonatomic) NSMutableArray<AgoraRtcVideoCanvas *> *videoCanvases;
@property (strong, nonatomic) NSArray<UIView *> *videoViews;
@end

@implementation LiveRoomViewController
- (BOOL)isBroadcaster {
    return self.clientRole == AgoraRtc_ClientRole_Broadcaster;
}

- (void)setClientRole:(AgoraRtcClientRole)clientRole {
    _clientRole = clientRole;
    [self updateButtonsVisiablity];
}

- (void)setIsMuted:(BOOL)isMuted {
    _isMuted = isMuted;
    [self.rtcEngine muteLocalAudioStream:isMuted];
    [self.audioMuteButton setImage:[UIImage imageNamed:(self.isMuted ? @"btn_mute_cancel" : @"btn_mute")] forState:UIControlStateNormal];
}

- (NSArray<AgoraRtcVideoCanvas *> *)displayCanvases {
    NSArray *displayCanvases;
    if (!self.isBroadcaster && self.videoCanvases.count > 0) {
        displayCanvases = [self.videoCanvases subarrayWithRange:NSMakeRange(1, self.videoCanvases.count - 1)];
    } else {
        displayCanvases = self.videoCanvases;
    }
    return displayCanvases;
}

//MARK: - lift cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoCanvases = [[NSMutableArray alloc] init];
    self.videoViews = @[self.videoView0];
    
    self.roomNameLabel.text = self.roomName;
    [self updateButtonsVisiablity];
    
    [self loadAgoraKit];
}

//MARK: - user action
- (IBAction)doSwitchCameraPressed:(UIButton *)sender {
    [self.rtcEngine switchCamera];
}

- (IBAction)doMutePressed:(UIButton *)sender {
    self.isMuted = !self.isMuted;
}

- (IBAction)doStereoPressed:(UIButton *)sender {
    self.shouldStereo = !self.shouldStereo;
}

- (IBAction)doDoubleTapped:(UITapGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self.view];
    
    AgoraRtcVideoCanvas *tappedCanvas;
    for (AgoraRtcVideoCanvas *canvas in self.displayCanvases) {
        CGRect rect = [self.view convertRect:canvas.view.frame fromView:canvas.view];
        if (CGRectContainsPoint(rect, location)) {
            tappedCanvas = canvas;
            break;
        }
    }
    
    if (tappedCanvas) {
        
    }
}

- (IBAction)doLeavePressed:(UIButton *)sender {
    [self leaveChannel];
}

//MARK: -
- (void)updateInterface {
    for (AgoraRtcVideoCanvas *canvas in self.videoCanvases) {
        [canvas.view removeFromSuperview];
    }
    
    NSArray *displayCanvases = self.displayCanvases;
    for (NSInteger i = 0; i < displayCanvases.count && i < self.videoViews.count; ++i) {
        UIView *hostingView = [displayCanvases[i] view];
        UIView *videoView = self.videoViews[i];
        hostingView.frame = videoView.bounds;
        [videoView addSubview:hostingView];
    }
    
    [self setStreamTypeForCanvases:displayCanvases];
}

- (void)setStreamTypeForCanvases:(NSArray<AgoraRtcVideoCanvas *> *)canvases {
    if (!canvases.count) {
        return;
    }
    
    AgoraRtcVideoCanvas *firstCanvas = canvases.firstObject;
    [self.rtcEngine setRemoteVideoStream:firstCanvas.uid type:AgoraRtc_VideoStream_High];
    
    for (NSInteger i = 1; i < canvases.count; ++i) {
        AgoraRtcVideoCanvas *canvas = canvases[i];
        [self.rtcEngine setRemoteVideoStream:canvas.uid type:AgoraRtc_VideoStream_Low];
    }
}

- (void)addLocalCanvas {
    AgoraRtcVideoCanvas *localCanvas = [[AgoraRtcVideoCanvas alloc] init];
    localCanvas.uid = 0;
    localCanvas.view = [[UIView alloc] init];
    localCanvas.renderMode = AgoraRtc_Render_Hidden;
    
    [self.videoCanvases addObject:localCanvas];
    [self.rtcEngine setupLocalVideo:localCanvas];
    [self updateInterface];
}

- (AgoraRtcVideoCanvas *)videoCanvasOfUid:(NSUInteger)uid {
    for (AgoraRtcVideoCanvas *canvas in self.videoCanvases) {
        if (canvas.uid == uid) {
            return canvas;
        }
    }
    
    AgoraRtcVideoCanvas *newCanvas = [[AgoraRtcVideoCanvas alloc] init];
    newCanvas.uid = uid;
    newCanvas.view = [[UIView alloc] init];
    newCanvas.renderMode = AgoraRtc_Render_Hidden;
    [self.videoCanvases addObject:newCanvas];
    return newCanvas;
}

- (void)leaveChannel {
    [self setIdleTimerActive:YES];
    
    [self.rtcEngine setupLocalVideo:nil];
    [self.rtcEngine leaveChannel:nil];
    if (self.isBroadcaster) {
        [self.rtcEngine stopPreview];
    }
    
    if ([self.delegate respondsToSelector:@selector(liveVCNeedClose:)]) {
        [self.delegate liveVCNeedClose:self];
    }
}

//MARK: - Agora Media SDK
- (void)loadAgoraKit {
    self.rtcEngine = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter AppId] delegate:self];
    [self.rtcEngine setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
    [self.rtcEngine enableDualStreamMode:YES];
    [self.rtcEngine enableVideo];
    [self.rtcEngine setVideoProfile:self.videoProfile swapWidthAndHeight:YES];
    [self.rtcEngine setClientRole:self.clientRole withKey:nil];
    
    if (self.isBroadcaster) {
        [self.rtcEngine startPreview];
    }
    
    [self addLocalCanvas];
    
    int code = [self.rtcEngine joinChannelByKey:nil channelName:self.roomName info:nil uid:0 joinSuccess:nil];
    if (code == 0) {
        [self setIdleTimerActive:NO];
    } else {
        [self alertString:[NSString stringWithFormat:@"Join channel failed: %d", code]];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    AgoraRtcVideoCanvas *userCanvas = [self videoCanvasOfUid:uid];
    [self.rtcEngine setupRemoteVideo:userCanvas];
    
    [self updateInterface];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    [self updateInterface];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
    AgoraRtcVideoCanvas *deleteCanvas;
    for (AgoraRtcVideoCanvas *canvas in self.videoCanvases) {
        if (canvas.uid == uid) {
            deleteCanvas = canvas;
        }
    }
    
    if (deleteCanvas) {
        [self.videoCanvases removeObject:deleteCanvas];
        [deleteCanvas.view removeFromSuperview];
        [self updateInterface];
    }
}

//MARK: -
- (void)updateButtonsVisiablity {
    for (UIButton *button in self.sessionButtons) {
        button.hidden = !self.isBroadcaster;
    }
}

- (void)setIdleTimerActive:(BOOL)active {
    [UIApplication sharedApplication].idleTimerDisabled = !active;
}

- (void)alertString:(NSString *)string {
    if (!string.length) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:string preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

//MARK: - popover delegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}
@end
