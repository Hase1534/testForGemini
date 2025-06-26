//
//  SettingViewController.swift
//  certificationExamPrototype03
//
//  Created by TERU on 2/20/25.
//

import UIKit

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let sections = ["アカウント", "一般", "背景","サポート"]
    let items = [
        ["プロフィール"],
        ["通知", "言語設定",],
        ["画像設定"],
        ["ヘルプ", "フィードバック"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        //ここからUD
        if let savedValue = UserDefaults.standard.object(forKey: "numberOfSelectedQuizKey") as? Int {
            numberOfSelectedQuiz = savedValue
        } else {
            numberOfSelectedQuiz = 10// 初回起動時のデフォルト値
        }
        
    }//end viewDidLoad
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.text = items[indexPath.section][indexPath.row]
        
        // 条件を満たすセルだけ右側にテキストを表示
           if indexPath.section == 2 && indexPath.row == 0 {
               cell.detailTextLabel?.text = "\(numberOfSelectedQuiz) 問"
               print("ここは実装されてる")
           } else {
               cell.detailTextLabel?.text = nil // 他のセルは右側のテキストを非表示にする
           }
        // 右側にアクセサリ（矢印）を追加
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
        /*
        // 問題数設定がタップされた時にPickerViewControllerへ遷移
        if indexPath.section == 2 && indexPath.row == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "PickerViewController") as? PickerViewController {
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
         */
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "SettingProfileViewController") as? SettingProfileViewController {
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
        
        if indexPath.section == 3 && indexPath.row == 1{
            if let url = URL(string: "https://docs.google.com/forms/d/1nuJp8o46ExFANQfuDeMkIbqbofAyE69eNj3iCIuae1M/edit") {
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
              }
        }
        
    }
    
}
