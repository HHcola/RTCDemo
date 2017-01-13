//
//  MusicViewController.m
//  RTCDemo
//
//  Created by GongYuhua on 2016/10/18.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "MusicViewController.h"

@interface MusicViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UISwitch *replaceSwitch;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@end

@implementation MusicViewController
- (void)setMixingStatus:(MusicMixingStatus)mixingStatus {
    _mixingStatus = mixingStatus;
    
    [self updateViewWithMixingStatus:mixingStatus];
    
    if ([self.delegate respondsToSelector:@selector(musicVC:didChangeToStatus:)]) {
        [self.delegate musicVC:self didChangeToStatus:mixingStatus];
    }
}

- (void)setShouldReplace:(BOOL)shouldReplace {
    _shouldReplace = shouldReplace;
    
    if ([self.delegate respondsToSelector:@selector(musicVC:didChangeReplace:)]) {
        [self.delegate musicVC:self didChangeReplace:shouldReplace];
    }
}

- (NSString *)localMusicFilePath {
    return [[NSBundle mainBundle] pathForResource:@"binaural" ofType:@"mp3"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(300, 160);
    
    [self updateViewWithMixingStatus:self.mixingStatus];
    self.replaceSwitch.on = self.shouldReplace;
}

- (IBAction)doReplaceSwitched:(UISwitch *)sender {
    BOOL shouldReplace = sender.on;
    //[self.rtcEngine audioMixingShouldReplace:shouldReplace];
    self.shouldReplace = shouldReplace;
}

- (IBAction)doPlayPausePressed:(UIButton *)sender {
    switch (self.mixingStatus) {
        case MusicMixingStatusStopped: {
            [self.rtcEngine startAudioMixing:self.localMusicFilePath loopback:NO replace:NO cycle:1];
            self.mixingStatus = MusicMixingStatusMixing;
            break;
        }
        case MusicMixingStatusMixing: {
            [self.rtcEngine pauseAudioMixing];
            self.mixingStatus = MusicMixingStatusPaused;
            break;
        }
        case MusicMixingStatusPaused: {
            [self.rtcEngine resumeAudioMixing];
            self.mixingStatus = MusicMixingStatusMixing;
            break;
        }
    }
}

- (IBAction)doStopPressed:(UIButton *)sender {
    [self.rtcEngine stopAudioMixing];
    self.mixingStatus = MusicMixingStatusStopped;
}

- (IBAction)doVolumeSliderChanged:(UISlider *)sender {
    [self.rtcEngine adjustAudioMixingVolume:((NSUInteger)sender.value)];
}

- (void)updateViewWithMixingStatus:(MusicMixingStatus)status {
    self.stopButton.hidden = (status == MusicMixingStatusStopped);
    [self.playPauseButton setImage:[UIImage imageNamed:(status == MusicMixingStatusMixing ? @"pause" : @"play")] forState:UIControlStateNormal];
    
    if (status == MusicMixingStatusStopped) {
        self.replaceSwitch.hidden = YES;
        self.replaceSwitch.on = NO;
    } else {
        self.replaceSwitch.hidden = NO;
    }
}
@end
