//
//  SelectTestViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 3/14/25.
//

import UIKit
import Foundation

var nameOfSubjectsArray = [String]()
var numberOfSelectedQuiz: Int = 10

class SelectTestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource{
    
var quizzesArray02 = [[String]]()
    @IBOutlet weak var numberOfQuizLabel: UILabel!
    
    @IBOutlet weak var selectTestTableView: UITableView!
    
    @IBOutlet weak var quizCountPickerView: UIPickerView!
    
    let labelText = "上記科目から　　　　演習"
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        
        selectTestTableView.delegate = self
        selectTestTableView.dataSource = self
        
        quizCountPickerView.delegate = self
        quizCountPickerView.dataSource = self
        
        // Pickerの初期値を10にする（インデックスは0から始まるので9を指定）
      
    
        if let savedData = UserDefaults.standard.data(forKey: "quizzesArrayKey"),
           let decodedArray = try? JSONDecoder().decode([[String]].self, from: savedData) {
            quizzesArray02 = decodedArray
        } else {
            print("読み込まれてない")
        }
        
        
        //ここからUD,Pickerとラベルに反映
        if let savedValue = UserDefaults.standard.object(forKey: "numberOfSelectedQuizKey") as? Int {
            numberOfSelectedQuiz = savedValue
            print("今の問題数 viewDidLoad UDから: \(savedValue)")
        } else {
            numberOfSelectedQuiz = 10 // 初回起動時のデフォルト値
            UserDefaults.standard.set(numberOfSelectedQuiz, forKey: "numberOfSelectedQuizKey") // デフォルト値を保存
        }
        
        //numberOfQuizLabel.text = "上記科目から\(numberOfSelectedQuiz)問演習"
        numberOfQuizLabel.text = labelText
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let savedValue = UserDefaults.standard.object(forKey: "numberOfSelectedQuizKey") as? Int {
            if numberOfSelectedQuiz != savedValue { //値が異なっていれば更新
                numberOfSelectedQuiz = savedValue
                print("今の問題数 viewWillAppear UDから: \(savedValue)")
            }
        }
        updateUIForSelectedQuizCount()
        //numberOfQuizLabel.text = "上記科目から\(numberOfSelectedQuiz)問演習"
        numberOfQuizLabel.text = labelText
    }
    
    func updateUIForSelectedQuizCount() {
        //numberOfQuizLabel.text = "上記科目から\(numberOfSelectedQuiz)問演習"
        numberOfQuizLabel.text = labelText
        // PickerViewの選択位置を更新 (numberOfSelectedQuizは1から、rowは0から始まる)
        // Pickerの行数が30行（1〜30問）と仮定
        if numberOfSelectedQuiz >= 1 && numberOfSelectedQuiz <= 30 {
            quizCountPickerView.selectRow(numberOfSelectedQuiz - 1, inComponent: 0, animated: false)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    // セクションのタイトル
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "出題科目"
    }
    
    
    // セルの数（仮で10個）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameOfSubjectsArray.count
    }
        
    // セルの表示設定
    /*func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectTestTableViewCell", for: indexPath)
        cell.textLabel?.text = nameOfSubjectsArray[indexPath.row]
        // セルの選択スタイルを変更（ハイライトなし）
        cell.selectionStyle = .none
        
        return cell
    }
     */
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectTestTableViewCell", for: indexPath)
        cell.textLabel?.text = nameOfSubjectsArray[indexPath.row]
        cell.selectionStyle = .none
        // 既に選択されている科目にチェックマークを付ける処理（必要に応じて）
        if selectedSubjectArray.contains(nameOfSubjectsArray[indexPath.row]) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    var selectedSubjectArray = [String]()
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            let subject = nameOfSubjectsArray[indexPath.row]
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                if let index = selectedSubjectArray.firstIndex(of: subject) {
                    selectedSubjectArray.remove(at: index)
                }
            } else {
                cell.accessoryType = .checkmark
                if !selectedSubjectArray.contains(subject) {
                    selectedSubjectArray.append(subject)
                }
            }
        }
        print(selectedSubjectArray)
    }
 
    var selectedquizzesArray = [[String]]()
    func filterQuizzesArray(quizzesArray: [[String]], selectedSubjectArray: [String]) -> [[String]] {
        //var quizzesArray01: [[String]] = []
        
        // quizzesArrayの各配列をチェック
        for quiz in quizzesArray {
            // quizの要素がselectedSubjectArrayに含まれているかどうかを確認
            if quiz.contains(where: { selectedSubjectArray.contains($0) }) {
                selectedquizzesArray.append(quiz) // 含まれていた場合、quizzesArray01に追加
            }
        }
        print(selectedquizzesArray.count, "今ここであらよりの問題数確認")
        
        return selectedquizzesArray
    }
    
//    func extractSelectedQuizzes(selectedQuizzesArray: [[String]], numberOfSelectedQuiz: Int) -> [[String]] {
//        // numberOfSelectedQuiz個の要素を抜き出す
//        // selectedQuizzesArrayがnumberOfSelectedQuizより長い場合にのみ抜き出しを行う
//        
//        if selectedQuizzesArray.count >= numberOfSelectedQuiz {
//            // 配列の最初からnumberOfSelectedQuiz個だけ抜き出す
//            quizzesArray01 = Array(selectedQuizzesArray.prefix(numberOfSelectedQuiz))
//        } else {
//            // selectedQuizzesArrayがnumberOfSelectedQuizより短い場合、そのまま全てを格納
//            quizzesArray01 = selectedQuizzesArray
//        }
//        
//        return quizzesArray01
//    }
    
    func extractSelectedQuizzes(selectedQuizzesArray: [[String]], numberOfSelectedQuiz: Int) -> [[String]] {
        if selectedQuizzesArray.count >= numberOfSelectedQuiz {
            // 配列をシャッフルしてからランダムにnumberOfSelectedQuiz個取り出す
            return Array(selectedQuizzesArray.shuffled().prefix(numberOfSelectedQuiz))
        } else {
            // 全体がnumberOfSelectedQuizより少ない場合、そのままシャッフルして返す
            return selectedQuizzesArray.shuffled()
        }
    }
    
    @IBAction func startTestButton(_ sender: Any) {
        let filteredQuizzes = filterQuizzesArray(quizzesArray: quizzesArray02, selectedSubjectArray: selectedSubjectArray)
        quizzesArray01 = extractSelectedQuizzes(selectedQuizzesArray: filteredQuizzes, numberOfSelectedQuiz: numberOfSelectedQuiz) // グローバル変数 numberOfSelectedQuiz を使用
        
        print(quizzesArray01.count, "最終的な問題数")
        numberOfQuizzes = quizzesArray01.count // 次の画面に渡す問題数
        
        // selectedSectionName は、次のQuizViewControllerでどのようにタイトル表示に使われるかによります。
        // 科目選択に応じて動的に変更するか、固定の文字列にするか検討が必要です。
        // ここでは一旦、元のコードの意図を尊重しつつ、より汎用的な名前にするか、
        // 選択された科目を連結した文字列などを設定することも考えられます。
        if selectedSubjectArray.isEmpty {
            selectedSectionName = "ランダム演習" // 何も科目が選択されていない場合など
        } else if selectedSubjectArray.count == 1 {
            selectedSectionName = selectedSubjectArray.first!
        } else {
            selectedSectionName = "選択科目演習" // 複数選択時
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        
    }
    // MARK: - UIPickerViewDataSource & Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // 問題数のみなので1コンポーネント
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 30 // 1問から30問まで選択可能にする (0行目から29行目)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1) 問" // 表示は1から30問
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        numberOfSelectedQuiz = row + 1 // 選択された値をnumberOfSelectedQuizに保存 (1から30)
        UserDefaults.standard.set(numberOfSelectedQuiz, forKey: "numberOfSelectedQuizKey") // UserDefaultsに保存
        //numberOfQuizLabel.text = "上記科目から\(numberOfSelectedQuiz)問演習" // ラベル表示を更新
        print("Pickerで選択された問題数: \(numberOfSelectedQuiz)")
    }

}

