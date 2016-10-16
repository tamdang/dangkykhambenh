//
//  Config.swift
//  dangkykhambenh
//
//  Created by Tam Dang on 10/9/16.
//  Copyright © 2016 Tam Dang. All rights reserved.
//

import Foundation

class Config{
    //MARK: Shared Instance
    
    private static var sharedInstance : Config? = nil
    
    let serverURL : String
    let phpIsUserRegistered : String
    let phpRegisterANumber : String
    let phpGetCurrentAndNext : String
    let phpGetSeatInfo : String

    static var Instance : Config = {
        
        if let instance = Config.sharedInstance {
            return instance
        }
        else {
            return Config()
        }
    }()
    
    init(){
        
        var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        var plistData: [String: AnyObject] = [:] //Our data
        let plistPath: String? = Bundle.main.path(forResource: "Config", ofType: "plist")! //the path of the data
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {//convert the data to a dictionary and handle errors.
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListForamt) as! [String:AnyObject]
        } catch {
            print("Error reading plist: \(error), format: \(propertyListForamt)")
        }
        
//        serverURL = plistData["serverURL"] as! String
        serverURL = plistData["localURL"] as! String
        phpIsUserRegistered = plistData["phpIsUserRegistered"] as! String
        phpRegisterANumber = plistData["phpRegisterANumber"] as! String
        phpGetCurrentAndNext = plistData["phpGetCurrentAndNext"] as! String
        phpGetSeatInfo = plistData["phpGetSeatInfo"] as! String
        
    }

}
