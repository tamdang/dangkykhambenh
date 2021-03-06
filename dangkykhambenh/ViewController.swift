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
    
    var isUserRegister : Bool = false
    
    @IBOutlet weak var labelNext: UILabel!
    @IBOutlet weak var labelCurrent: UILabel!
    
    @IBAction func loginFBButtonClick(_ sender: AnyObject) {
        
        let loginManager = LoginManager()
        
        if FBSDKAccessToken.current() != nil {
            // User is logged in, do work such as go to next view controller.
            loginManager.logOut()
            
            self.loginFBButton.setTitle("Login", for: UIControlState.normal)
            textMessage.text = ""

            UserInfo.Instance.id = nil
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
                self.loginFBButton.setTitle("Logout", for: UIControlState.normal)

                self.getFacebookUserInfo()
            }
        }
        
    }
    
    func getFacebookUserInfo(){
        
        let parameters = ["fields": "id, name"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).start(completionHandler: { (connection, user, requestError) -> Void in
            
            if requestError != nil {
                print(requestError)
                return
            }
            
            if let userInfo = user as? [String:String] {
                UserInfo.Instance.id = userInfo["id"]
                UserInfo.Instance.name = userInfo["name"]
                self.getSeatInfo(doctorID: 1)
//                self.isUserRegistered()
                
//                self.getCurrentAndNext(doctorID: 0)
            }
        })
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        var loginButtonTitle : String

        if FBSDKAccessToken.current() != nil {
            // User is logged in, do work such as go to next view controller.
            loginButtonTitle = "Logout"
            getFacebookUserInfo()
            
        }
        else{
            loginButtonTitle = "Login"
            UserInfo.Instance.id = nil
        }
        
        self.loginFBButton.setTitle(loginButtonTitle, for: UIControlState.normal)
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func insertData(_ sender: AnyObject) {
        
        if UserInfo.Instance.id == nil {
            let message = "Pls. login in with FB in order to register"
            let alertController = UIAlertController(title: title, message: message, preferredStyle:UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            { action -> Void in
                
                // Put your code here
            })
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        requestAPresenseNumber(userID: UserInfo.Instance.id!, doctorID: 1)
    }
    
    func requestAPresenseNumber(userID:String, doctorID: Int){

        let parameters: Parameters = [
            "userID": userID,
            "doctorID": doctorID
        ]
        
        let url : String = Config.Instance.serverURL + Config.Instance.phpRequesetAPresenseNumber
        
        Alamofire.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody,
            headers:HMACAlgorithm.header).responseJSON { response in
                if let urlContent = response.data {
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options:
                            JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, String>
                        
                        if let registerNumber = Int(jsonResult["msg"]!){
                            if registerNumber < 0 {
                                self.textMessage.text = "DAY OFF"
                            }
                            else {
                                self.textMessage.text = "Your number is \(registerNumber)"
                            }
                        }
                    } catch {
                        print("JSON Processing Failed")
                    }
                }
        }
    }
    
    func isUserRegistered(){
        let parameters: Parameters = [
            "id": UserInfo.Instance.id!
        ]
        
        let url : String = Config.Instance.serverURL + Config.Instance.phpIsUserRegistered
        
        Alamofire.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody).responseJSON { response in
                if let urlContent = response.data {
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options:
                            JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                        
                        if let rowCount = Int(jsonResult["msg"] as! String){
                            if rowCount > 0 {
                                self.requestAPresenseNumber(userID: UserInfo.Instance.id!, doctorID: 1)
                            }
                        }
                    } catch {
                        print("JSON Processing Failed")
                    }
                }
        }
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
                                    print("Seat ID: \(seatID), status: \(seatStatus)")
                                }
                            }
                        }
                    } catch {
                        print("JSON Processing Failed")
                    }
                }
        }

    }
    
    func getCurrentAndNext(doctorID: Int){
        let parameters: Parameters = [
            "doctorID": doctorID
        ]
        
        let url : String = Config.Instance.serverURL + Config.Instance.phpGetCurrentAndNext
        
        Alamofire.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody).responseJSON { response in
                if let urlContent = response.data {
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options:
                        JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, AnyObject>
                        
                        if let json = jsonResult {
                            if let currentNumber = Int(json["current"] as! String) {
                                if currentNumber > 0{
                                    self.labelCurrent.text = "CURRENT: " + String(currentNumber)
                                }
                                else{
                                    self.labelCurrent.text = "CURRENT: NOT START YET"
                                }
                            }
                            
                            if let nextNumber = Int(json["next"] as! String) {
                                if nextNumber > 0 {
                                    self.labelNext.text = "NEXT: " + String(nextNumber)
                                }
                                else {
                                    self.labelNext.text = "NO ONE ELSE IS WAITING"
                                }
                            }
                        }
                        
                    } catch {
                        print("JSON Processing Failed")
                    }
                }
        }
    }

    @IBAction func unwindToSetting(sender: UIStoryboardSegue){
        if sender.source is TableController{
            print("BACK FROM TableController unwindToSetting")
        }
    }
//
//    @IBAction func unwindToLogin(sender: UIStoryboardSegue){
//        if sender.source is TableController{
//            print("BACK FROM TableController unwindToLogin")
//        }
//    }
}

