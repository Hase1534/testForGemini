//
//  PickerViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 3/21/25.
//

import UIKit

class PickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
   
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    override func viewDidLoad() {
        print("この画面は読み込まれている")
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        // Do any additional setup after loading the view.
       
        pickerView.selectRow(numberOfSelectedQuiz - 1, inComponent: 0, animated: false)
        // Do any additional setup after loading the view.
        //pickerView.isHidden = true
        
        //ここからUD
        if let savedValue = UserDefaults.standard.object(forKey: "numberOfSelectedQuizKey") as? Int {
            numberOfSelectedQuiz = savedValue
        } else {
            numberOfSelectedQuiz = 10// 初回起動時のデフォルト値
        }
        
    }//end viewDidLoad
    

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        numberOfSelectedQuiz = row + 1
        UserDefaults.standard.set(numberOfSelectedQuiz, forKey: "numberOfSelectedQuizKey")
        print("選択された数: \(numberOfSelectedQuiz)") // デバッグ用
        
        
    }
    
    
    @IBAction func finishButton(_ sender: Any) {
        
        //self.dismiss(animated: true, completion: nil)
//
//        let nextView = storyboard?.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
//        
//        nextView.modalTransitionStyle = .crossDissolve
//        nextView.modalPresentationStyle = .fullScreen
//        self.present(nextView, animated: true, completion: nil)
    }
    
    
    
}
