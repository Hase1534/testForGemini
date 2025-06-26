//
//  QuizViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 2/3/25.
//

import UIKit

var numberOfCorrectAnswer = 0 //正解問題数カウント
var numberOfQuizzes = Int()//問題数
var array01 = [Int]() //1セクションあたりの正誤を暫定で保持しておくための配列
var csvLines01 = [String]()

//前の画面で選択された問題を引き継ぐ用の変数
var selectedSectionName = String()
var selectedQuizName = String()

var quizzesArray01 = [[String]]()

var bookMarkedNumberArray = [String]()

class QuizViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, PopupViewControllerDelegate{
   
    var quizCount: Int = 0
    var csvLines = [String]()
    var quizzesArray = [Any]()
    var viewResultOrNot = false
    var correctAnswerInt = Int() //正解の問題番号を格納しておくための変数
    var bookMarkedNumber = String()
    var bookMarkedOrNot = false
    
    var alertController: UIAlertController!
    
    @IBOutlet weak var quizCountLabel: UILabel!
    @IBOutlet weak var maruBatsuLabel: UILabel!
    @IBOutlet weak var quizTextView: UITextView!
    @IBOutlet weak var nextQuizButtonOutlet: UIButton!
    @IBOutlet weak var previousQuizButtonOutlet: UIButton!
    @IBOutlet weak var tableViewOutlet: UITableView!
    @IBOutlet weak var bookMarkButtonOutlet: UIButton!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
               //
            
    }
    

    
    //次の問題表示
    func nextQuizReload() {
        if quizCount <= numberOfQuizzes - 1{
            //ここでラベルの表示を変更する
            if selectedSectionName == "ブックマークした問題" || selectedSectionName == "ランダム" || selectedSectionName == "間違えた問題"{
                //quizCountLabel.text = "\(selectedQuizName) \(selectedSectionName) 第\(quizCount + 1)問"
                quizCountLabel.text = "\(selectedQuizName) \(quizzesArray01[quizCount][0]) 第\(quizzesArray01[quizCount][2])問"
            }else{
                quizCountLabel.text = "\(selectedQuizName) \(selectedSectionName) 第\(quizCount + 1)問"
            }
            
            let converted: String = quizzesArray01[quizCount][3]
            let fixedConverted = converted.replacingOccurrences(of: "\\n", with: "\n")//ここでエスケープを有効に
            quizTextView.text = fixedConverted
            //print(quizzesArray01[quizCount], "これが表示する問題のarray")//unrap時にエラーが出たらここを確認
            print(quizzesArray01[quizCount][4], "ここが正答数字")
            correctAnswerInt = Int(quizzesArray01[quizCount][4])!
            //ここで問題番号をarrayに保持させる
            //array01.append(Int(quizzesArray01[quizCount][2])!)
            array01.append(Int(quizzesArray01[quizCount][17])!)

            bookMarkedNumber = quizzesArray01[quizCount][17]
            explanationsText = quizzesArray01[quizCount][11]
            //ここに解説入れる
       
            //ブクマボタンの表示変更(遷移してきて最初の部分
            if bookMarkedNumberArray.contains(quizzesArray01[quizCount][17]){
                bookMarkButtonOutlet.setTitle("ブクマ済", for: .normal)
                bookMarkedOrNot = true
            }else{
                bookMarkButtonOutlet.setTitle("ブクマ", for: .normal)
                bookMarkedOrNot = false
            }
        }else{
            print("問題終了")
        }
        
        if poppedUpOrNot == true{
            //解答しないと次に進めないように
            nextQuizButtonOutlet.isUserInteractionEnabled = true
            nextQuizButtonOutlet.alpha = 1.0
        }else{
            //解答しないと次に進めないように
            nextQuizButtonOutlet.isUserInteractionEnabled = false
            nextQuizButtonOutlet.alpha = 0.5
        }
      
        
    }
    
    //ボタンの表示切り替え
    func buttonlabelChange() {
        if quizCount == 0 && numberOfQuizzes != 1{
            previousQuizButtonOutlet.isUserInteractionEnabled = false
            previousQuizButtonOutlet.alpha = 0.0
        }else if quizCount == 0 && numberOfQuizzes == 1{
            //ここでブクマ問題が1問のみの場合を想定
            previousQuizButtonOutlet.isUserInteractionEnabled = false
            previousQuizButtonOutlet.alpha = 0.0
            //結果を見れるように
            nextQuizButtonOutlet.setTitle("終了", for: .normal)
            viewResultOrNot = true
        }else if quizCount < numberOfQuizzes - 1{
            previousQuizButtonOutlet.isUserInteractionEnabled = true
            previousQuizButtonOutlet.alpha = 1.0
        }else{
            nextQuizButtonOutlet.setTitle("終了", for: .normal)
            viewResultOrNot = true
        }
        maruBatsuLabel.text = ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        let backButton = UIBarButtonItem(title: self.navigationController?.viewControllers.dropLast().last?.navigationItem.title ?? "Back", style: .plain, target: self, action: #selector(confirmBack))//ここのtitle表示は改善の余地あり

           let backImage = UIImage(systemName: "chevron.left")
           backButton.image = backImage
           backButton.tintColor = .systemBlue // 必要に応じて色変更

           self.navigationItem.leftBarButtonItem = backButton
        
        
        if bookMarkedNumberArray != []{
            bookMarkedNumberArray = (UserDefaults.standard.array(forKey: "bookMarkedNumberArrayKey") as? [String])!
        }
        
        quizTextView.isEditable = false
        quizTextView.isScrollEnabled = true
        //読み込んだ時に暫定で結果を持っておく配列も初期化
        array01 = []
        
        //ボタンの表示
        nextQuizButtonOutlet.setTitle("次の問題へ", for: .normal)
        previousQuizButtonOutlet.setTitle("前の問題へ(工事中)", for: .normal)

        guard let path = Bundle.main.path(forResource:"quiz3", ofType:"csv") else {
            print("csv does not exist")
                return
        }
        do {
            let csvString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            csvLines = csvString.components(separatedBy: .newlines)
            csvLines.removeLast()
        } catch let error as NSError {
            print("エラー: \(error)")
            return
        }
        
        for quizData in csvLines01 {
            let singleQuizArray = quizData.components(separatedBy: ",")
            if singleQuizArray != [""]{
            quizzesArray.append(singleQuizArray)
            }
        }
        buttonlabelChange()
        nextQuizReload()
    }//end viewDidLoad
    
    @objc func confirmBack() {
        let alert = UIAlertController(title: "確認", message: "本当に前の画面に戻ってもよろしいですか？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
        //ここは暫定で5択としているが、将来的に可変にする必要あり
    }
    
    var stringArray02 = [String]()//これは正しい選択肢だけを抽出する配列
    var stringArray = [String]()
    var randomItems: [String] = []
    var shuffleOrNot = true
    
    func shuffleArray() {
        if quizCount <= numberOfQuizzes - 1{
            stringArray = quizzesArray01[quizCount]

            stringArray02 = Array(stringArray[5...9])//ここは元8まで(4択)
                    
            // itemsをシャッフルしてrandomItemsに格納
            randomItems = stringArray02.shuffled()
            shuffleOrNot = false
        }else{
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if quizCount <= numberOfQuizzes - 1{
            if shuffleOrNot == true{
                shuffleArray()//
            }
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "quizCell", for: indexPath)
            //cell.textLabel!.text = stringArray[indexPath.row + 5]
            cell.textLabel!.text = randomItems[indexPath.row]
            return cell
        }else{
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "quizCell", for: indexPath)
            cell.textLabel!.text = ""
            return cell
        }
    }
    
    func didTapActionButton() {
           quizCount += 1
           nextQuizReload()
           tableViewOutlet.reloadData()

           if viewResultOrNot == true {
               let nextView = storyboard?.instantiateViewController(withIdentifier: "ResultViewController01") as! ResultViewController01
               nextView.modalTransitionStyle = .crossDissolve
               nextView.modalPresentationStyle = .fullScreen
               self.present(nextView, animated: true, completion: nil)
           }

           buttonlabelChange()
           tableViewOutlet.isUserInteractionEnabled = true

           shuffleOrNot = true
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let correctAnswerNumber = Int(stringArray[4]) ?? 100//抜けなかったら100を返す
        let corretAnswer = stringArray[correctAnswerNumber + 4]
   
        if randomItems[indexPath.row] == corretAnswer {
            maruBatsuLabel.text = "まる"
            numberOfCorrectAnswer += 1
            tableViewOutlet.isUserInteractionEnabled = false
            array01.append(-1)
            //array01.append(Int(stringArray[17])!)
            //暫定で問題に解答しないと進めないように
            maruOrBatsuBool = true
            nextQuizButtonOutlet.isUserInteractionEnabled = true
            nextQuizButtonOutlet.alpha = 1.0
            
            let nextView = storyboard?.instantiateViewController(withIdentifier: "PopupViewController") as! PopupViewController
            nextView.modalTransitionStyle = .crossDissolve
            nextView.modalPresentationStyle = .overFullScreen  // ← 前の画面が見えるように
            nextView.delegate = self  // ← デリゲート設定
            self.present(nextView, animated: true, completion: nil)
            
        }else{
            maruBatsuLabel.text = "ばつ"
            tableViewOutlet.isUserInteractionEnabled = false
            array01.append(-2)
            maruOrBatsuBool = false
            //暫定で問題に解答しないと進めないように
            nextQuizButtonOutlet.isUserInteractionEnabled = true
            nextQuizButtonOutlet.alpha = 1.0
            
            let nextView = storyboard?.instantiateViewController(withIdentifier: "PopupViewController") as! PopupViewController
            nextView.modalTransitionStyle = .crossDissolve
            nextView.modalPresentationStyle = .overFullScreen  // ← 前の画面が見えるように
            nextView.delegate = self  // ← デリゲート設定
            self.present(nextView, animated: true, completion: nil)
            
        }
     }
    
    
    @IBAction func nextQuizButton(_ sender: Any) {
        quizCount += 1
        nextQuizReload()
        tableViewOutlet.reloadData()
        
        if viewResultOrNot == true{
            let nextView = storyboard?.instantiateViewController(withIdentifier: "ResultViewController01") as! ResultViewController01
            nextView.modalTransitionStyle = .crossDissolve
            nextView.modalPresentationStyle = .fullScreen
            self.present(nextView, animated: true, completion: nil)
        }
        buttonlabelChange()
        tableViewOutlet.isUserInteractionEnabled = true
        
        shuffleOrNot = true
        
    }
    
    @IBAction func previousQuizButton(_ sender: Any) {
        if quizCount >= 1{
            quizCount -= 1
            nextQuizReload()
            tableViewOutlet.reloadData()
            buttonlabelChange()
        }else{
            print("最初の問題")
        }
    }
    
    @IBAction func bookMarkButton(_ sender: Any) {
        if bookMarkedOrNot == false{
            //ブクマされてない時の挙動
            bookMarkedNumberArray.append(bookMarkedNumber)
            UserDefaults.standard.set(bookMarkedNumberArray, forKey: "bookMarkedNumberArrayKey")
            bookMarkButtonOutlet.setTitle("ブクマ済", for: .normal)
            bookMarkedOrNot = true
        }else{
            //ブクマされてる時の挙動
            bookMarkedNumberArray = bookMarkedNumberArray.filter { $0 != bookMarkedNumber }//番号削除
            UserDefaults.standard.set(bookMarkedNumberArray, forKey: "bookMarkedNumberArrayKey")
            bookMarkButtonOutlet.setTitle("ブクマ", for: .normal)
            bookMarkedOrNot = false
        }
    }
    
    
    @IBAction func checkAnswerButton(_ sender: Any) {
        answerCheckButtonPushed = true
        let correctAnswerNumber = Int(stringArray[4]) ?? 100//抜けなかったら100を返す
        let corretAnswer = stringArray[correctAnswerNumber + 4]
        choosedSentakushi = corretAnswer//次viewに正解選択肢を表示
        explanationsText = stringArray[11]//次viewに解説を表示
        
        let nextView = storyboard?.instantiateViewController(withIdentifier: "PopupViewController") as! PopupViewController
        nextView.modalTransitionStyle = .crossDissolve
        nextView.modalPresentationStyle = .fullScreen
        self.present(nextView, animated: true, completion: nil)
        
        
    }
    
    
}
