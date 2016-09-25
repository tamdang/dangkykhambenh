//
//  ViewController.swift
//  dangkykhambenh
//
//  Created by Tam Dang on 9/23/16.
//  Copyright © 2016 Tam Dang. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var textMessage: UILabel!
    
    var count : Int = 2
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func insertData(_ sender: AnyObject) {
        count += 1
        let parameters: Parameters = [
            "name": "Dang Thanh Tam XCODE \(count)",
            "email": "dangtam@gmail.com",
            "status": "active"
        ]
        
        Alamofire.request(
            "http://Tams-MacBook-Pro.local:8080/DangKyKhamBenh_SERVER/index.php",
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody).responseJSON { response in
                
                debugPrint(response)
                
                if let urlContent = response.data {
                    
                    do {
                        
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options:
                            JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                        
                        self.textMessage.text = jsonResult["msg"] as! String?
                        
                        
                    } catch {
                        
                        print("JSON Processing Failed")
                    }
                }
        }

    }
}

