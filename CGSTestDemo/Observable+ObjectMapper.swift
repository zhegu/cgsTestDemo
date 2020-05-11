//
//  Observable+ObjectMapper.swift
//  RxSwiftMoya
//
//  Created by 李哲 on 2018/6/26.
//  Copyright © 2018年 李哲. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import ObjectMapper
//import Result

fileprivate let RESULT_CODE = "code"
fileprivate let RESULT_MSG = "message"
fileprivate let RESULT_RESPONSE = "response"
fileprivate let RESULT_TIME = "serverTime"

typealias NetworkResponseTuple = (code:Int, object:Any?, message:String, serverTime:Int)

extension Observable {
    
  public func mapObject<T: Mappable>(type: T.Type) -> Observable<(code:Int, object:T?, message:String, serverTime:Int)> {
        return self.map { response in
            //if response is a dictionary, then use ObjectMapper to map the dictionary
            //if not throw an error
            guard let dict = response as? [String: Any] else {
                throw RxSwiftMoyaError.ParseJSONError
            }
            guard (dict["code"] as?Int) != nil else {
                throw RxSwiftMoyaError.ParseJSONError
           }
            var netServerTime = 0
            if let serverTime = dict[RESULT_TIME] as? Int {
                netServerTime = serverTime
            }
            
            // 服务器返回code
            if let code = dict[RESULT_CODE] as? Int {
                if code == 1 {
                    // get data
                    let data =  dict[RESULT_RESPONSE]
                    if let data = data as? [String: Any] {
                        // 使用 ObjectMapper 解析成对象
                        let object = Mapper<T>().map(JSON: data)!
                        return  (code, object, "success", netServerTime)
                    }else {
                        throw RxSwiftMoyaError.ParseJSONError
                    }
                } else {
                    if let message = dict[RESULT_MSG] as? String {
                       return  (code, nil, message, netServerTime)
                    } else {
                       return  (code, nil, "服务器异常", netServerTime)
                    }
                    
                }
            } else {
                throw RxSwiftMoyaError.ParseJSONError
            }
        }
    }
    
   public func mapArray<T: Mappable>(type: T.Type) -> Observable<(code:Int, object:[T]?, message:String, serverTime:Int)> {
        
        return self.map { response in
            //if response is a dictionary, then use ObjectMapper to map the dictionary
            //if not throw an error
            guard let dict = response as? [String: Any] else {
                throw RxSwiftMoyaError.ParseJSONError
            }
            guard (dict["code"] as?Int) != nil else {
                throw RxSwiftMoyaError.ParseJSONError
            }
            var netServerTime = 0
            if let serverTime = dict[RESULT_TIME] as? Int {
                netServerTime = serverTime
            }
            
            // 服务器返回code
            if let code = dict[RESULT_CODE] as? Int {
                if code == 1 {
                    // get data
                    let data =  dict[RESULT_RESPONSE]
                    if let data = data as? [Any] {
                        // 使用 ObjectMapper 解析成对象
                        let object = Mapper<T>().mapArray(JSONArray: data as! [[String : Any]])
                        return  (code, object, "success", netServerTime)
                    }else {
                        throw RxSwiftMoyaError.ParseJSONError
                    }
                } else {
                    if let message = dict[RESULT_MSG] as? String {
                        return  (code, nil, message, netServerTime)
                    } else {
                        return  (code, nil, "服务器异常", netServerTime)
                    }
                    
                }
            } else {
                throw RxSwiftMoyaError.ParseJSONError
            }
        }
    }
    
  public  func parseServerError() -> Observable {
        return self.map { (response) in
            let name = type(of: response)
            print(name)
            guard let dict = response as? [String: Any] else {
                throw RxSwiftMoyaError.ParseJSONError
            }
            if let error = self.parseError(response: dict) {
                throw error
            }
            return self as! Element
        }
        
    }
    
    fileprivate func parseError(response: [String: Any]?) -> NSError? {
        var error: NSError?
        if let value = response {
             var code:Int?
          
         
            if let codes = value["code"] as?Int
            {
                code = codes
                
            }
            if  code != 200 {
                var msg = ""
                if let message = value["message"] as? String {
                    msg = message
                }
                error = NSError(domain: "Network", code: code!, userInfo: [NSLocalizedDescriptionKey: msg])
            }
        }
        return error
    }
    
   
}




public enum RxSwiftMoyaError: String {
    case ParseJSONError
    case OtherError
}

extension RxSwiftMoyaError: Swift.Error {

    
}
