//
//  PopupViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 3/4/25.
//

import UIKit

var explanationsText = String()
var choosedSentakushi = String()
var maruOrBatsuBool = Bool()
var poppedUpOrNot = Bool()
var answerCheckButtonPushed = false


protocol PopupViewControllerDelegate: AnyObject {
    func didTapActionButton()
}


class PopupViewController: UIViewController {

    @IBOutlet weak var closeButtonOutlet: UIButton!
    
    @IBOutlet weak var explanationsTextView: UITextView!
    
    @IBOutlet weak var maruBatsuImageView: UIImageView!
    
    @IBOutlet weak var sentakushiTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        explanationsTextView.text = explanationsText
        closeButtonOutlet.setTitle("戻る", for: .normal)
        
        //explanationsTextView.text = explanationsText
        //↑CSVに解説が入ったらこっちを使うこと！！！
        explanationsTextView.text = "解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説解説"

        
        sentakushiTextView.text = "正解: \(choosedSentakushi)"
        
        if answerCheckButtonPushed == false{
            if maruOrBatsuBool == true{
                maruBatsuImageView.image = UIImage(named: "maruImage")
            }else{
                maruBatsuImageView.image = UIImage(named: "batsuImage")
            }
        }
        poppedUpOrNot = true//これ要確認
        
    }//end viewDidLoad
    
    weak var delegate: PopupViewControllerDelegate?
    
    @IBAction func closeButton(_ sender: Any) {
//        let nextView = storyboard?.instantiateViewController(withIdentifier: "QuizViewController") as! QuizViewController
//        nextView.modalTransitionStyle = .crossDissolve
//        nextView.modalPresentationStyle = .fullScreen
//        self.present(nextView, animated: true, completion: nil)
        
        dismiss(animated: true, completion: nil)
        //ここの時の遷移前のtableViewの表示等々は改善の余地あり
        
    }
    
    
    @IBAction func nextQuizButton(_ sender: Any) {
        delegate?.didTapActionButton()  // ← 親に通知
            self.dismiss(animated: true, completion: nil)  // ← ポップアップ閉じる
        
    }
    
   

}
