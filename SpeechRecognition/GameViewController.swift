//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by hadis on 6/28/1398 AP.
//  Copyright © 1398 hadis. All rights reserved.
//

import UIKit
import Speech
import AVKit
import AVFoundation

class GameViewController: UIViewController {
    
    var openEarsEventsObserver = OEEventsObserver()

    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var arrowImageBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var resultTextLabel: UILabel!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var videoView: UIView!
    
//    var videoView: UIView?
    
    var lmPath: String?
    var dicPath: String?
    
    let sensitiveWords = ["up", "ba", "ma", "sh"]
    let arrowTopMovementValue: CGFloat = 10
    let arrowBottomMovementValue: CGFloat = 2
    var problemCount = 0
    let maxProblemCountLimit = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestSpeechAuthorization()
    }
    
    func setupOpenEars() {
        
        if lmPath == nil && dicPath == nil {
            self.openEarsEventsObserver.delegate = self
            
            let lmGenerator = OELanguageModelGenerator()
            
            let name = "NameIWantForMyLanguageModelFiles"
            let err: Error! = lmGenerator.generateLanguageModel(from: sensitiveWords, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
            
            if let err = err {
                print("Error while creating initial language model: \(err)")
            } else {
                lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModel(withRequestedName: name)
                dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: name)
                
                self.startListening()
            }
        }
    }
    
    public func startListening() {
        guard let listener = OEPocketsphinxController.sharedInstance() else { return }
        listener.vadThreshold = 3.4
//        listener.returnNbest = true
        listener.secondsOfSilenceToDetect = 0.3
//        listener.nBestNumber = 10
        if listener.isSuspended {
            listener.resumeRecognition()
        } else {
            do {
                try listener.setActive(true)
                listener.startListeningWithLanguageModel(atPath: lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
            } catch {
                print("Error: it wasn't possible to set the shared instance to active: \"\(error)\"")
            }
        }
    }
    
    public func stopListening() {
        guard let listener = OEPocketsphinxController.sharedInstance() else { return }
        listener.suspendRecognition()
        print("stopped")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func moveArrowTop() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            let topOfArrowImage = self.arrowImage.frame.origin.y - self.arrowTopMovementValue
            let bottomOfHeartImage = self.heartImageView.frame.height + self.heartImageView.frame.origin.y

            if topOfArrowImage >= bottomOfHeartImage {
                self.arrowImageBottomSpace.constant += self.arrowTopMovementValue
            } else {
                self.arrowImageBottomSpace.constant += self.arrowTopMovementValue
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.arrowImageBottomSpace.constant = CGFloat(30.0)
                })
            }
            self.view.layoutIfNeeded()
        })
    }
    
    func moveArrowBottom() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            if (self.arrowImageBottomSpace.constant - self.arrowBottomMovementValue) > 30 {
                self.arrowImageBottomSpace.constant -= self.arrowBottomMovementValue
                self.view.layoutIfNeeded()
            }
        })
    }
    
    func setRecognizedText(text: String) {
        self.resultTextLabel.text = text
        self.resultTextLabel.fadeIn()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.resultTextLabel.fadeOut()
        }
    }
    
    func setProblemCount() {
        problemCount += 1
        if problemCount > self.maxProblemCountLimit {
            problemCount = 0
            self.playVideo()
        }
    }
    
    private func playVideo() {
        guard let path = Bundle.main.path(forResource: "sh", ofType:"mp4") else {
            self.sendAlert(message: "video not found")
            return
        }
        self.view.bringSubviewToFront(self.videoView)
        stopListening()
        videoView.cornerRadius = 4.0
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = false
        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.frame = videoView.bounds
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.addSublayer(layer)
        playerController.player?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func playerDidFinishPlaying() {
        self.view.sendSubviewToBack(self.videoView)
        startListening()
        self.videoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
    
//    func makeVideoView() {
//        self.videoView = UIView()
//        videoView?.
//    }

    
    //MARK: - Check Authorization Status
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.setupOpenEars()
                case .denied:
                    self.sendAlert(message: "User denied access to speech recognition", alertAction: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    })
                case .restricted:
                    self.sendAlert(message: "Speech recognition restricted on this device", alertAction: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    })
                case .notDetermined:
                    self.sendAlert(message: "Speech recognition not yet authorized")
                @unknown default:
                    self.sendAlert(message: "Speech recognition not yet authorized")
                }
            }
        }
    }
    
}

extension GameViewController: OEEventsObserverDelegate {
    func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!) { // Something was heard
        if hypothesis.contains(" ") { return }
        print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")

        if sensitiveWords.contains(hypothesis) && ((Int(recognitionScore) ?? -60000) > -60000) {
            setRecognizedText(text: hypothesis)
            self.moveArrowTop()
        } else if !sensitiveWords.contains(hypothesis) || ((Int(recognitionScore) ?? -60000) <= -60000) {
            setProblemCount()
            self.moveArrowBottom()
        }
    }
    
//    func pocketsphinxDidReceiveNBestHypothesisArray(_ hypothesisArray: [Any]!) {
//        var successCount = 0
//        var theWord = ""
//
//        for hypothesis in hypothesisArray {
//            let hypoth = (hypothesis as! [String:Any])["Hypothesis"] as! String
//            let score = (hypothesis as! [String:Any])["Score"] as! Int
//            print("\(hypoth) -- \(score)")
//
//            if sensitiveWords.contains(hypoth) && score > -50000 && (theWord.isEmpty || theWord == hypoth) {
//                theWord = hypoth
//                successCount += 1
//            }
//        }
//
//        if successCount > 3 {
//            setRecognizedText(text: theWord)
//            self.moveArrow()
//        }
//    }
    
    // An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
    // This might be useful in debugging a conflict between another sound class and Pocketsphinx.
    func pocketsphinxRecognitionLoopDidStart() {
        print("Local callback: Pocketsphinx started.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
    func pocketsphinxDidStartListening() {
        print("Local callback: Pocketsphinx is now listening.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
    func pocketsphinxDidDetectSpeech() {
        print("Local callback: Pocketsphinx has detected speech.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance.
    func pocketsphinxDidDetectFinishedSpeech() {
        print("Local callback: Pocketsphinx has detected a second of silence, concluding an utterance.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx has exited its recognition loop, most
    // likely in response to the OEPocketsphinxController being told to stop listening via the stopListening method.
    func pocketsphinxDidStopListening() {
        print("Local callback: Pocketsphinx has stopped listening.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
    // Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
    // in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
    // or as a result of the OEPocketsphinxController being told to suspend recognition via the suspendRecognition method.
    func pocketsphinxDidSuspendRecognition() {
        print("Local callback: Pocketsphinx has suspended recognition.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
    // having been suspended it is now resuming.  This can happen as a result of Flite speech completing
    // on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
    // or as a result of the OEPocketsphinxController being told to resume recognition via the resumeRecognition method.
    func pocketsphinxDidResumeRecognition() {
        print("Local callback: Pocketsphinx has resumed recognition.") // Log it.
    }
    
    // An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
    // recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
    func pocketsphinxDidChangeLanguageModel(toFile newLanguageModelPathAsString: String!, andDictionary newDictionaryPathAsString: String!) {
        
        print("Local callback: Pocketsphinx is now using the following language model: \n\(newLanguageModelPathAsString!) and the following dictionary: \(newDictionaryPathAsString!)")
    }
    
    // An optional delegate method of OEEventsObserver which informs that Flite is speaking, most likely to be useful if debugging a
    // complex interaction between sound classes. You don't have to do anything yourself in order to prevent Pocketsphinx from listening to Flite talk and trying to recognize the speech.
    func fliteDidStartSpeaking() {
        print("Local callback: Flite has started speaking") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Flite is finished speaking, most likely to be useful if debugging a
    // complex interaction between sound classes.
    func fliteDidFinishSpeaking() {
        print("Local callback: Flite has finished speaking") // Log it.
    }
    
    func pocketSphinxContinuousSetupDidFail(withReason reasonForFailure: String!) { // This can let you know that something went wrong with the recognition loop startup. Turn on [OELogging startOpenEarsLogging] to learn why.
        print("Local callback: Setting up the continuous recognition loop has failed for the reason \(reasonForFailure ?? ""), please turn on OELogging.startOpenEarsLogging() to learn more.") // Log it.
    }
    
    func pocketSphinxContinuousTeardownDidFail(withReason reasonForFailure: String!) { // This can let you know that something went wrong with the recognition loop startup. Turn on OELogging.startOpenEarsLogging() to learn why.
        print("Local callback: Tearing down the continuous recognition loop has failed for the reason \(reasonForFailure ?? "")") // Log it.
    }
    
    /** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
    func pocketsphinxFailedNoMicPermissions() {
        print("Local callback: The user has never set mic permissions or denied permission to this app's mic, so listening will not start.")
    }
    
    /** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a true or a false result  (will only be returned on iOS7 or later).*/
    
    func micPermissionCheckCompleted(withResult: Bool) {
        print("Local callback: mic check completed.")
    }
}
