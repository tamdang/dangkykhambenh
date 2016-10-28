//
//  TableController.swift
//  dangkykhambenh
//
//  Created by Tam Dang on 10/16/16.
//  Copyright © 2016 Tam Dang. All rights reserved.
//

import UIKit
import Alamofire

class TableController: UITableViewController {

    @IBOutlet weak var login: UIBarButtonItem!
    var tableData : [[String:String]] = [[String:String]]()
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender as? UIBarButtonItem === login {
            print("LOGIN BUTTON SELECTED")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.getSeatInfo(doctorID: 1)
    }
    
    
    func getSeatInfo(doctorID: Int){
//        let parameters: Parameters = [
//            "doctorID": doctorID
//        ]
        
//        let url : String = Config.Instance.serverURL + "getSeats/" + String(doctorID)
        
        let url : String = Config.Instance.serverURL + Config.Instance.phpGetSeatInfo + String(doctorID)

        Alamofire.request(
            url,
            method: .get,
            parameters: nil,
            encoding: URLEncoding.httpBody,
            headers:HMACAlgorithm.header ).responseJSON { response in
                if let urlContent = response.data {
                    do {
                        if let jsonArray = try JSONSerialization.jsonObject(with: urlContent, options:
                            JSONSerialization.ReadingOptions.mutableContainers) as? NSArray{
                            for json in jsonArray {
                                if let seatInfo = json as? NSDictionary {
                                    let seatID = seatInfo["i"] as! String;
                                    let seatStatus = seatInfo["s"] as! String;
                                    var d = [String:String]()
                                    d["seatID"] = seatID;
                                    d["seatStatus"] = seatStatus;
                                    self.tableData.append(d)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                return
                            }
                        }
                    } catch {
                        print("JSON Processing Failed")
                    }
                }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = "Seat ID = \(tableData[indexPath.row]["seatID"]!), Status = \(tableData[indexPath.row]["seatStatus"]!)"
        // Configure the cell...

        return cell
    }
 

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    func bookASeat(userID: String, doctorID : Int, seatID : Int){
        let parameters: Parameters = [
            "doctorID": doctorID,
            "userID" : userID,
            "seatID" : seatID
        ]
        
        let url : String = Config.Instance.serverURL + Config.Instance.phpBookASeat
        
//        let url : String = Config.Instance.serverURL + "bookASeat"
        
        Alamofire.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody,
            headers:HMACAlgorithm.header).responseJSON { response in
                if let urlContent = response.data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: urlContent, options:
                        JSONSerialization.ReadingOptions.mutableContainers) as? [String:String]{
                            if let message = json["msg"] {
                                let alertController = UIAlertController(title: self.title, message: message, preferredStyle:UIAlertControllerStyle.alert)
                                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                                { action -> Void in
                                    
                                    // Put your code here
                                })
                                self.present(alertController, animated: true, completion: nil)
                            }
                            
                            
                        }
                    } catch {
                        print("JSON Processing Failed")
                    }
                }
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let diceRoll = Int(arc4random_uniform(1000000) + 1)
        
        bookASeat(userID: String(diceRoll) , doctorID: 1, seatID: Int(self.tableData[indexPath.row]["seatID"]!)!)
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
