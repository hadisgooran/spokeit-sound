//
//  Extensions.swift
//  SpeechRecognition
//
//  Created by hadis on 6/29/1398 AP.
//  Copyright © 1398 hadis. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            
            // Don't touch the masksToBound property if a shadow is needed in addition to the cornerRadius
            if layer.shadowOpacity <= 0.0 {
                self.layer.masksToBounds = true
            }
        }
    }
    
    func fadeIn(withDuration duration: TimeInterval = 0.1) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    func fadeOut(withDuration duration: TimeInterval = 0.2) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
}

extension UIViewController {
    
    func sendAlert(message: String, alertAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
            alertAction?()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
