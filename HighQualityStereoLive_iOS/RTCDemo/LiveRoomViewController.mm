//
//  LiveRoomViewController.m
//  RTCDemo
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "LiveRoomViewController.h"
#import "MusicViewController.h"
#import "KeyCenter.h"
#import "CaptureSessionController.h"
#import <AgoraRtcEngineKit/IAgoraRtcEngine.h>
#import <AgoraRtcEngineKit/IAgoraMediaEngine.h>

@interface LiveRoomViewController () <
AgoraRtcEngineDelegate,
MusicVCDelegate,
CaptureSessionControllerDelegate,
UIPopoverPresentationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *sessionButtons;
@property (weak, nonatomic) IBOutlet UIButton *audioMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *stereoButton;

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

@property (weak, nonatomic) MusicViewController *musicVC;
@property (assign, nonatomic) MusicMixingStatus mixingStatus;
@property (assign, nonatomic) BOOL shouldReplace;

@property (strong, nonatomic) CaptureSessionController* captureSessionController;
@end

BOOL useExternalDevice;

class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
public:
    void pushExternalData(void* data, int bytes, int fs, int ch)
    {
        sampleRate = fs;
        channels = ch;
        
        if (availableBytes + bytes > kBufferLengthBytes) {
            readIndex = 0;
            writeIndex = 0;
            availableBytes = 0;
        }
        
        if (writeIndex + bytes > kBufferLengthBytes) {
            int left = kBufferLengthBytes - writeIndex;
            memcpy(byteBuffer+writeIndex, data, left);
            memcpy(byteBuffer, (char*)data+left, bytes - left);
            writeIndex = bytes - left;
        }
        else {
            memcpy(byteBuffer + writeIndex, data, bytes);
            writeIndex += bytes;
        }
        availableBytes += bytes;
    }
    
    virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
    {
        if (!startDataPassIn &&
            availableBytes < 441 * 2 * 2 * 10) {
            return true;
        }
        startDataPassIn = true;
        
        audioFrame.samplesPerSec = sampleRate;
        int readBytes = sampleRate / 100 * channels * sizeof(int16_t);  // 10ms
        int16_t tmp[960]; // At most 2ch @48k
        
        if (readIndex + readBytes > kBufferLengthBytes) {
            int left = kBufferLengthBytes - readIndex;
            memcpy(tmp, byteBuffer + readIndex, left);
            memcpy(tmp + left, byteBuffer, readBytes - left);
            readIndex = readBytes - left;
        }
        else {
            memcpy(tmp, byteBuffer + readIndex, readBytes);
            readIndex += readBytes;
        }
        availableBytes -= readBytes;
        
        if (channels == audioFrame.channels) {
            memcpy(audioFrame.buffer, tmp, readBytes);
        }
        else if (channels == 1 && audioFrame.channels == 2) {
            int16_t* from = tmp;
            int16_t* to = static_cast<int16_t*>(audioFrame.buffer);
            size_t size = readBytes / sizeof(int16_t);
            for (size_t i = 0; i < size; ++i) {
                to[2*i] = from[i];
                to[2*i+1] = from[i];
            }
        }
        else if (channels == 2 && audioFrame.channels == 1) {
            int16_t* from = tmp;
            int16_t* to = static_cast<int16_t*>(audioFrame.buffer);
            size_t size = readBytes / sizeof(int16_t) / channels;
            for (size_t i = 0; i < size; ++i) {
                to[i] = from[2*i];
            }
        }
        
        return true;
    }
    
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override { return true; }
    
    virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override { return true; }
    
private:
    enum { kBufferLengthBytes = 441 * 2 * 2 * 50 };
    char byteBuffer[kBufferLengthBytes];
    int readIndex = 0;
    int writeIndex = 0;
    int availableBytes = 0;
    int sampleRate = 44100;
    int channels = 1;
    bool startDataPassIn = false;
};

static AgoraAudioFrameObserver* s_audioFrameObserver;

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

- (void)setShouldStereo:(BOOL)shouldStereo {
    _shouldStereo = shouldStereo;
    [self.rtcEngine setHighQualityAudioParametersWithFullband:true stereo:shouldStereo fullBitrate:false];
    
    [self.stereoButton setImage:[UIImage imageNamed:(self.shouldStereo ? @"btn_stereo_blue" : @"btn_stereo")] forState:UIControlStateNormal];
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
    self.videoViews = @[self.videoView0,
                        self.videoView1,
                        self.videoView2,
                        self.videoView3,
                        self.videoView4,
                        self.videoView5,
                        self.videoView6];
    
    self.roomNameLabel.text = self.roomName;
    [self updateButtonsVisiablity];
    
    [self loadAgoraKit];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"liveToMusic"]) {
        MusicViewController *musicVC = segue.destinationViewController;
        musicVC.rtcEngine = self.rtcEngine;
        musicVC.mixingStatus = self.mixingStatus;
        musicVC.shouldReplace = self.shouldReplace;
        musicVC.delegate = self;
        musicVC.popoverPresentationController.delegate = self;
        self.musicVC = musicVC;
    }
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
        [self.videoCanvases removeObject:tappedCanvas];
        [self.videoCanvases insertObject:tappedCanvas atIndex:0];
        [self updateInterface];
    }
}

- (IBAction)doLeavePressed:(UIButton *)sender {
    if (useExternalDevice) {
        [self.captureSessionController stopCaptureSession];
        [self.captureSessionController deallocCaptureSession];
    }
    
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

//MARK: - Music mixing delegate
- (void)musicVC:(MusicViewController *)musicVC didChangeToStatus:(MusicMixingStatus)status {
    self.mixingStatus = status;
}

- (void)musicVC:(MusicViewController *)musicVC didChangeReplace:(BOOL)shouldReplace {
    self.shouldReplace = shouldReplace;
}

//MARK: - Agora Media SDK
- (void)loadAgoraKit {
    self.rtcEngine = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter AppId] delegate:self];
    [self.rtcEngine setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
    [self.rtcEngine enableDualStreamMode:YES];
    [self.rtcEngine enableVideo];
    [self.rtcEngine setVideoProfile:self.videoProfile swapWidthAndHeight:YES];
    [self.rtcEngine setClientRole:self.clientRole withKey:nil];
    
    
    useExternalDevice = (self.clientRole == AgoraRtc_ClientRole_Broadcaster);
    // Data is from external capture
    if (useExternalDevice) {
        // alloc the capture session object
        self.captureSessionController = [[CaptureSessionController alloc] init];
        self.captureSessionController.delegate = self;
        [self.captureSessionController setupCaptureSession];
        
        [self.rtcEngine setParameters: @"{\"che.audio.external_device\": true}"];
        [self.rtcEngine setParameters: @"{\"che.audio.external.to.apm\": true}"];
        agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)self.rtcEngine.getNativeHandle;
        agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
        mediaEngine.queryInterface(*rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
        if (mediaEngine) {
            s_audioFrameObserver = new AgoraAudioFrameObserver();
            mediaEngine->registerAudioFrameObserver(s_audioFrameObserver);
        }
    }
    
    // Enable stereo transmission
    [self.rtcEngine setHighQualityAudioParametersWithFullband:true stereo:true fullBitrate:false];
    
    // Set capture format
    [self.rtcEngine setRecordingAudioFrameParametersWithSampleRate:44100 channel:2 mode:AgoraRtc_RawAudioFrame_OpMode_WriteOnly samplesPerCall:882];
    
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
    
    if (useExternalDevice) {
        [self.captureSessionController startCaptureSession];
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

- (void)rtcEngineMediaEngineDidAudioMixingFinish:(AgoraRtcEngineKit *)engine {
    self.mixingStatus = MusicMixingStatusStopped;
    self.musicVC.mixingStatus = MusicMixingStatusStopped;
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

- (void)captureSessionController:(CaptureSessionController *)controller
                  didCaptureData:(void *)data
                           bytes:(int)bytes
                              fs:(int)fs
                              ch:(int)ch {
    if (s_audioFrameObserver) {
        s_audioFrameObserver->pushExternalData(data, bytes, fs, ch);
    }
}
@end
