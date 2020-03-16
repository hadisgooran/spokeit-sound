//
//  SavedAnAnimalViewController.swift
//  SpeechRecognition
//
//  Created by hadis on 10/19/1398 AP.
//  Copyright © 1398 hadis. All rights reserved.
//

import UIKit

class SavedAnAnimalViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var helpLabel: UILabel!
    
    var state: GameState?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showSavedAnimalImage()
        self.setupHandle()
    }
    
    func showSavedAnimalImage() {
        guard let savedAnimal = self.state else {
            return
        }
        
        switch savedAnimal {
        case .red:
            self.imageView.image = UIImage(named: "img_panda_success")
            self.helpLabel.text = "You helped the panda"
        case .blue:
            self.imageView.image = UIImage(named: "img_shark_success")
            self.helpLabel.text = "You helped the shark"
        case .green:
            self.imageView.image = UIImage(named: "img_chimp_success")
            self.helpLabel.text = "You helped the chimp"
        }
    }
    
    func setupHandle() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        self.imageView.addGestureRecognizer(tapRecognizer)
        self.imageView.isUserInteractionEnabled = true
    }
    
    @objc func imageTapped() {
        if self.state ?? .red == .green {
            let savedAllViewController = self.storyboard?.instantiateViewController(withIdentifier: "savedAllAnimalsViewController") as! SavedAllAnimalsViewController
            self.navigationController?.pushViewController(savedAllViewController, animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
