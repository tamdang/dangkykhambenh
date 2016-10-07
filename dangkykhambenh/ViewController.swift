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

class ViewController: UIViewController, LoginButtonDelegate {

    /**
     Called when the button was used to login and the process finished.
     
     - parameter loginButton: Button that was used to login.
     - parameter result:      The result of the login.
     */
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult){
        print("hahaha")
        switch result {
        case .failed(let error):
            print(error)
        case .cancelled:
            print("User cancelled login.")
        case .success(_, _, _):
            print("Logged in!")
            
            // Requires user_likes permission to be granted.
//            let connection = GraphRequestConnection()
//            connection.add(GraphRequest(graphPath: "me/likes")) {
//                (response: HTTPURLResponse?, result: GraphRequestResult<GraphRequest>) in
//                // Process error or results here.
//                
//                
//                print(result)
//            }
//            connection.start()
//            
            
            let parameters = ["fields": "id, name"]
            FBSDKGraphRequest(graphPath: "me", parameters: parameters).start(completionHandler: { (connection, user, requestError) -> Void in
                
                if requestError != nil {
                    print(requestError)
                    return
                }
                
                let userInfo : [String : Any] = (user as? [String : Any])!
                
                let id = userInfo["id"] as? String
                let name = userInfo["name"] as? String
                
                print("id: \(id) name: \(name)")
        })
    }
    
//    func returnUserData()
//    {
//        
//        
//        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
//        
//        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
//            
//            if ((error) != nil)
//            {
//                // Process error
//                print("Error: \(error)")
//            }
//            else
//            {
//                print("fetched user: \(result)")
//                let userName : NSString = result.valueForKey("name") as! NSString
//                print("User Name is: \(userName)")
//                let userEmail : NSString = result.valueForKey("email") as! NSString
//                print("User Email is: \(userEmail)")
//            }
//        })
    }
    
    /**
     Called when the button was used to logout.
     
     - parameter loginButton: Button that was used to logout.
     */
    func loginButtonDidLogOut(_ loginButton: LoginButton){
        
    }
    
    @IBOutlet weak var textMessage: UILabel!
    
    var count : Int = 2
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        loginButton.delegate = self
        
        view.addSubview(loginButton)
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

