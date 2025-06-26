//
//  ResultViewController01.swift
//  certificationExamPrototype03
//
//  Created by TERU on 2/3/25.
//

import UIKit

var dateStringArray = [String]()


class ResultViewController01: UIViewController {

    @IBOutlet weak var resultLable01: UILabel!
    @IBOutlet weak var resultLabel02: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let savedArray = UserDefaults.standard.stringArray(forKey: "dateStringArrayKey") {
            dateStringArray = savedArray
            print("Loaded dateStringArray: \(dateStringArray)")
        } else {
            print("No saved data found for dateStringArrayKey")
        }
        //resultLable01.text = "\(numberOfQuizzes)問中\(numberOfCorrectAnswer) 問正解"
        resultLable01.text = "\(array01.count / 2)問中\(array01.filter{$0 == -1}.count)問正解"
        // Do any additional setup after loading the view.
        resultLabel02.text = "\( Int(floor((Float(array01.filter{$0 == -1}.count) / Float(array01.count / 2)) * 100 )))%正解"
    }
    

    @IBAction func returnToHomeButton(_ sender: Any) {
        print(array01, "今の回答状況")
        statusArray.append(array01)
        UserDefaults.standard.set(statusArray, forKey: "statusArrayKey")

        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
//        // ロケール設定（端末の暦設定に引きづられないようにする）
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        // タイムゾーン設定（端末設定によらず固定にしたい場合）
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        // 変換
        let str = dateFormatter.string(from: Date())

        dateStringArray.append(str)
        print(dateStringArray, "dateStringArray")
        UserDefaults.standard.set(dateStringArray, forKey: "dateStringArrayKey")

        
        //戻った時にBarButtonを表示
        func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.hidesBottomBarWhenPushed = false
            print("あああ")
        }
        
//        let nextView = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
//        nextView.modalTransitionStyle = .crossDissolve
//        nextView.modalPresentationStyle = .fullScreen
//        self.present(nextView, animated: true, completion: nil)
        
    }
    
}
