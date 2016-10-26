//
//  HMAC.swift
//  dangkykhambenh
//
//  Created by Tam Dang on 10/25/16.
//  Copyright © 2016 Tam Dang. All rights reserved.
//

import Foundation
enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCEnum() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
    
    static private let publicHash = "d1f830fc2233e06762caf8bf5185205ed796027bb1a17ef2b748b545c8696923"
    static private let privateKey = "b3565d37723f653cc39054d71d7398d9ac5b9ffa6073e83b65c4c81ecad2d73d"
    static private let hashContent = "c4f943484a97b9d978a206011eb0f876380dd8c053b238eca604ec79de940dc7"
    static private let content = "e2eaae785a40bd7f0de1adcc5bfd9b7abf123b889a278b370d3e58e33b8ae059"
    
    static let header = [
        "X-Public" : HMACAlgorithm.publicHash,
        "X-Hash" : HMACAlgorithm.hashContent,
        "content" : HMACAlgorithm.content
    ];
    
}

extension String {
    
    func digest(algorithm: HMACAlgorithm, key: String) -> String! {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = UInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = UInt(key.lengthOfBytes(using: String.Encoding.utf8))
        
        CCHmac(algorithm.toCCEnum(), keyStr!, Int(keyLen), str!, Int(strLen), result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deinitialize()
        
        return String(hash)
    }
    
}
