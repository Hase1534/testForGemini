//
//  SettingProfileViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 4/10/25.
//

import UIKit


var userName = "User"

class SettingProfileViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userNameTextField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
        
        if let savedUserName = UserDefaults.standard.string(forKey: "userNameKey") {
            print("userNameは読み込まれている: \(savedUserName)")
            userName = savedUserName
        } else {
            print("userNameは読み込まれていない")
        }
        
        userNameLabel.text = "あなたの名前：　\(userName)"
        // Do any additional setup after loading the view.
    }
    

    @IBAction func doneInputButton(_ sender: Any) {
        userName = userNameTextField.text ?? ""
        userNameLabel.text = "あなたの名前：　\(userName)"
        UserDefaults.standard.set(userName, forKey: "userNameKey")

        
    }
    
    
}
