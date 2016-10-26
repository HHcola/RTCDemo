//
//  Agora.swift
//  AgoraDuo
//
//  Created by Qin Cindy on 9/2/16.
//  Copyright © 2016 Qin Cindy. All rights reserved.
//

import Foundation

enum AgoraStatusMachine: Int {
    case logout
    case login
    case calling
    case inCall
    case receiveCalling
    case refuseCall
    case endCall
    case callFail
}

class Agora: NSObject {
    

    /// shared instance of Configuration (singleton)
    static let sharedInstance = Agora()
    
    var agoraInstance: AgoraAPI!
    var rtcEngineInstance: AgoraRtcEngineKit!
    var uid: UInt32 = 0
    var remoteUid: UInt = 0
    var status: AgoraStatusMachine!
    var updateDelegate: ((_ status: AgoraStatusMachine)->())?
    var updateVideoEnable:((_ isEnable: Bool)->())?
    // Peer mute or not
    var inMuteDelegate: ((_ isMute: Bool)->())?
    // Peer speake or not
    var inSpeakeDelegate: ((_ isSpeake: Bool)->())?
    
    var callFrom: String = ""
    var callTo: String = ""
    
    var peerViewHolder: UIView?
    
    override init() {
        
        super.init()
        agoraInstance = AgoraAPI.getInstanceWithoutMedia(Configuration.sharedInstance.appid)
        rtcEngineInstance = AgoraRtcEngineKit.sharedEngine(withAppId: Configuration.sharedInstance.appid, delegate: self)
        rtcEngineInstance.setParameters("{\"rtc.log_filter\":32783}")

        status = .logout
        
        initCallbackHandler()
        rtcEngineInstance.enableAudioVolumeIndication(1000, smooth: 3)
    }
    
    func initCallbackHandler() {
        loginCallback()
        inviteCallback()

    }
    
    func loginCallback() {
        agoraInstance.onLoginSuccess = { (uid, fd) in
            self.uid = uid
            self.status = .login
            self.updateDelegate?(self.status)
        }
        //onLogout
        
        agoraInstance.onLoginFailed = { ecode in
            self.status = .logout
            DispatchQueue.main.async(execute: {
                
                SVProgressHUD.showError(withStatus: "登录失败".localized()+"\(ecode)")
                self.updateDelegate?(self.status)
            })
        }
    }
    
    
    func startPlay(_ file: String) {
        rtcEngineInstance.startAudioMixing(file, loopback: false, replace: false, cycle: -1)
    }
    
    func stopPlay() {
        rtcEngineInstance.stopAudioMixing()
    }
    
    func inviteCallback() {
        agoraInstance.onInviteFailed = {(channelID, account, uid, ecode) in
            self.status = .refuseCall
            self.updateDelegate?(self.status)
            self.leaveChannel(channelID!)
            DispatchQueue.main.async(execute: {
                
                SVProgressHUD.showError(withStatus: "呼叫失败: ".localized()+"\(ecode)")
            })
        }
        
        agoraInstance.onInviteAcceptedByPeer = { (channel, name, uid) in
            self.status = .inCall
            self.rtcEngineInstance.muteLocalAudioStream(false)
            self.rtcEngineInstance.muteLocalVideoStream(false)
            self.updateDelegate?(self.status)
        }
        
        agoraInstance.onInviteReceived = { (channel, name, uid) in
            self.status = .receiveCalling
            self.callFrom = name!
            self.joinCall(Configuration.sharedInstance.myPhoneNumber!)
            self.updateDelegate?(self.status)
        }
        
        
        agoraInstance.onInviteRefusedByPeer = { (channel, name, uid) in
            self.status = .refuseCall
            self.updateDelegate?(self.status)
            self.leaveChannel(channel!)
        }
        
        agoraInstance.onInviteEndByPeer = { (channel, name, uid) in
            self.status = .endCall
            self.updateDelegate?(self.status)
            self.leaveChannel(channel!)
        }
        
        agoraInstance.onInviteEndByMyself = { (channel, name, uid) in
            self.status = .endCall
            self.updateDelegate?(self.status)
        }
        
        


        
    }
    
    func login() {
        
        guard let myPhoneNumber = Configuration.sharedInstance.myPhoneNumber else {
            return
        }
        let time = Date().timeIntervalSince1970 + 3600
        let token = AgoraHelper.calcToken(Configuration.sharedInstance.appid, signKey: Configuration.sharedInstance.certificate, account: myPhoneNumber, expiredTime: UInt32(time))
        agoraInstance.login(Configuration.sharedInstance.appid, account: myPhoneNumber, token: token, uid: uid, deviceID: "")
    }
    
    func setUpVideo(_ videoView: UIView) {
        
        rtcEngineInstance.enableVideo()
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 0
        canvas.view = videoView
        canvas.renderMode = .render_Hidden
        rtcEngineInstance.setupLocalVideo(canvas)

        rtcEngineInstance.startPreview()
    }
    
    func setUpPeerVideo(_ videoView: UIView) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = remoteUid

        canvas.view = videoView
        canvas.renderMode = .render_Hidden
        rtcEngineInstance.setupRemoteVideo(canvas)
    }
    
    func enableVideoMode() {
        rtcEngineInstance.enableVideo()
        rtcEngineInstance.startPreview()
    }

    func disableVideoMode() {
        rtcEngineInstance.disableVideo()
        rtcEngineInstance.stopPreview()
    }
    
    func switchCamera() {
        rtcEngineInstance.switchCamera()
    }
    
    func joinChannel(_ callToNumber: String) {
        

        agoraInstance.channelJoin(callToNumber)
        
        rtcEngineInstance.joinChannel(byKey: Configuration.sharedInstance.appid, channelName: callToNumber, info: callToNumber, uid: UInt(self.uid)) { (a, b, c) in
            self.rtcEngineInstance.setEnableSpeakerphone(true)

        }

        
    }
    
    func leaveChannel(_ callToNumber: String) {
        agoraInstance.channelLeave(callToNumber)
        rtcEngineInstance.leaveChannel(nil)
    }
    
    func callTo(_ phoneName: String) {
        
        callTo = phoneName
        callFrom = Configuration.sharedInstance.myPhoneNumber!
        status = .calling
        
        rtcEngineInstance.muteLocalAudioStream(true)
        rtcEngineInstance.enableVideo()

        joinChannel(phoneName)
        agoraInstance.channelInviteUser(phoneName, account: phoneName, uid: 0)
        updateDelegate?(status)
    }
    
    func endCall(_ peerPhoneNumber: String) {

        leaveChannel(callTo)

        agoraInstance.channelInviteEnd(callTo, account: peerPhoneNumber, uid: 0)
        
    }
    
    func joinCall(_ callToNumber: String) {
        
        guard callFrom != "" else { return }
        callTo = callToNumber
        rtcEngineInstance.muteLocalAudioStream(true)
        rtcEngineInstance.muteLocalVideoStream(true)
        joinChannel(callToNumber)

    }
    
    func acceptCall(_ callToNumber: String) {
        rtcEngineInstance.muteLocalAudioStream(false)
        rtcEngineInstance.muteLocalVideoStream(false)
        agoraInstance.channelInviteAccept(callToNumber, account: self.callFrom, uid: 0)
        status = .inCall
        updateDelegate?(status)
    }

    
    func refuseCall(_ callToNumber: String){
        self.status = .refuseCall
        print("callToNumber \(callToNumber) callFrom \(callFrom)")
        agoraInstance.channelInviteRefuse(callToNumber, account: callFrom, uid: 0)
        updateDelegate?(self.status)
    }
    
    func muteVolume(mute: Bool) {
        rtcEngineInstance.muteLocalAudioStream(mute)
    }
}


extension Agora: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        self.remoteUid = uid
        guard let peerView = peerViewHolder else { return}
        DispatchQueue.main.async {
            self.setUpPeerVideo(peerView)
        }
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didVideoEnabled enabled: Bool, byUid uid: UInt) {
        updateVideoEnable?(enabled)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, reportAudioVolumeIndicationOfSpeakers speakers: [Any]!, totalVolume: Int) {
        
        let users = speakers as! [AgoraRtcAudioVolumeInfo]
        for user in users {
            if user.uid == 0 {
                continue
            }
            if user.volume > 0{
                inSpeakeDelegate?(true)
            } else {
                inSpeakeDelegate?(false)
            }
        }
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didAudioMuted muted: Bool, byUid uid: UInt) {
        inMuteDelegate?(muted)
    }
}
