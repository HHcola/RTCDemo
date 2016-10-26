//
//  AgoraVideoSource+CameraSource.h
//  OpenLive
//
//  Created by Qin Cindy on 10/17/16.
//  Copyright © 2016 Agora. All rights reserved.
//


#import <videoprp/AgoraVideoSourceObjc.h>
#import "GPUImageOutput.h"

@interface AgoraVideoSource (CameraSource)

- (void)captureOutputSampleBuffer:(GPUImageOutput *)output isFrontCamera: (Boolean)isFront time: (CMTime)time;

@end
