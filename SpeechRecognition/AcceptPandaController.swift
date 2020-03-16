//
//  AcceptPandaController.swift
//  SpeechRecognition
//
//  Created by hadis on 9/7/1398 AP.
//  Copyright © 1398 hadis. All rights reserved.
//

import Foundation

class AcceptPandaController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func accept(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
}
