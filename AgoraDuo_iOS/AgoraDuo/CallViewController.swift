//
//  CallViewController.swift
//  AgoraDuo
//
//  Created by Qin Cindy on 9/2/16.
//  Copyright © 2016 Qin Cindy. All rights reserved.
//

import UIKit
import AVFoundation

class CallViewController: UIViewController {
    
    //Outlets
    @IBOutlet weak var acceptCallButton: UIButton!
    @IBOutlet weak var endCallButton: UIButton!
    @IBOutlet weak var cameraSwitchButton: UIButton!

    
    @IBOutlet weak var callTextField: UITextField!
    @IBOutlet weak var callAlignCenter: NSLayoutConstraint!
    @IBOutlet weak var endcallAlignCenter: NSLayoutConstraint!
    @IBOutlet weak var smallVideoView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var informationLabel: UILabel!
    
    @IBOutlet weak var inCallMessageLabel: UILabel!
    @IBOutlet weak var callContainerView: UIView!
    @IBOutlet weak var callContainerViewBottomConstraint: NSLayoutConstraint!
    
    var callToNumber: String = ""
    // Main view show peer video
    var isShowPeer = true
    
    var audioPlayer: AVAudioPlayer?
    var isAudioStopBeforeJoin = true
    var isAudioStopAfterJoin = true
    
//MARK: Code start
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callTextField.delegate = self
        callTextField.keyboardType = .numberPad
        
        Agora.sharedInstance.updateDelegate = { status in
            print("Agora.sharedInstance \(status)")
            DispatchQueue.main.async(execute: {
                self.updateUI(status)
            })
        
        }

        updateUI(Agora.sharedInstance.status)

        initMusicPlayerBeforeJoin()
        
            }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Agora.sharedInstance.inSpeakeDelegate = { isSpeake in
            
            guard self.inCallMessageLabel.isHidden == false else {
                return
            }
            DispatchQueue.main.async(execute: {
                if isSpeake {
                    self.inCallMessageLabel.text = "对方在说话".localized()
                } else {
                    if self.inCallMessageLabel.text != "对方已静音".localized() {
                        self.inCallMessageLabel.text = ""
                    }
                    
                }
            })
        }
        
        Agora.sharedInstance.inMuteDelegate = { isMute in
            guard self.inCallMessageLabel.isHidden == false else {
                return
            }
            
            
            DispatchQueue.main.async(execute: {
                if isMute {
                    self.inCallMessageLabel.text = "对方已静音".localized()
                } else {
                    self.inCallMessageLabel.text = ""
                }
            })
        }

        smallVideoView.layer.cornerRadius = smallVideoView.frame.height/2
        smallVideoView.layer.masksToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Agora.sharedInstance.inSpeakeDelegate = nil
        Agora.sharedInstance.inMuteDelegate = nil

    }
    
    func updateUI(_ status: AgoraStatusMachine) {
        switch (status) {
        case .login:
            callTextField.isHidden = false
            inCallMessageLabel.isHidden = true
            showCallView()
            smallVideoView.isHidden = true

            informationLabel.text = "您的号码是: ".localized() + Configuration.sharedInstance.myPhoneNumber!
            updateVideoView(false)
            
        case .refuseCall:
            callTextField.isHidden = false
            inCallMessageLabel.isHidden = true
            smallVideoView.isHidden = true

            showCallView()
            informationLabel.text = "通话已拒绝".localized()
            updateVideoView(false)
            stopPlayAfterJoin()
            
        case .endCall:
            callTextField.isHidden = false
            inCallMessageLabel.isHidden = true
            smallVideoView.isHidden = true

            showCallView()
            informationLabel.text = "通话已结束".localized()
            updateVideoView(false)
            stopPlayBeforeJoin()
            
        case .calling:
            callTextField.isHidden = true
            inCallMessageLabel.isHidden = true
//            smallVideoView.isHidden = true

            hideCallView()
            showStopcallHideCall()
            informationLabel.text = "正在打电话给".localized() + callToNumber
            updateVideoView(false)
            startPlayAfterJoin()
            
        case .inCall:
            informationLabel.text = "正在通话中".localized()
            callTextField.isHidden = true
            inCallMessageLabel.isHidden = false
            showStopcallHideCall()
            smallVideoView.isHidden = false
            
            updateVideoView(true)
            stopPlayBeforeJoin()
            stopPlayAfterJoin()
            
        case .receiveCalling:
            callTextField.isHidden = true
            inCallMessageLabel.isHidden = true
            smallVideoView.isHidden = true
            
            informationLabel.text = "接收到电话:".localized() + Agora.sharedInstance.callFrom
            hideCallView()
            showCallShowStopCall()
            updateVideoView(true)
            startPlayBeforeJoin()
        default:
            break;
        }
    }
    
    func showCallShowStopCall() {
        acceptCallButton.isEnabled = true
        endCallButton.isEnabled = true
        
        if callAlignCenter.constant == 0 {
            callAlignCenter.constant = self.view.frame.width/4
        }
        
        if endcallAlignCenter.constant == 0 {
            endcallAlignCenter.constant = -self.view.frame.width/4
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.setNeedsLayout()
            self.acceptCallButton.alpha = 1.0
            self.endCallButton.alpha = 1.0
        })
    }
    
    func showCallView() {
        cameraSwitchButton.isHidden = true
        muteButton.isHidden = true
        
        guard callContainerViewBottomConstraint.constant != 0 else {
            return
        }
        

        callContainerViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.callContainerView.alpha = 1
            self.view.layoutIfNeeded()
        })
        
    }
    
    func hideCallView() {
        cameraSwitchButton.isHidden = false
        muteButton.isHidden = false
        guard callContainerViewBottomConstraint.constant == 0 else {
            return
        }
        

        
        callContainerViewBottomConstraint.constant = -callContainerView.frame.height

        UIView.animate(withDuration: 0.3, animations: {
            self.callContainerView.alpha = 0
            self.view.layoutIfNeeded()
        })
    }
    
    func showStopcallHideCall() {
        acceptCallButton.isEnabled = false
        endCallButton.isEnabled = true
        
        if callAlignCenter.constant != 0 {
            callAlignCenter.constant = 0
        }
        
        if endcallAlignCenter.constant != 0 {
            endcallAlignCenter.constant = 0
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.setNeedsLayout()
            self.acceptCallButton.alpha = 0.0
            self.endCallButton.alpha = 1.0
        })
    }
    
    func updateVideoView(_ showPeer: Bool) {
        
        if showPeer == isShowPeer {
            return
        }
        isShowPeer = showPeer
        if !isShowPeer {
            Agora.sharedInstance.setUpVideo(videoView)

        } else {
            Agora.sharedInstance.setUpVideo(smallVideoView)
            Agora.sharedInstance.peerViewHolder = videoView
            
        }
    }

//MARK: Button actions
    var isReceiver = false
    
    @IBAction func pressAcceptCallButton(_ sender: UIButton) {
        
        isReceiver = true
        Agora.sharedInstance.acceptCall(Configuration.sharedInstance.myPhoneNumber!)
        
    }
    
    @IBAction func pressEndCall(_ sender: UIButton) {
        
        guard let myPhoneNumber = Configuration.sharedInstance.myPhoneNumber else { return }
        
        if Agora.sharedInstance.status == .receiveCalling {
            stopPlayBeforeJoin()
            Agora.sharedInstance.refuseCall(myPhoneNumber)
        } else {
            stopPlayAfterJoin()
            if isReceiver {
                Agora.sharedInstance.endCall(Agora.sharedInstance.callFrom)
            } else {
                Agora.sharedInstance.endCall(Agora.sharedInstance.callTo)

            }
            
        }
    }
    
    @IBAction func pressCameraSwitchButton(_ sender: UIButton) {
        Agora.sharedInstance.switchCamera()
        
    }
    

    var isMute = false
    
    @IBOutlet weak var muteButton: UIButton!

    
    @IBAction func pressMuteButton(_ sender: UIButton) {
        isMute = !isMute
        if isMute {
            
            muteButton.setImage(UIImage(named: "mute"), for: UIControlState.normal)
        } else {
            muteButton.setImage(UIImage(named: "unMute"), for: UIControlState.normal)
        }
        Agora.sharedInstance.muteVolume(mute: isMute)
    }

    
    @IBAction func pressCallButton(_ sender: UIButton) {
        guard callToNumber != "" else {
            SVProgressHUD.showError(withStatus: "输入的号码不正确!")
            return
        }
        isReceiver = false
        Agora.sharedInstance.callTo(callToNumber)
    }
    
}

extension CallViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //todo: add isNumber verification
        if let number = textField.text {
            callToNumber = number
        }
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    
}

// MusicPlayer
extension CallViewController: AVAudioPlayerDelegate {

    
    func startPlayAfterJoin() {
        if isAudioStopAfterJoin {
            isAudioStopAfterJoin = false
            let file = Bundle.main.path(forResource: "videoCall", ofType: "wav")!
            Agora.sharedInstance.startPlay(file)
        }

    }
    
    func stopPlayAfterJoin() {
        if !isAudioStopAfterJoin {
            isAudioStopAfterJoin = true
            Agora.sharedInstance.stopPlay()
        }

    }
    


    func initMusicPlayerBeforeJoin() {
        
        let alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "videoCall", ofType: "wav")!)
        print(alertSound)
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.defaultToSpeaker)

        } catch let error as NSError {
            print("\(error) \(error.userInfo)")
        }
        
        
        do {
             try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("\(error) \(error.userInfo)")
        }
        
        do {
            audioPlayer =  try AVAudioPlayer(contentsOf: alertSound)
        } catch let error as NSError {
            print("\(error) \(error.userInfo)")
        }
        

        audioPlayer?.delegate = self

    }
    
    func startPlayBeforeJoin() {
        if isAudioStopBeforeJoin {
            isAudioStopBeforeJoin = false
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        }

    }
    
    func stopPlayBeforeJoin() {
        if !isAudioStopBeforeJoin {
            isAudioStopBeforeJoin = true
            audioPlayer?.stop()
        }

    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !isAudioStopBeforeJoin {
            player.play()
        }
        
    }


}
