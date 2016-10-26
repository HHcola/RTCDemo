//
//  LiveRoomViewController.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit

protocol LiveRoomVCDelegate: NSObjectProtocol {
    func liveVCNeedClose(_ liveVC: LiveRoomViewController)
}

class LiveRoomViewController: UIViewController {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var remoteContainerView: UIView!
    @IBOutlet weak var broadcastButton: UIButton!

    @IBOutlet weak var audioMuteButton: UIButton!
    @IBOutlet var sessionButtons: [UIButton]!
    
    @IBOutlet weak var faceUContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var faceUCollectView: UICollectionView!
    @IBOutlet weak var faceUVIewContainer: UIView!
    var roomName: String!
    var clientRole = AgoraRtcClientRole.clientRole_Audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    var videoProfile: AgoraRtcVideoProfile!
    weak var delegate: LiveRoomVCDelegate?
    
    //MARK: - engine & session view
    var rtcEngine: AgoraRtcEngineKit!
    var agoraEnhancer: AgoraYuvEnhancerObjc?
    var videoSrc: AgoraVideoSource?

    fileprivate var isBroadcaster: Bool {
        return clientRole == .clientRole_Broadcaster
    }
    fileprivate var isMuted = false {
        didSet {
            rtcEngine?.muteLocalAudioStream(isMuted)
            audioMuteButton?.setImage(UIImage(named: isMuted ? "btn_mute_cancel" : "btn_mute"), for: UIControlState())
        }
    }
    
    fileprivate var videoSessions = [VideoSession]() {
        didSet {
            guard remoteContainerView != nil else {
                return
            }
            updateInterfaceWithAnimation(true)
        }
    }
    fileprivate var fullSession: VideoSession? {
        didSet {
            if fullSession != oldValue && remoteContainerView != nil {
                updateInterfaceWithAnimation(true)
            }
        }
    }
    
    fileprivate let viewLayouter = VideoViewLayouter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = roomName
        updateButtonsVisiablity()
        
        loadAgoraKit()
        faceUCollectView.delegate = self
        faceUCollectView.dataSource = self
        initLayout()
        faceUContainerViewBottomConstraint.constant = -faceUVIewContainer.frame.height
        
    }
    
    //MARK: - user action
    
    @IBAction func pressFaceUButton(_ sender: UIButton) {
        showFaceUView()
    }
    
    @IBAction func pressFaceUCloseButton(_ sender: UIButton) {
        hideFaceUView()
        FaceU.sharedInstance.closeFaceEffects()
    }
    @IBAction func doSwitchCameraPressed(_ sender: UIButton) {
//        rtcEngine?.switchCamera()
        FaceU.sharedInstance.switchCamera()
    }
    
    @IBAction func doMutePressed(_ sender: UIButton) {
        isMuted = !isMuted
    }
    
    @IBAction func doBroadcastPressed(_ sender: UIButton) {
        if isBroadcaster {
            clientRole = .clientRole_Audience
            videoSrc?.detach()
            FaceU.sharedInstance.stopCapture()

        } else {
            clientRole = .clientRole_Broadcaster
            FaceU.sharedInstance.startCapture()
            videoSrc?.attach()
        }
        rtcEngine.setClientRole(clientRole, withKey: nil)
        updateInterfaceWithAnimation(true)
    }
    
    @IBAction func doDoubleTapped(_ sender: UITapGestureRecognizer) {
        if fullSession == nil {
            //将双击到的session全屏
            if let tappedSession = viewLayouter.reponseSessionOfGesture(sender, inSessions: videoSessions, inContainerView: remoteContainerView) {
                fullSession = tappedSession
            }
        } else {
            fullSession = nil
        }
    }
    
    @IBAction func doLeavePressed(_ sender: UIButton) {
        leaveChannel()
    }
    
    var preLocalSessionFrame: CGRect?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let localSession = self.fetchSessionOfUid(0) else {
            return
        }
        if preLocalSessionFrame != nil && localSession.canvas.view.frame != preLocalSessionFrame {
            print("frame change to \(localSession.canvas.view.frame)")
            FaceU.sharedInstance.removeFaceUFromLocalSession()
            FaceU.sharedInstance.addFaceUToLocalSession(localView: localSession.canvas.view)
        }
        preLocalSessionFrame = localSession.canvas.view.frame

        
    }
}

private extension LiveRoomViewController {
    
    func updateButtonsVisiablity() {
        guard sessionButtons != nil else {
            return
        }
        broadcastButton?.setImage(UIImage(named: isBroadcaster ? "btn_join_cancel" : "btn_join"), for: UIControlState())
        
        for button in sessionButtons {
            button.isHidden = !isBroadcaster
        }
    }
    
    func leaveChannel() {
        setIdleTimerActive(true)
        
//        rtcEngine.setupLocalVideo(nil)
        
        rtcEngine.leaveChannel(nil)
        if isBroadcaster {
            videoSrc?.detach()
            FaceU.sharedInstance.stopCapture()
//            rtcEngine.stopPreview()
        }
        
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
        
        agoraEnhancer?.turnOff()
        
        delegate?.liveVCNeedClose(self)
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
    
    func alertString(_ string: String) {
        guard !string.isEmpty else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: string, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

private extension LiveRoomViewController {
    func updateInterfaceWithAnimation(_ animation: Bool) {
        if animation {
            
            UIView.animate(withDuration: 0.3, animations: { [weak self] _ in
                self?.updateInterface()
                self?.remoteContainerView.layoutIfNeeded()

                })
        } else {
            updateInterface()
        }
    }
    
    
    
    func updateInterface() {
        var displaySessions = videoSessions
        if !isBroadcaster && !displaySessions.isEmpty {
            displaySessions.removeFirst()
        }
        viewLayouter.layoutSessions(displaySessions, fullSession: fullSession, inContainer: remoteContainerView)
        setStreamTypeForSessions(displaySessions, fullSession: fullSession)

    }
    
    func setStreamTypeForSessions(_ sessions: [VideoSession], fullSession: VideoSession?) {
        if let fullSession = fullSession {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: (session == fullSession ? .videoStream_High : .videoStream_Low))
            }
        } else {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: .videoStream_High)
            }
        }
    }
    func addLocalSession() {
        let localSession = VideoSession.localSession()
        videoSessions.append(localSession)
//        rtcEngine.setupLocalVideo(localSession.canvas)
        FaceU.sharedInstance.addFaceUToLocalSession(localView: localSession.canvas.view)
    }
    
    func fetchSessionOfUid(_ uid: Int64) -> VideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        
        return nil
    }
    
    func videoSessionOfUid(_ uid: Int64) -> VideoSession {
        if let fetchedSession = fetchSessionOfUid(uid) {
            return fetchedSession
        } else {
            let newSession = VideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
}

//MARK: - Agora Media SDK
private extension LiveRoomViewController {
    
    func loadAgoraKit() {
        
        rtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: VendorKey, delegate: self)
        rtcEngine.setChannelProfile(.channelProfile_LiveBroadcasting)
        rtcEngine.enableDualStreamMode(true)
        rtcEngine.enableVideo()
        rtcEngine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
        rtcEngine.setClientRole(clientRole, withKey: nil)

        videoSrc = AgoraVideoSource()
        // Init faceU
        if videoSrc != nil {
            FaceU.sharedInstance.configure(videoSource: videoSrc!)
        }
        
        if isBroadcaster {
//            rtcEngine.startPreview()
            videoSrc?.attach()
            FaceU.sharedInstance.startCapture()
        }

        addLocalSession()
        
        let code = rtcEngine.joinChannel(byKey: nil, channelName: roomName, info: nil, uid: 0, joinSuccess: nil)
        if code == 0 {
            setIdleTimerActive(false)
            rtcEngine.setEnableSpeakerphone(true)
        } else {
            DispatchQueue.main.async(execute: {
                self.alertString("Join channel failed: \(code)")
            })
        }
        
        if isBroadcaster {
            let enhancer = AgoraYuvEnhancerObjc()
            enhancer.turnOn()
            self.agoraEnhancer = enhancer
        }
    }
}

extension LiveRoomViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit!, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        // display remote view
        let userSession = videoSessionOfUid(Int64(uid))
        rtcEngine.setupRemoteVideo(userSession.canvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        if let _ = videoSessions.first {
            updateInterfaceWithAnimation(false)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerated() {
            if session.uid == Int64(uid) {
                indexToDelete = index
            }
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.remove(at: indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            
            if deletedSession == fullSession {
                fullSession = nil
            }
        }
        
        if let _ = videoSessions.first {
            updateInterfaceWithAnimation(false)
        }
    }
}

class FaceUCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
}

extension LiveRoomViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func initLayout() {
        // Collection view
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = UICollectionViewScrollDirection.vertical
        flowLayout.itemSize = CGSize(width: 100, height: 100) // the size will be redefined in UICollectionViewDelegate
        
        // Space between cells and between all cell and view bounds
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        self.faceUCollectView.contentInset = UIEdgeInsets.zero
        self.faceUCollectView.collectionViewLayout = flowLayout
    }
    
    
    
    // MARK: UICollectionViewDataSource, UICollectionViewDelegate
    
    /**
     Get number of cells
     
     - parameter collectionView: the collectionView
     - parameter section:        the section index
     
     - returns: the number of image
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FaceU.sharedInstance.effects.count
    }
    
    
    
    /**
     Get cell
     
     - parameter collectionView:       the collectionView
     - parameter indexPath:            the indexPath
     
     - returns: the cell
     */
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FaceUCollectionViewCell",
                                                      for: indexPath) as! FaceUCollectionViewCell

        cell.nameLabel.text = FaceU.sharedInstance.effects[indexPath.row].displayName
        return cell
    }
    
    
    
    /**
     Get cell size. Calculates depending on screen size.
     
     - parameter collectionView:       the collectionView
     - parameter collectionViewLayout: the layout
     - parameter indexPath:            the indexPath
     
     - returns: the size
     */
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return collectCellSize()
    }
    
    func collectCellSize() -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let n: CGFloat = 4
        
        let width: CGFloat = (screenWidth) / n
        let height: CGFloat = 45
        
        return CGSize(width: width, height: height)
    }
    
    /**
     Show Details screen when cell tapped
     
     - parameter collectionView:       the collectionView
     - parameter indexPath:            the indexPath
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        FaceU.sharedInstance.onFaceEffect(forIndex: indexPath.row)
        hideFaceUView()
        collectionView.deselectItem(at: indexPath, animated: true)
    }

}

//MARK: - faceU view
extension LiveRoomViewController {
    
    func showFaceUView() {
        
        
        guard faceUContainerViewBottomConstraint.constant != 0 else {
            return
        }
        
        
        faceUContainerViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.faceUVIewContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
        
    }
    
    func hideFaceUView() {
        
        guard faceUContainerViewBottomConstraint.constant == 0 else {
            return
        }
        
        faceUContainerViewBottomConstraint.constant = -faceUVIewContainer.frame.height
        
        UIView.animate(withDuration: 0.3, animations: {
            self.faceUVIewContainer.alpha = 0
            self.view.layoutIfNeeded()
        })
    }

}
