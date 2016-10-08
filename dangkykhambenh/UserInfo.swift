//
//  UserInfo.swift
//  dangkykhambenh
//
//  Created by Tam Dang on 10/8/16.
//  Copyright © 2016 Tam Dang. All rights reserved.
//

import Foundation
class UserInfo{
    //MARK: Shared Instance
    
    private static var sharedInstance : UserInfo? = nil
    
    var id : String?
    var name: String?
    
    static var Instance : UserInfo = {
        
        if let instance = UserInfo.sharedInstance {
            return instance
        }
        else {
            return UserInfo()
        }
    }()
    
}
