//
//  AgoraVideoSource+CameraSource.m
//  OpenLive
//
//  Created by Qin Cindy on 10/17/16.
//  Copyright © 2016 Agora. All rights reserved.
//

#import "AgoraVideoSource+CameraSource.h"


@implementation AgoraVideoSource (CameraSource)


void NV21ToI420(const unsigned char *nv21,
                int width,
                int height,
                unsigned char *i420
                )
{
    if(width <= 0 || height <= 0)
        return;
    
    const unsigned char *yIn = nv21;
    unsigned char *y = i420;
    const unsigned char *uvIn = yIn + width * height;
    unsigned char *u = y + width * height;
    unsigned char *v = u + width * height / 4;
    
    // y
    memcpy(y, yIn, width * height);
    
    // uv
    int i;
    int cheight = height / 2;
    int cwidth = width / 2;
    for(i=0; i<cheight; i++)
    {
        int j;
        // ASSERT(cwidth & 1 == 0);
        for(j=0; j<cwidth/2; j++)
        {
            unsigned int iv = *(unsigned int *)uvIn; // 32-bit cpu
            uvIn += 4;
            *u++ = iv & 0xFF;
            *v++ = (iv >> 8) & 0xFF;
            *u++ = (iv >> 16) & 0xFF;
            *v++ = (iv >> 24) & 0xFF;
        }
        uvIn += width - cwidth * 2;
        u += cwidth - cwidth;
        v += cwidth - cwidth;
    }
}

- (int) getDisplayRotation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    switch(orientation) {
        case UIDeviceOrientationPortrait:
        default:
            return 0;
        case UIDeviceOrientationLandscapeLeft:
            return 90;
        case UIDeviceOrientationPortraitUpsideDown:
            return 180;
        case UIDeviceOrientationLandscapeRight:
            return 270;
    }
}



- (void)captureOutputSampleBuffer:(GPUImageOutput *)output isFrontCamera: (Boolean)isFront time: (CMTime)time {
    
    const int kFlags = 0;

    CVPixelBufferRef videoFrame = output.framebufferForOutput.pixelBuffer;
    
//    OSType type = CVPixelBufferGetPixelFormatType(videoFrame);
    if (CVPixelBufferLockBaseAddress(videoFrame, kFlags) != kCVReturnSuccess) {
        // TODO: treat as error?
        return;
    }
    
    const int kYPlaneIndex = 0;
    
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(videoFrame, kYPlaneIndex);

    int width = (int)CVPixelBufferGetWidth(videoFrame);
    int height = (int)CVPixelBufferGetHeight(videoFrame);

    [self DeliverFrame:baseAddress width:width height:height cropLeft:0 cropTop:0 cropRight:0 cropBottom:0 rotation:0 timeStamp:CACurrentMediaTime() * 1000 format:2];
    
    CVPixelBufferUnlockBaseAddress(videoFrame, kFlags);
}




@end
