//
//  StatusViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 2/3/25.
//

import UIKit
import Charts
import DGCharts
import GoogleGenerativeAI

var missedQuizNumberSet: Set<Int> = []
var missedQuizNumberArray = [Int]()

class StatusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    
    @IBOutlet weak var AIAdviceTextView: UITextView!
    
    @IBOutlet weak var onesanImageView: UIImageView!
    
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // --- Geminiモデルのインスタンスを準備 ---
    let generativeModel = GenerativeModel(
       name: "gemini-2.0-flash", // ★ モデル名
       apiKey: APIKey.default // APIKey.swift からキーを読み込む
    )

    
    let subjectRanges: [(range: ClosedRange<Int>, name: String)] = [
        (10001...10010, "教育原理"),
        (10011...10030, "子どもの食と栄養"),
        (10031...10050, "子どもの保健"),
        (10051...10070, "子ども家庭福祉"),
        (10071...10080, "社会的養護"),
        (10081...10100, "社会福祉"),
        (10101...10120, "保育の心理学"),
        (10121...10140, "保育原理"),
        (10141...10160, "保育実習理論")
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ここに処理を書く
        onesanImageView.image = UIImage(named: "onesanImage")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AIAdviceTextView.delegate = self
        if let savedStatusArray = UserDefaults.standard.array(forKey: "statusArrayKey") as? [[Int]] {
            statusArray = savedStatusArray
        } else {
            // 保存されていない場合
            print("No data found for key 'statusArrayKey'")
        }
        
        // ローディングインジケーターの設定
        if let indicator = activityIndicator {
            indicator.hidesWhenStopped = true
            indicator.stopAnimating()
        }
        
        // AI分析結果表示用のTextViewの初期設定
        AIAdviceTextView.isEditable = false
        AIAdviceTextView.text = "解答履歴を分析中..." // 初期メッセージ
        AIAdviceTextView.font = UIFont.systemFont(ofSize: 16) // 見やすいようにフォント設定例

        // --- 解答履歴の分析とコメント生成を非同期で実行 ---
        Task {
            do {
                // 1. statusArrayから科目ごとの統計情報を計算
                let analysisResult = analyzeQuizHistory(history: statusArray, ranges: subjectRanges)
                // 2. 統計情報を基にGeminiに分析コメント生成を依頼
                let analysisComment = try await fetchAnalysisCommentFromGemini(result: analysisResult, userName: userName)
                // 3. 結果をTextViewに表示 (UI更新はメインスレッドで)
                DispatchQueue.main.async {
                    print(analysisComment)
                    self.AIAdviceTextView.text = analysisComment
                }
            } catch {
                // エラーハンドリング
                print("分析またはコメント生成でエラーが発生しました: \(error)")
                DispatchQueue.main.async {
                    self.AIAdviceTextView.text = "分析中にエラーが発生しました。\n詳細: \(error.localizedDescription)"
                }
            }
        }
        
        
        statusArray.removeAll(where: { (value) in // removeAllメソッドの引数whereにクロージャを指定することで、条件に一致する要素を削除する
            value == []
        })
        
        if let dateStringArray01 = UserDefaults.standard.array(forKey: "dateStringArrayKey") as? [String] {
            dateStringArray = dateStringArray01
        } else {
            print("保存されたデータが見つかりませんでした。")
        }
        
        loadArray()
  
        //以下間違えた問題の番号のみを抽出するコード
        //[]を削除
        statusArray = statusArray.filter { !$0.isEmpty }
        // 各問題番号ごとの最後の正誤を記録する辞書
        var lastResultForQuiz: [Int: Int] = [:]

        for subArray in statusArray {
            for i in stride(from: 0, to: subArray.count, by: 2) {
                let quizNumber = subArray[i]         // 問題番号
                let quizResult = subArray[i + 1]     // 正誤

                // 最後の結果を記録（重複を防ぐため、最後の結果だけを保持）
                lastResultForQuiz[quizNumber] = quizResult
            }
        }

        // 最後に間違えた問題番号をSetに追加（Setを使うことで重複を防ぐ）
        for (quizNumber, result) in lastResultForQuiz {
            if result == -2 {
                missedQuizNumberSet.insert(quizNumber)
            }
        }

        // Setを配列に変換
        missedQuizNumberArray = Array(missedQuizNumberSet)
        UserDefaults.standard.set(missedQuizNumberArray, forKey: "missedQuizNumberArrayKey")

     
        
    }//end viewDidLoad
    
    
    // --- データ構造の定義 ---
       // 各セッションにおける科目ごとの統計情報 (正解数, 不正解数, 合計解答数)
       typealias SessionSubjectStats = [String: (correct: Int, incorrect: Int, total: Int)]
       // 全セッションの統計情報 (セッションごとの統計情報の配列)
       typealias AnalysisResult = [SessionSubjectStats]

       // --- 解答履歴を分析し、セッションごと・科目ごとの統計情報を計算する関数 ---
       func analyzeQuizHistory(history: [[Int]], ranges: [(range: ClosedRange<Int>, name: String)]) -> AnalysisResult {
           var allSessionsResults: AnalysisResult = [] // 全セッションの結果を格納する配列

           // セッションごとにループ (historyの各内側配列を処理)
           for sessionData in history {
               var currentSessionStats: SessionSubjectStats = [:] // 現在のセッションの統計情報

               // まず、すべての科目を0で初期化しておく
               for (_, subjectName) in ranges {
                   currentSessionStats[subjectName] = (correct: 0, incorrect: 0, total: 0)
               }

               // セッションデータ ([問題番号, 結果, 問題番号, 結果...]) を処理
               // strideを使って2つずつ要素を取り出す
               for i in stride(from: 0, to: sessionData.count, by: 2) {
                   // 配列の範囲チェック (ペアが存在するか)
                   guard i + 1 < sessionData.count else { continue }

                   let questionID = sessionData[i]
                   let result = sessionData[i+1] // -1: 正解, -2: 不正解

                   // 問題IDがどの科目に属するかを検索
                   var subjectNameFound: String? = nil
                   for subjectInfo in ranges {
                       if subjectInfo.range.contains(questionID) {
                           subjectNameFound = subjectInfo.name
                           break // 見つかったらループを抜ける
                       }
                   }

                   // 対応する科目が見つかった場合のみ統計を更新
                   if let name = subjectNameFound, var stats = currentSessionStats[name] {
                       stats.total += 1 // 合計解答数をインクリメント
                       if result == -1 {
                           stats.correct += 1 // 正解数をインクリメント
                       } else if result == -2 {
                           stats.incorrect += 1 // 不正解数をインクリメント
                       }
                       currentSessionStats[name] = stats // 更新した統計情報を辞書に戻す
                   } else {
                       print("警告: 問題ID \(questionID) に対応する科目が見つかりませんでした。")
                   }
               }
               // このセッションの統計情報を全体のリストに追加
               allSessionsResults.append(currentSessionStats)
           }

           return allSessionsResults // 全セッションの分析結果を返す
       }


    
    func fetchAnalysisCommentFromGemini(result: AnalysisResult, userName: String) async throws -> String {

        // --- Geminiへの指示 (プロンプト) を組み立てる ---
        var prompt = """
        \(userName)さん、こんにちは！
        あなたは、保育士試験の学習者をサポートする経験豊富な女性チューターです。
        提供された複数セッションにわたる科目別のクイズ解答履歴データを分析してください。
        その分析に基づき、学習者の得意分野と苦手分野を特定し、今後の学習に役立つ具体的で励みになるアドバイスを日本語で生成してください。
        回答はチューターが喋っているようなものにしたいので、「はいわかりました」などのこちらのプロンプトに対する応答は不要で、本当にチューターが喋っているようなものにして。
        喋り方は丁寧な口調で。
        このプロンプトの中にある\(userName)、というのは学習者の名前なので、適宜呼びかけに使って。

        [分析データ]

        """

        if result.isEmpty {
            prompt += "解答履歴データがありません。\n"
        } else {
            for (index, sessionStats) in result.enumerated() {
                prompt += "--- セッション \(index + 1) ---\n"
                let sortedSubjectNames = sessionStats.keys.sorted()
                var sessionHasData = false
                for subjectName in sortedSubjectNames {
                    if let stats = sessionStats[subjectName], stats.total > 0 {
                        sessionHasData = true
                        let rate = stats.total == 0 ? 0 : (Double(stats.correct) / Double(stats.total)) * 100.0
                        prompt += "\(subjectName): 正解 \(stats.correct) / 全 \(stats.total) (正答率: \(String(format: "%.1f", rate))%)\n"
                    }
                }
                if !sessionHasData {
                    prompt += "(このセッションの解答記録はありません)\n"
                }
            }
        }

        prompt += """

        [指示]
        上記の分析データに基づいて、以下の要素を含むアドバイスを生成してください。
        1.  **得意分野の特定:** 正答率が高い科目を特定し、その知識を維持・強化する方法を提案してください。
        2.  **苦手分野の特定:** 正答率が低い、または停滞している科目を特定してください。
        3.  **苦手分野の対策:** 特定した苦手分野について、具体的な学習アプローチ（例: 重点的な復習、関連資料の参照、問題演習の増加など）を提案してください。
        4.  **成長の可視化:** セッション間で正答率が改善している科目があれば言及し、学習の成果を具体的に示して励ましてください。（例：「〇〇は前回△%から今回□%へと着実に力がついていますね！」）
        5.  **全体のトーン:** 学習者を励まし、前向きな気持ちで学習に取り組めるような、丁寧で建設的な語り口で記述してください。
        6.  **出力形式:** 自然な日本語の文章で、分析結果とアドバイスをまとめてください。ユーザーが次に行うべきアクションが明確になるように記述してください。

        それでは、分析とアドバイスの生成をお願いします。
        """

        print("--- Geminiへのプロンプト ---")
        print(prompt)
        print("--------------------------")

        let response = try await generativeModel.generateContent(prompt)

        guard let analysisText = response.text, !analysisText.isEmpty else {
            throw NSError(domain: "AnalysisCommentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Geminiからの分析コメントが空でした。"])
        }
        return analysisText
    }
    
    // --- ローディング状態のUIを制御するヘルパーメソッド ---
       private func setLoading(_ isLoading: Bool) {
           DispatchQueue.main.async { // UI更新はメインスレッドで
               //self.inputTextField.isEnabled = !isLoading
               //self.sendButton.isEnabled = !isLoading
               if isLoading {
                   self.AIAdviceTextView.text = "考え中..."
                   self.activityIndicator?.startAnimating()
               } else {
                   // ローディング解除時に "考え中..." を消すかは仕様による
                   // self.responseTextView.text = "" // 必要ならクリア
                   self.activityIndicator?.stopAnimating()
               }
           }
       }
    
   
    
    var timeAndStatusArray = [[String]]()
    //[[日付, 問題数, 正答数]]
    
    func loadArray() {
        var i = 0
        for status in statusArray{
            timeAndStatusArray.append([String(status.filter{$0 == -1}.count), String(status.filter{$0 == -2}.count), dateStringArray[i]])
            i += 1
            //print(timeAndStatusArray, "timeAndStatusArray")
        }
        print(timeAndStatusArray, timeAndStatusArray.count, "ここで表示内容c'k")
        
        timeAndStatusArray.reverse()
    }
    
// セクション数を返す
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セクションのタイトルを返す
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "演習履歴"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeAndStatusArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "statusCell", for: indexPath)
        cell.textLabel!.text = "正解数: \(timeAndStatusArray[indexPath.row][0]), 誤答数: \(timeAndStatusArray[indexPath.row][1]), 日付: \(timeAndStatusArray[indexPath.row][2])"
        return cell
    }
    
    
    @IBAction func moveToAITestButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "ChartsViewController") as? ChartsViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        
    }
    
}
