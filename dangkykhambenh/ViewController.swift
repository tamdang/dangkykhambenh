//
//  ViewController.swift
//  dangkykhambenh
//
//  Created by Tam Dang on 9/23/16.
//  Copyright © 2016 Tam Dang. All rights reserved.
//

import UIKit
import Alamofire
import FacebookLogin
import FacebookCore
import FBSDKCoreKit

class ViewController: UIViewController {

    @IBOutlet weak var loginFBButton: UIButton!
    @IBOutlet weak var textMessage: UILabel!

    @IBAction func loginFBButtonClick(_ sender: AnyObject) {
        
        let loginManager = LoginManager()
        
        if FBSDKAccessToken.current() != nil {
            // User is logged in, do work such as go to next view controller.
            //            loginFBButton.isHidden = true
            loginManager.logOut() // this is an instance function
            
            self.loginFBButton.titleLabel?.text = "Login"
            return
        }
        
        loginManager.logIn([.publicProfile], viewController: self){
            loginResult in
            switch loginResult{
            case .failed(let error):
                print(error)
            case .cancelled:
                print ("User canncelled login.")
            case .success(_, _, _):
                self.loginFBButton.titleLabel?.text = "Logout"
                let parameters = ["fields": "id, name"]
                FBSDKGraphRequest(graphPath: "me", parameters: parameters).start(completionHandler: { (connection, user, requestError) -> Void in
                    
                    if requestError != nil {
                        print(requestError)
                        return
                    }
                    
                    let userInfo : [String : Any] = (user as? [String : Any])!
                    
                    let id = userInfo["id"] as? String
                    let name = userInfo["name"] as? String
                    
                    self.textMessage.text = "name \(name!) id \(id!)"
                })

            }
        }
        
    }
    
    var count : Int = 2
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if FBSDKAccessToken.current() != nil {
            // User is logged in, do work such as go to next view controller.
//            loginFBButton.isHidden = true
            loginFBButton.titleLabel?.text = "Logout"
        }
        else{
            loginFBButton.titleLabel?.text = "Login"
        }
        
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
        
        
        //http://104.199.44.253/
        //Tams-MacBook-Pro.local:8080
        Alamofire.request(
            "http://104.199.44.253/DangKyKhamBenh_SERVER/index.php",
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

