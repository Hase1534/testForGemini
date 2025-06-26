//
//  ViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 2/3/25.
//

import UIKit
import DGCharts
import Foundation
import GoogleGenerativeAI
import GoogleMobileAds

var statusArray: [[Int]] = [[]]

var sectionsName01 = [String]()
var sectionsName = [String]()
var sectionsContents = [String]()
var sectionsContents01 = [String]()

class ViewController: UIViewController {
    
    

    @IBOutlet weak var tabBar: UITabBar!
    
    @IBOutlet weak var chartView: LineChartView!
    var lineDataSet: LineChartDataSet!
    // 折れ線グラフで表示するデータ(Y軸)
    private let data: [Double] = [100.0, 65.0, 90.0, 30.0, 45.0]
    
    //ボタンのoutlet接続
    @IBOutlet weak var moveToKakomonButtonOutlet: UIButton!
    @IBOutlet weak var moveTokoumokuButtonOutlet: UIButton!
    @IBOutlet weak var moveToMachigaiButtonOutlet: UIButton!
    @IBOutlet weak var moveToBookmarkButtonOutlet: UIButton!
    
    
    @IBOutlet weak var adContainerView: UIView!
    
    //広告仮置き用のラベル(広告Viewに置換予定)
    //@IBOutlet weak var adLabel01: UILabel!
    @IBOutlet weak var homeAITextView: UITextView!
    
    //最初の起動時だけCSVを読むための識別変数
    let defaults = UserDefaults.standard
    var firstTimeOrNot = true
    
    var csvLines = [String]()
    var quizzesArray = [[String]]()
    var alertController = UIAlertController()
    
    // --- プロパティ ---
    // (既存のモデル)
    let generativeModel = GenerativeModel(
        name: "gemini-2.0-flash",
        apiKey: APIKey.default
    )
    

    var bannerView: BannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // BannerViewインスタンス作成
        bannerView = BannerView(adSize: AdSizeBanner)
        // BannerViewインスタンス作成
        bannerView = BannerView(adSize: AdSizeBanner)

                // 自分のバナー広告ユニットIDに書き換えてね！
                bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111"  // ←バナーID

                // ルートViewControllerを設定
                bannerView.rootViewController = self

        // UIViewにバナー広告を追加
              bannerView.translatesAutoresizingMaskIntoConstraints = false
              adContainerView.addSubview(bannerView)

                // 広告リクエストを作成してロード
        let request = Request()
        bannerView.load(request)
        
        
        
        
        
        
        //ユーザーネームのUD
        if let savedUserName = UserDefaults.standard.string(forKey: "userNameKey") {
            print("userNameは読み込まれている: \(savedUserName)")
            userName = savedUserName
        } else {
            print("userNameは読み込まれていない")
        }
        
        
        // --- 挨拶とダジャレ表示設定 (非同期処理を開始) ---
        setupHomeAITextView()

        //広告仮置きラベルの設定
//        adLabel01.text = "🤑ぱーぱす枠🤑"
//        adLabel01.backgroundColor = UIColor.systemPink
        
        //ボタンの各種設定
        moveToKakomonButtonOutlet.layer.borderColor = UIColor.black.withAlphaComponent(0.7).cgColor
        moveToKakomonButtonOutlet.layer.borderWidth = 1.0
        moveToKakomonButtonOutlet.layer.cornerRadius = 7.0
        moveToKakomonButtonOutlet.titleLabel?.textColor = UIColor.black
        moveToKakomonButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 24)

        moveTokoumokuButtonOutlet.layer.borderColor = UIColor.black.withAlphaComponent(0.7).cgColor
        moveTokoumokuButtonOutlet.layer.borderWidth = 1.0
        moveTokoumokuButtonOutlet.layer.cornerRadius = 7.0
        moveTokoumokuButtonOutlet.titleLabel?.textColor = UIColor.black
        moveTokoumokuButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        
        
        moveToMachigaiButtonOutlet.layer.borderColor = UIColor.black.withAlphaComponent(0.7).cgColor
        moveToMachigaiButtonOutlet.layer.borderWidth = 1.0
        moveToMachigaiButtonOutlet.layer.cornerRadius = 7.0
        moveToMachigaiButtonOutlet.titleLabel?.textColor = UIColor.black
        moveToMachigaiButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        
        moveToBookmarkButtonOutlet.layer.borderColor = UIColor.black.withAlphaComponent(0.7).cgColor
        moveToBookmarkButtonOutlet.layer.borderWidth = 1.0
        moveToBookmarkButtonOutlet.layer.cornerRadius = 7.0
        moveToBookmarkButtonOutlet.titleLabel?.textColor = UIColor.black
        moveToBookmarkButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 17)
    
        
        if let savedValue = defaults.object(forKey: "firstTimeOrNotKey") as? Bool {
            firstTimeOrNot = savedValue
        } else {
            firstTimeOrNot = true // 初回起動時のデフォルト値
        }

        if firstTimeOrNot == true || firstTimeOrNot == false{
            //ここは後で変えておく
            csvLines = [String]()
            quizzesArray = [[String]]()
            //ここからCSV読み込み
            guard let path = Bundle.main.path(forResource:"quiz3", ofType:"csv") else {
                print("csv does not exist")
                    return
            }
            
            do {
                let csvString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
                csvLines = csvString.components(separatedBy: .newlines)
                csvLines.removeLast()
                csvLines01 = csvString.components(separatedBy: .newlines)
                csvLines01.removeLast()
                
            } catch let error as NSError {
                print("エラー: \(error)")
                return
            }
            
            for quizData in csvLines {
                let singleQuizArray = quizData.components(separatedBy: ",")
                if singleQuizArray != [""]{
                quizzesArray.append(singleQuizArray)
                }
            }
         
            firstTimeOrNot = false
            defaults.set(firstTimeOrNot, forKey: "firstTimeOrNotKey")
            if let encodedData = try? JSONEncoder().encode(quizzesArray) {
                defaults.set(encodedData, forKey: "quizzesArrayKey")
                print("quizzesArrayは保存された")
            }
            
            //ここから科目名をUDに保存
            var seenSubjects: Set<String> = []
            for quiz in quizzesArray {
                let subject = quiz[0]
                if !seenSubjects.contains(subject) {
                    nameOfSubjectsArray.append(subject)
                    seenSubjects.insert(subject)
                }
            }
            print(nameOfSubjectsArray)
            defaults.set(nameOfSubjectsArray, forKey: "nameOfSubjectsArrayKey")
            
            
            
        }else{//以下2回目以降の起動時
            if let savedData = defaults.data(forKey: "quizzesArrayKey"),
               let decodedArray = try? JSONDecoder().decode([[String]].self, from: savedData) {
                quizzesArray = decodedArray
                print("quizzesArrayは読み込まれている")
            } else {
                print("quizzesArrayは読み込まれていない")
            }
        
            //ここに科目名呼び出しコード書く
            if let savedData01 = defaults.stringArray(forKey: "nameOfSubjectsArrayKey") {
                nameOfSubjectsArray = savedData01
            }else{
                print("科目名読み出せず")
            }
            
        }
  
        statusArray = (defaults.array(forKey: "statusArrayKey") ?? [[]]) as [[Int]]
        if dateStringArray != [String](){
            dateStringArray = (defaults.array(forKey: "dateStringArrayKey") as? [String])!
        }
        
        //drawChart(y: data)
        //ここOnにしないとチャート非表示
        extractSectionName(from: quizzesArray)
    }//end ViewDidLoad
    
    // --- 挨拶とダジャレを homeAITextView に設定するメソッド (Gemini呼び出し含む) ---
    func setupHomeAITextView() {
        // homeAITextViewの初期設定 (編集不可など)
        homeAITextView.isEditable = false
        homeAITextView.font = UIFont.systemFont(ofSize: 16) // フォント例

        let greeting = getTimeBasedGreeting() // 時間帯挨拶を取得

        // ステップ1: まずプレースホルダーを表示
        homeAITextView.text = """
        \(greeting)、\(userName)さん。
        今日はいい天気だね。


        考え中...🤔
        """

        // ステップ2: 非同期でGeminiにダジャレを問い合わせる
        Task { // 非同期処理を開始
            do {
                // Geminiからダジャレを取得
                let pun = try await fetchPunFromGemini()

                // ★ 成功：取得したダジャレを使ってTextViewを更新 (メインスレッドで)
                DispatchQueue.main.async {
                    self.homeAITextView.text = """
                    \(greeting)、\(userName)さん。
                    今日はいい天気だね。


                    「\(pun)」
                    """
                }
            } catch {
                // ★ 失敗：エラーメッセージまたは代替テキストを表示 (メインスレッドで)
                print("ダジャレ取得エラー: \(error)")
                DispatchQueue.main.async {
                     // エラー発生時も挨拶は表示する
                     self.homeAITextView.text = """
                    \(greeting)、\(userName)さん。
                    今日はいい天気だね。

                    そうだ、面白いダジャレを思いついたけど...忘れちゃったみたい。
                    """
                }
            }
        }
    }

    // --- Geminiにダジャレ生成を指示し、結果を返す非同期メソッド ---
    func fetchPunFromGemini() async throws -> String {
        // --- Geminiへの指示 (プロンプト) ---
        let prompt = """
        あなたは豆しばです
        豆知識を一つ披露して日本語で出力して
        """

        print("Geminiにダジャレを問い合わせ中...") // デバッグ用

        // API呼び出し
        let response = try await generativeModel.generateContent(prompt)

        // レスポンスからテキスト部分を取得して返す
        guard let punText = response.text, !punText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "PunFetcherError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Geminiからの応答が空でした。"])
        }

        print("取得したダジャレ: \(punText)") // デバッグ用
        return punText.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // --- 時間に基づいた挨拶を返すヘルパーメソッド ---
    func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        // 現在時刻 2025年4月10日 17:43:50 JST
        switch hour {
        case 5..<12: return "おはよう" // 5:00-11:59
        case 12..<18: return "こんにちは" // 12:00-17:59 (現在の時間 17:43 はここに該当)
        case 18..<24, 0..<5: return "こんばんは" // 18:00-4:59
        default: return "こんにちは"
        }
        // 現在時刻(17:43 JST)に基づくと、"こんにちは"が返されます。
    }
    
    //ブクマアラート用関数
    func alert(title:String, message:String) {
       alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
       alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
       present(alertController, animated: true)
    }
    
    //ブクマ0ならアラート鳴らす関数
    func loadValueFromUserDefaults() {
        bookMarkedNumberArray = (UserDefaults.standard.array(forKey: "bookMarkedNumberArrayKey") as? [String] ?? [])
        if bookMarkedNumberArray.count == 0{
            alert(title: "ブックマークされた問題がありません",message: "")
        } else {
        }
    }
    
    //ブクマ検索用の関数
    func filter2DArray<T: Equatable>(array2D: [[T]], filterArray: [T]) -> [[T]] {
        return array2D.filter { subArray in
            subArray.contains { filterArray.contains($0) }
        }
    }
    
    func extractSectionName(from array: [[String]]) {
        for subArray in array {
            sectionsName01.append(subArray[0])
            sectionsContents01.append(subArray[1])
        }
        sectionsName = Array(Set(sectionsName01))
        sectionsContents = Array(Set(sectionsContents01))
    }
//
//    func drawChart(y: [Double]) {
//                
//            chartView.center = self.view.center
//            
//            // チャートに渡す用の配列を定義
//            var dataEntries: [ChartDataEntry] = []
//            
//            // Y軸のデータリストからインデックスと値を取得し配列に格納
//            for (index, value) in y.enumerated() {
//                // X軸は配列のインデックス番号
//                let dataEntry = ChartDataEntry(x: Double(index), y: value)
//                dataEntries.append(dataEntry)
//            }
//
//            // 折れ線グラフ用のデータセット labelはグラフ名
//            lineDataSet = LineChartDataSet(entries: dataEntries, label: "グラフ名")
//            // グラフに反映
//            chartView.data = LineChartData(dataSet: lineDataSet)
//            
//            // x軸のラベルをbottomに表示
//            chartView.xAxis.labelPosition = .bottom
//            // x軸のラベル数をデータの数にする
//            chartView.xAxis.labelCount = dataEntries.count - 1
//
//    }
    
    
    @IBAction func moveToKakomonButton(_ sender: Any) {
        KakomonOrKoumoku = 1
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "SelectQuizViewController") as? SelectQuizViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }

    }
    
    
    @IBAction func moveTokoumokuButton(_ sender: Any) {
        KakomonOrKoumoku = 2
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "SelectQuizViewController") as? SelectQuizViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    @IBAction func moveToMachigaiButton(_ sender: Any) {
        if let savedStatusArray = UserDefaults.standard.array(forKey: "statusArrayKey") as? [[Int]] {
            statusArray = savedStatusArray
        } else {
            print("No data found for key 'statusArrayKey'")
        }
        
        statusArray.removeAll(where: { (value) in // removeAllメソッドの引数whereにクロージャを指定することで、条件に一致する要素を削除する
            value == []
        })
        
        // 各問題番号ごとの最後の正誤を記録する辞書
        var lastResultForQuiz: [Int: Int] = [:]

        for subArray in statusArray {
            for i in stride(from: 0, to: subArray.count, by: 2) {
                let quizNumber = subArray[i]         // 問題番号
                let quizResult = subArray[i + 1]     // 正誤
                lastResultForQuiz[quizNumber] = quizResult
            }
        }
        
        UserDefaults.standard.set(missedQuizNumberArray, forKey: "missedQuizNumberArrayKey")
        
        for (quizNumber, result) in lastResultForQuiz {
            if result == -2 {
                missedQuizNumberSet.insert(quizNumber)
            }
        }
        missedQuizNumberArray = Array(missedQuizNumberSet)
        
        quizzesArray01.removeAll()
        
        for quiz in quizzesArray {
            if let quizNumber = Int(quiz[17]), missedQuizNumberArray.contains(quizNumber) {
                quizzesArray01.append(quiz) // 一致した一次元配列を追加
            }
        }

        numberOfQuizzes = quizzesArray01.count//次のViewCOntrollerに問題数を渡す処理
        missedQuizNumberSet.removeAll()//ここで一旦間違えた配列を初期化
        
        selectedSectionName = "間違えた問題"
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    
    @IBAction func moveToBookmarkButton(_ sender: Any) {
        loadValueFromUserDefaults()
            if let bookMarkedNumberArray = UserDefaults.standard.array(forKey: "bookMarkedNumberArrayKey") as? [String] {
                let filteredSubarrays = filter2DArray(array2D: quizzesArray, filterArray: bookMarkedNumberArray)
                quizzesArray01 = filteredSubarrays
                numberOfQuizzes = filteredSubarrays.count//次のViewCOntrollerに問題数を渡す処理
            }else{
                print("データがありません")
            }
        selectedSectionName = "ブックマークした問題"

        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    
}//end class


//コードによる画面遷移
//        let nextView = storyboard?.instantiateViewController(withIdentifier: "SelectQuizViewController") as! SelectQuizViewController
//        nextView.modalTransitionStyle = .crossDissolve
//        nextView.modalPresentationStyle = .fullScreen
//        self.present(nextView, animated: true, completion: nil)
