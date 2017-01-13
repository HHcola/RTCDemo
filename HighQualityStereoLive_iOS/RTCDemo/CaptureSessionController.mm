//
//  CaptureSessionController.mm
//  RTCDemo
//
//  Created by YaoSiqiang on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "CaptureSessionController.h"

@implementation CaptureSessionController

- (id)init
{
    self = [super init];
    
    if (self) {
        [self registerForNotifications];
    }
    
    return self;
}

- (NSString *)getDeviceName
{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    return audioDevice.localizedName;
}

- (BOOL)setupCaptureSession
{
    // Find the current default audio input device
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    if (audioDevice && audioDevice.connected) {
        // Get the device name
        NSLog(@"Audio Device Name: %@", audioDevice.localizedName);
    } else {
        NSLog(@"AVCaptureDevice defaultDeviceWithMediaType failed or device not connected!");
        return NO;
    }
    
    // Create the capture session
    captureSession = [[AVCaptureSession alloc] init];
    if (!captureSession) {
        NSLog(@"AVCaptureSession allocation failed!");
        return NO;
    }
    
    // Create and add a device input for the audio device to the session
    NSError *error = nil;
    captureAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!captureAudioDeviceInput) {
        NSLog(@"AVCaptureDeviceInput allocation failed! %@", [error localizedDescription]);
        return NO;
    }
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    } else {
        NSLog(@"Could not addInput to Capture Session!");
        return NO;
    }
    
    // Create and add a AVCaptureAudioDataOutput object to the session
    captureAudioDataOutput = [AVCaptureAudioDataOutput new];
    
    if (!captureAudioDataOutput) {
        NSLog(@"Could not create AVCaptureAudioDataOutput!");
        return NO;
    }
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    } else {
        NSLog(@"Could not addOutput to Capture Session!");
        return NO;
    }
    
    // Create a serial dispatch queue and set it on the AVCaptureAudioDataOutput object
    dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    if (!audioDataOutputQueue){
        NSLog(@"dispatch_queue_create Failed!");
        return NO;
    }
    
    [captureAudioDataOutput setSampleBufferDelegate:self queue:audioDataOutputQueue];
    
    // add an observer for the interupted property, we simply log the result
    [captureSession addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    // Start the capture session - This will cause the audio data output delegate method didOutputSampleBuffer
    // to be called for each new audio buffer recieved from the input device
    //  [self startCaptureSession];
    
    return YES;
}

// if we need to we call this to dispose of the previous capture session
// and create a new one, add our input and output and go
- (BOOL)resetCaptureSession
{
    if (captureSession) {
        [captureSession removeObserver:self forKeyPath:@"interrupted" context:nil];
        [captureSession removeObserver:self forKeyPath:@"running" context:nil];
        
        captureSession = nil;
    }
    
    // Create the capture session
    captureSession = [[AVCaptureSession alloc] init];
    if (!captureSession) {
        NSLog(@"AVCaptureSession allocation failed!");
        return NO;
    }
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    } else {
        NSLog(@"Could not addInput to Capture Session!");
        return NO;
    }
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    } else {
        NSLog(@"Could not addOutput to Capture Session!");
        return NO;
    }
    
    // add an observer for the interupted property, we simply log the result
    [captureSession addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    return YES;
}

// teardown
- (void)deallocCaptureSession
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionRuntimeErrorNotification
                                                  object:nil];
    
    [captureSession removeObserver:self forKeyPath:@"interrupted" context:nil];
    [captureSession removeObserver:self forKeyPath:@"running" context:nil];
    
    
    [captureAudioDataOutput setSampleBufferDelegate:nil queue:NULL];
}

/*
 Called by AVCaptureAudioDataOutput as it receives CMSampleBufferRef objects containing audio frames captured by the AVCaptureSession.
 Each CMSampleBufferRef will contain multiple frames of audio encoded in the default AVCapture audio format. This is where all the work is done,
 the first time through setting up and initializing the graph and format settings then continually rendering the provided audio though the
 audio unit graph manually and if we're recording, writing the processed audio out to the file.
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    OSStatus err = noErr;
    if ([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]])
    {
        
        // Get samples.
        CMBlockBufferRef audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t lengthAtOffset;
        size_t totalLength;
        char *samples;
        err = CMBlockBufferGetDataPointer(audioBuffer, 0, &lengthAtOffset, &totalLength, &samples);
        
        char dataPointer[4096];
        err  = CMBlockBufferCopyDataBytes(audioBuffer, 0, totalLength, dataPointer);
        
        // Get format.
        CMAudioFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        const AudioStreamBasicDescription *description = CMAudioFormatDescriptionGetStreamBasicDescription(format);
                
        if ([self.delegate respondsToSelector:@selector(captureSessionController:didCaptureData:bytes:fs:ch:)]) {
            [self.delegate captureSessionController:self didCaptureData:dataPointer
                                              bytes:(int)totalLength
                                                 fs:(int)description->mSampleRate
                                                 ch:(int)description->mChannelsPerFrame];
        }
    }
}

- (void)startCaptureSession
{
    static UInt8 retry = 0;
    
    // this sample always attempts to keep the capture session running without tearing it all down,
    // which means we may be trying to start the capture session while it's still
    // in some interim interrupted state (after a phone call for example) which will usually
    // get cleared up after a very short delay handle by a simple retry mechanism
    // if we still can't start, then resort to releasing the previous capture session and creating a new one
    if (captureSession.isInterrupted) {
        if (retry < 3) {
            retry++;
            NSLog(@"Capture Session interrupted try starting again...");
            [self performSelector:@selector(startCaptureSession) withObject:self afterDelay:2];
            return;
        } else {
            NSLog(@"Resetting Capture Session");
            BOOL result = [self resetCaptureSession];
            if (NO == result) {
                // this is bad, and means we can never start...should never see this
                NSLog(@"FAILED in resetCaptureSession! Cannot restart capture session!");
                return;
            }
        }
    }
    
    if (!captureSession.running) {
        NSLog(@"startCaptureSession");
        
        [captureSession startRunning];
        
        retry = 0;
    }
}

- (void)stopCaptureSession
{
    if (captureSession.running) {
        NSLog(@"stopCaptureSession");
        [captureSession stopRunning];
    }
}

#pragma mark ======== Observers =========

// observe state changes from the capture session, we log interruptions but activate the UI via notification when running
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"interrupted"] ) {
        NSLog(@"CaptureSesson is interrupted %@", (captureSession.isInterrupted) ? @"Yes" : @"No");
    }
    
    if ([keyPath isEqualToString:@"running"] ) {
        NSLog(@"CaptureSesson is running %@", (captureSession.isRunning) ? @"Yes" : @"No");
        if (captureSession.isRunning) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CaptureSessionRunningNotification" object:nil];
        }
    }
}

#pragma mark ======== Notifications =========

// notifications for standard things we want to know about
- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routeChangeHandler:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(captureSessionRuntimeError:)
                                                 name:AVCaptureSessionRuntimeErrorNotification
                                               object:nil];
}

// log any runtime erros from the capture session
- (void)captureSessionRuntimeError:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey: AVCaptureSessionErrorKey];
    
    NSLog(@"AVFoundation error %ld", (long)[error code]);
}

// log route changes
- (void)routeChangeHandler:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey: AVAudioSessionRouteChangeReasonKey] intValue];
    
    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reasonValue || AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reasonValue) {
        NSLog(@"CaptureSessionController routeChangeHandler called:");
        (reasonValue == AVAudioSessionRouteChangeReasonNewDeviceAvailable) ? NSLog(@"     NewDeviceAvailable") :
        NSLog(@"     OldDeviceUnavailable");
    }
}

@end
