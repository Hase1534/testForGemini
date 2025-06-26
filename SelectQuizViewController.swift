//
//  SelectQuizViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 2/13/25.
//

import UIKit
import Foundation

var KakomonOrKoumoku = Int()//1が過去問、2が項目別
var reversedOrnot = Bool()

class SelectQuizViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    var csvLines = [String]()
    var quizzesArray = [[String]]()
    
    // テーブルビュー表示用の配列。sectionsName と sectionsContents は原本的な扱いをして入れ替えないでおく。
    var displaySections: [String] = []
    var displayRowsInSection: [String] = []
    
    var alertController = UIAlertController()

    @IBOutlet var tableView: UITableView!
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("過去問か項目か", KakomonOrKoumoku)
        
        
        
        if let savedData = UserDefaults.standard.data(forKey: "quizzesArrayKey"),
           let decodedArray = try? JSONDecoder().decode([[String]].self, from: savedData) {
            quizzesArray = decodedArray
        } else {
        }
        
        let baseSectionNames = sectionsName     //原本を壊さないように保険
        let baseContentNames = sectionsContents

        
        if KakomonOrKoumoku == 1{
            //whenSelectedkakomon()//ここら辺が悪さしてそう？
            displaySections = baseContentNames
            displayRowsInSection = baseSectionNames
        }else{
            displaySections = baseSectionNames
            displayRowsInSection = baseContentNames
        }
        
        tableView.reloadData()
    }//end viewDidLoad
    
    
    
    //選択された年度・単元の問題を検索する関数
    func filterSubarraysContainingElements(in array: [[String]], elements: [String]) -> [[String]] {
        return array.filter { subArray in
            elements.allSatisfy { subArray.contains($0) }
        }
    }
    
    //ブクマ検索用の関数
    func filter2DArray<T: Equatable>(array2D: [[T]], filterArray: [T]) -> [[T]] {
        return array2D.filter { subArray in
            subArray.contains { filterArray.contains($0) }
        }
    }
    
    //ランダム出題用の関数
    func getRandomRows(from array: [[String]], count: Int) -> [[String]] {
        guard array.count >= count else {
            return array.shuffled()
        }
        return Array(array.shuffled().prefix(count))
    }
    
    //過去問が選択された時はsectionとかをひっくり返す関数
    //戻った時にひっくり返らない様にする処理が必要
    
    
    func whenSelectedkakomon(){
        if reversedOrnot == true{
            reversedOrnot = false
            print(reversedOrnot)
        }else{
            //こっちがひっくり返す方
            let temp = sectionsName
            sectionsName = sectionsContents
            sectionsContents = temp
            reversedOrnot = true
            print(reversedOrnot, "ひっくり返った")
        }
        
        
//        if reversedOrnot  == false{
//            let temp = sectionsName
//            sectionsName = sectionsContents
//            sectionsContents = temp
//            reversedOrnot = true
//        }else{
//            //既にひっくり返っている時
//            reversedOrnot = false
//        }
    }
    
    
    
    // UITableViewDataSource メソッド: セクションの数
    func numberOfSections(in tableView: UITableView) -> Int {
        return displaySections.count
    }

    // UITableViewDataSource メソッド: セクションごとの行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayRowsInSection.count//全セクションで問題の数は一緒と仮定
    }

    // UITableViewDataSource メソッド: セルの内容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectQuizCell", for: indexPath)
        cell.textLabel?.text = displayRowsInSection[indexPath.row]
            return cell
    }

    // UITableViewDataSource メソッド: セクションタイトル
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < displaySections.count {
                    return displaySections[section]
        }
        return nil
    }
    
    //セル選択時の挙動
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 選択された表示上のテキスト
        let selectedSectionHeaderText = displaySections[indexPath.section]
        let selectedRowItemText = displayRowsInSection[indexPath.row]

        var searchKeyForOriginalSectionName: String
        var searchKeyForOriginalQuizName: String

        if KakomonOrKoumoku == 1 {                  // 過去問モード
            searchKeyForOriginalSectionName = selectedRowItemText
            searchKeyForOriginalQuizName = selectedSectionHeaderText
        } else {
            searchKeyForOriginalSectionName = selectedSectionHeaderText
            searchKeyForOriginalQuizName = selectedRowItemText
        }

        selectedSectionName = searchKeyForOriginalSectionName
        selectedQuizName = searchKeyForOriginalQuizName

        var searchElements = [String]()
        searchElements.append(selectedSectionName) // 元の科目名に相当するもの
        searchElements.append(selectedQuizName)    // 元の単元名に相当するもの

        let filteredSubarrays = filterSubarraysContainingElements(in: quizzesArray, elements: searchElements)
        quizzesArray01 = filteredSubarrays
        numberOfQuizzes = filteredSubarrays.count//次のViewCOntrollerに問題数を渡す処理
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController {
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
     }
    
}//end class

