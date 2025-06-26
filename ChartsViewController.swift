//
//  ChartsViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 5/16/25.
//

import UIKit
import Charts
import DGCharts

class ChartsViewController: UIViewController {

    
    @IBOutlet weak var pieChartsView: UIView!
    @IBOutlet weak var lineChartsView: UIView!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //print("")
        
        if let savedStatusArray = UserDefaults.standard.array(forKey: "statusArrayKey") as? [[Int]] {
            statusArray = savedStatusArray
        } else {
            // 保存されていない場合
            print("No data found for key 'statusArrayKey'")
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

        // 円グラフを作成
        setupPieChart()
        setupLineChart()
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
    
    func setupPieChart() {
        let pieChart = PieChartView()
        pieChart.frame = pieChartsView.bounds
        pieChart.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pieChartsView.addSubview(pieChart)
        pieChart.centerText = "科目別演習割合"
           
       var correctCountBySubject: [String: Int] = [:]
       var totalCountBySubject: [String: Int] = [:]

       for history in statusArray {
           for i in stride(from: 0, to: history.count, by: 2) {
               let problemNumber = history[i]
               let result = history[i + 1]

               for subjectRange in subjectRanges {
                   if subjectRange.range.contains(problemNumber) {
                       //let subject = subjectRange.subjectValue
                       let subject = subjectRange.name
                       totalCountBySubject[subject, default: 0] += 1
                       if result == -1 {
                           correctCountBySubject[subject, default: 0] += 1
                       }
                   }
               }
           }
       }
       
       var entries: [PieChartDataEntry] = []
       for (subject, total) in totalCountBySubject {
           let correct = correctCountBySubject[subject, default: 0]
           let percentage = Double(correct) / Double(total) * 100
           let entry = PieChartDataEntry(value: percentage, label: "\(subject) (\(Int(percentage))%)")
           entries.append(entry)
       }
       
       let dataSet = PieChartDataSet(entries: entries, label: "科目別正解率")
       dataSet.colors = ChartColorTemplates.joyful()
       let data = PieChartData(dataSet: dataSet)
       pieChart.data = data
        
       pieChart.holeColor = UIColor.white
       pieChart.usePercentValuesEnabled = true
       pieChart.drawSlicesUnderHoleEnabled = false
       pieChart.animate(yAxisDuration: 1.4, easingOption: .easeInOutQuart)
    }
    
    func setupLineChart() {
        timeAndStatusArray.reverse()//ここでひっくり返したの直す
        let lineChart = LineChartView()

        // lineChartsViewに追加
        lineChart.frame = lineChartsView.bounds
        lineChart.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lineChartsView.addSubview(lineChart)

        // 時間と正答率の推移を格納する配列
        var dataEntries: [ChartDataEntry] = []

        // timeAndStatusArrayを走査して、正答率を計算
        for (index, data) in timeAndStatusArray.enumerated() {
            if let correctAnswers = Int(data[0]), let incorrectAnswers = Int(data[1]) {
                // 正答数 / (正答数 + 誤答数) = 正答率
                let totalAnswers = correctAnswers + incorrectAnswers
                let correctRate = totalAnswers > 0 ? Double(correctAnswers) / Double(totalAnswers) * 100 : 0
                
                // ChartDataEntryに時間インデックスをx軸に、正答率をy軸に設定
                let entry = ChartDataEntry(x: Double(index), y: correctRate)
                dataEntries.append(entry)
            }
        }

        // 折れ線グラフのデータセットを作成
        let lineChartDataSet = LineChartDataSet(entries: dataEntries, label: "正答率の推移")
        lineChartDataSet.colors = [NSUIColor.blue]  // 線の色
        lineChartDataSet.valueColors = [NSUIColor.black]  // 値の色
        lineChartDataSet.circleColors = [NSUIColor.red]  // 円の色（データ点）
        lineChartDataSet.circleRadius = 5  // 円の半径

        // LineChartDataにデータセットをセット
        let lineChartData = LineChartData(dataSet: lineChartDataSet)

        // 折れ線グラフにデータをセット
        lineChart.data = lineChartData

        // その他の設定（x軸のラベルを日時に変更）
        let xAxis = lineChart.xAxis
        xAxis.valueFormatter = IndexAxisValueFormatter(values: timeAndStatusArray.map { $0[2] })
        xAxis.granularity = 1  // 1回ごとの間隔で表示（インデックス単位）
        xAxis.labelRotationAngle = 45  // ラベルを45度回転

        // y軸の設定
        let leftAxis = lineChart.leftAxis
        leftAxis.axisMinimum = 0  // y軸の最小値を0に設定
        leftAxis.axisMaximum = 100  // y軸の最大値を100%に設定

        // 右側のy軸（表示しない）
        lineChart.rightAxis.enabled = false

        // グラフのアニメーション
        lineChart.animate(xAxisDuration: 1.5, yAxisDuration: 1.5)

        timeAndStatusArray.reverse()//ここでひっくり返したの直す
            
    }//ここまで折れ線グラフ
    
    
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

}
