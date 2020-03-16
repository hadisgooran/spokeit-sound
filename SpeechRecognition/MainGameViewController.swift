//
//  MainGameViewController.swift
//  SpeechRecognition
//
//  Created by hadis on 10/14/1398 AP.
//  Copyright © 1398 hadis. All rights reserved.
//

import UIKit
import Speech
import AVKit
import AVFoundation

class MainGameViewController: UIViewController {
    
    @IBOutlet weak var redMigImageView: UIImageView!
    @IBOutlet weak var redMigTopConst: NSLayoutConstraint!
    
    @IBOutlet weak var blueMigImageView: UIImageView!
    @IBOutlet weak var blueMigTopConst: NSLayoutConstraint!
    
    
    @IBOutlet weak var greenMigImageView: UIImageView!
    @IBOutlet weak var greenMigTopConst: NSLayoutConstraint!
    
    
    @IBOutlet weak var pandaCageImageView: UIImageView!
    @IBOutlet weak var sharkCageImageView: UIImageView!
    @IBOutlet weak var chimpCageImageView: UIImageView!
    
    @IBOutlet weak var helpLabel: UILabel!
    
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var mistakeCount: UILabel!
    
    var openEarsEventsObserver = OEEventsObserver()
    var lmPath: String?
    var dicPath: String?
    
    var sensitiveWords: [String] = ["sh", "ch", "pa"]
    var state: GameState = .red
    
    //    var successCount = 0
    //    let maxSuccessCountLimit = 4
    var problemCount = 0 {
        didSet {
            self.mistakeCount.text = "you made mistake \(self.problemCount) time(s)"
        }
    }
    
    let maxProblemCountLimit = 3
    
    var isAppPermitted = false
    var isSleep =  false
    var isListening = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestSpeechAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.resetGame()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.isSleep = false
        switch state {
        case .red:
            self.redsTurn()
        case .blue:
            self.bluesTurn()
        case .green:
            self.greensTurn()
        }
    }
    
    func redsTurn() {
        self.helpLabel.text = "Migs are standing near their favourite animal to help them"
        
        let time = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.helpLabel.text = "What is Red's favourite animal?"
        })
        
        self.choosePanda()
    }
    
    func bluesTurn() {
        self.helpLabel.text = "What is Blue's favourite animal?"
        self.chooseShark()
    }
    
    func greensTurn() {
        self.helpLabel.text = "What is Green's favourite animal?"
        self.chooseChimp()
    }
    
    func resetGame() {
        self.problemCount = 0
        self.redMigTopConst.constant = 100.0
        self.blueMigTopConst.constant = 100.0
        self.greenMigTopConst.constant = 100.0
        
        self.pandaCageImageView.image = UIImage(named: "img_panda_cage")
        self.sharkCageImageView.image = UIImage(named: "img_shark_cage")
        self.chimpCageImageView.image = UIImage(named: "img_chimp_cage")
    }
    
    func choosePanda() {
        let pandaGesture = UITapGestureRecognizer(target: self, action: #selector(self.pandaIsChosen))
        self.pandaCageImageView.isUserInteractionEnabled = true
        self.pandaCageImageView.addGestureRecognizer(pandaGesture)
        
        self.sharkCageImageView.isUserInteractionEnabled = false
        self.chimpCageImageView.isUserInteractionEnabled = false
    }
    
    func chooseShark() {
        let sharkGesture = UITapGestureRecognizer(target: self, action: #selector(self.sharkIsChosen))
        self.sharkCageImageView.isUserInteractionEnabled = true
        self.sharkCageImageView.addGestureRecognizer(sharkGesture)
        
        self.pandaCageImageView.isUserInteractionEnabled = false
        self.chimpCageImageView.isUserInteractionEnabled = false
    }
    
    func chooseChimp() {
        let chimpGesture = UITapGestureRecognizer(target: self, action: #selector(self.chimpIsChosen))
        self.chimpCageImageView.isUserInteractionEnabled = true
        self.chimpCageImageView.addGestureRecognizer(chimpGesture)
        
        self.pandaCageImageView.isUserInteractionEnabled = false
        self.sharkCageImageView.isUserInteractionEnabled = false
    }
    
    @objc func pandaIsChosen() {
        //        self.sensitiveWords = ["pa"]
        self.setupOpenEars()
        self.helpLabel.text = "Let's help the panda! Say 'pa' 4 times!"
    }
    
    @objc func sharkIsChosen() {
        //        self.sensitiveWords = ["sh"]
        if !self.isListening {
            self.startListening()
        }
        self.helpLabel.text = "Let's help the shark! Say 'sh' 4 times!"
    }
    
    @objc func chimpIsChosen() {
        //        sensitiveWords = ["ch"]
        if !self.isListening {
            self.startListening()
        }
        self.helpLabel.text = "Let's help the chimp! Say 'ch' 4 times!"
    }
    
    //MARK: - Check Authorization Status
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.isAppPermitted = true
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
    
    func setupOpenEars() {
        guard self.isAppPermitted == true else {
            self.requestSpeechAuthorization()
            return
        }
        
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
                self.isListening = true
            } catch {
                print("Error: it wasn't possible to set the shared instance to active: \"\(error)\"")
            }
        }
    }
    
    public func stopListening() {
        guard let listener = OEPocketsphinxController.sharedInstance() else { return }
        listener.suspendRecognition()
        print("stopped")
        self.isListening = false
    }
    
    func stepMigForward(hypothesis: String) {
        if self.state == .red && hypothesis == "pa" {
            self.stepRedMigForward()
        } else if self.state == .blue && hypothesis == "sh" {
            self.stepBlueMigForward()
        } else if self.state == .green && hypothesis == "ch" {
            self.stepGreenMigForward()
        }
    }
    
    func stepRedMigForward() {
        if self.redMigTopConst.constant > 11 {
            self.redMigTopConst.constant -= 30
        } else {
            self.redMigTopConst.constant -= 30
            self.migSucceed()
        }
    }
    
    func stepBlueMigForward() {
        if self.blueMigTopConst.constant > 11 {
            self.blueMigTopConst.constant -= 30
        } else {
            self.blueMigTopConst.constant -= 30
            self.migSucceed()
        }
    }
    
    func stepGreenMigForward() {
        if self.greenMigTopConst.constant > 11 {
            self.greenMigTopConst.constant -= 30
        } else {
            self.greenMigTopConst.constant -= 30
            self.migSucceed()
        }
    }
    
    func setOpenedCageImage() {
        switch state {
        case .red:
            self.pandaCageImageView.image = UIImage(named: "img_panda_released")
        case .blue:
            self.sharkCageImageView.image = UIImage(named: "img_shark_released")
        case .green:
            self.chimpCageImageView.image = UIImage(named: "img_chimp_released")
        }
    }
    
    func migSucceed() {
        guard !isSleep else { return }
        self.setOpenedCageImage()
        self.helpLabel.text = "Yay! you did it!"
        let time = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            // succeed page for a animal
            self.showSavedAnAnimalPage()
        })
        self.isSleep = true
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
    
    func showSavedAnAnimalPage() {
        let savedAnAnimalPage = self.storyboard?.instantiateViewController(withIdentifier: "savedAnAnimalViewController") as! SavedAnAnimalViewController
        savedAnAnimalPage.state = self.state
        self.stopListening()
        self.navigationController?.pushViewController(savedAnAnimalPage, animated: true)
        self.changeState()
    }
    
    func changeState() {
        switch self.state {
        case .red:
            self.state = .blue
        case .blue:
            self.state = .green
        case .green:
            self.state = .red
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension MainGameViewController: OEEventsObserverDelegate {
    func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!) { // Something was heard
        if hypothesis.contains(" ") { return }
        print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")
        
        if sensitiveWords.contains(hypothesis) && ((Int(recognitionScore) ?? -60000) > -60000) {
            self.stepMigForward(hypothesis: hypothesis)
        } else if !sensitiveWords.contains(hypothesis) || ((Int(recognitionScore) ?? -60000) <= -60000) {
            self.setProblemCount()
        }
    }
    
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


enum GameState {
    case red
    case blue
    case green
}
