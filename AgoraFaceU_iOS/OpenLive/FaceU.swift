//
//  FaceU.swift
//  OpenLive
//
//  Created by Qin Cindy on 10/14/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Foundation
import facekit

struct Effect {
    var displayName: String!
    var indexName: String!
    var tag: LMFilterPos!
}
class FaceU: NSObject, LMCameraOutput {
    /// shared instance of Configuration (singleton)
    static let sharedInstance = FaceU()
    fileprivate var camera: LMCamera!
    fileprivate var renderEngine: LMRenderEngine!
    fileprivate var facekitOutput: GPUFacekitOutput!
    fileprivate var passthroughFilter: GPUImageFilter!
    
    fileprivate var resBundle: Bundle!
    fileprivate var effectPos: LMFilterPos?
    fileprivate var videoSource: AgoraVideoSource!
    
    fileprivate var gpuImageView: GPUImageView?
    
    let effects = [ Effect(displayName: "大眼", indexName: "surgery/bigeyes", tag: 150),
                    Effect(displayName: "大颜瘦脸", indexName: "surgery/bigeyesAndSlimface", tag: 151),
                    Effect(displayName: "Cute脸", indexName: "surgery/lovely", tag: 152),
                    Effect(displayName: "蛇脸", indexName: "surgery/snakeface", tag: 153),
                    Effect(displayName: "猫耳", indexName: "effect/cat_ear", tag: 1),
                    Effect(displayName: "嘻哈", indexName: "effect/hiphop", tag: 2),
                    Effect(displayName: "长草", indexName: "effect/zhangcao", tag: 3),
                    Effect(displayName: "扇子", indexName: "effect/rifeng_b", tag: 4),
                    Effect(displayName: "鹿", indexName: "effect/SikaDeer", tag: 5),
                    Effect(displayName: "丐帮", indexName: "effect/j3_gaibang", tag: 6),
                    Effect(displayName: "猫趴", indexName: "effect/maopa", tag: 8),
                    Effect(displayName: "猫妖", indexName: "effect/maoyao_mz", tag: 9),
                    Effect(displayName: "猪猪", indexName: "effect/animal_zhuzhu_b", tag: 11),
                    Effect(displayName: "手猫", indexName: "effect/animal_mycat", tag: 12),
    ]
    
    // Position是贴纸中meta.json定义的，决定引擎替换效果还是叠加效果，数值相同则替换。
    // 建议不要hardcode此信息，我们提供的贴纸可能会有position的变化。
    fileprivate static let LMFilterPosBeauty: LMFilterPos = 100;
    fileprivate static let  LMFilterPosFilter: LMFilterPos = 120;
    fileprivate static let  LMFilterPosReshape: LMFilterPos = 140;
    fileprivate static let  LMFilterPosSticker: LMFilterPos = 4000;
    
    fileprivate let colseEffects = [
    Effect(displayName: "关闭美颜", indexName: "", tag: LMFilterPosBeauty),
    Effect(displayName: "关闭滤镜", indexName: "", tag: LMFilterPosFilter),
    Effect(displayName: "关闭整形", indexName: "", tag: LMFilterPosReshape),
    Effect(displayName: "关闭贴纸", indexName: "", tag: LMFilterPosSticker),
    ]
    
    var currentFilter: LMFilterPos = -99
    
    override init() {
        
        super.init()

        camera = LMCamera(position: AVCaptureDevicePosition.front, cameraSessionPreset:  AVCaptureSessionPreset1280x720, pixelFormatType: kCVPixelFormatType_32BGRA)
        camera.setFrameRate(25)
        camera.setCameraOutput(self)
        
        renderEngine = LMRenderEngine(forTextureWith: GPUImageContext.sharedImageProcessing().context, queue: GPUImageContext.sharedContextQueue())
        facekitOutput = GPUFacekitOutput(renderEngine: renderEngine)
        passthroughFilter = GPUImageFilter()
        facekitOutput.addTarget(passthroughFilter)
        facekitOutput.horizontallyMirrorRearFacingCamera = true
        facekitOutput.horizontallyMirrorFrontFacingCamera = true
        facekitOutput.outputImageOrientation = UIInterfaceOrientation.portrait
        if let path = Bundle.main.path(forResource: "LMEffectResource", ofType: "bundle") {
            resBundle = Bundle(path: path)
        } else {
            assert(true, "LMEffectResource hasn't been found")
        }

        regPixelBuffer()

    }
    
    func closeFaceEffects() {
        
        if currentFilter != -99 {
            renderEngine.stopFilter(currentFilter)
        }
        
        for effect in colseEffects {
            renderEngine.stopFilter(effect.tag)
        }
    }
    
    func switchCamera() {
    
        camera.rotateCamera()
    }
    
    func onFaceEffect(forIndex index: Int) {
        let effect = effects[index]
        let path = resBundle.path(forResource: effect.indexName, ofType: "")
        let pos = renderEngine.apply(withPath: path)
        currentFilter = pos
        print("applied pos: \(pos)")
    }
    
    func configure(videoSource: AgoraVideoSource) {
        self.videoSource = videoSource

    }
    
    func addFaceUToLocalSession(localView: UIView) {
        
        gpuImageView = GPUImageView(frame: localView.frame)
        gpuImageView?.fillMode = GPUImageFillModeType.preserveAspectRatioAndFill
        localView.addSubview(gpuImageView!)
        facekitOutput.addTarget(gpuImageView!)
    }
    
    func removeFaceUFromLocalSession() {
        if let localView = gpuImageView {
            localView.removeFromSuperview()
            facekitOutput.removeTarget(localView)
        }

    }
    
    func startCapture() {
        camera.startCapture()
    }
    
    func stopCapture() {
        camera.stopCapture()
    }
    
    func regPixelBuffer() {
        
        print("enter regPixelBuffer")
        passthroughFilter.frameProcessingCompletionBlock = { (output, time) in
            if let theOutput = output {
                self.videoSource.captureOutputSampleBuffer(theOutput, isFrontCamera: true, time: time)
            }

        }
    }
    
    func camera(_ camera: LMCamera!, with sampleBuffer: CMSampleBuffer!) {
        facekitOutput.processSampleBuffer(sampleBuffer)
    }

}

