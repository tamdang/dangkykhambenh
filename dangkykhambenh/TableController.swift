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

    var tableData : [[String:String]] = [[String:String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.getSeatInfo(doctorID: 1)
    }
    
    
    func getSeatInfo(doctorID: Int){
        let parameters: Parameters = [
            "doctorID": doctorID
        ]
        
        let url : String = Config.Instance.serverURL + Config.Instance.phpGetSeatInfo
        
        Alamofire.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody).responseJSON { response in
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
//                                if let seatInfo = json as? NSDictionary {
//                                    let seatID = seatInfo["i"] as! String;
//                                    let seatStatus = seatInfo["s"] as! String;
//                                    print("Seat ID: \(seatID), status: \(seatStatus)")
//                                }
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
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
