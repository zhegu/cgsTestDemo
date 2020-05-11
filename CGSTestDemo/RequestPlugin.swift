//
//  RequestPluginExample.swift
//  MoyaStudy
//
//  Created by 李哲 on 2018/6/26.
//  Copyright © 2018年 李哲. All rights reserved.
//

import Foundation
import Moya

/// show or hide the loading hud

//AccessTokenPlugin 管理AccessToken的插件
//CredentialsPlugin 管理认证的插件
//NetworkActivityPlugin 管理网络状态的插件
//NetworkLoggerPlugin 管理网络log的插件

//网络日志输出
public let networkLoggerPlugin = NetworkLoggerPlugin(configuration: NetworkLoggerPlugin().configuration)

//网络请求小菊花
public let newworkActivityPlugin = NetworkActivityPlugin { (change,LoginHttpApiManager)  -> () in
    switch(change){
    case .ended:
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    case .began:
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
}

//设置请求头
public let myEndpointClosure = { (target: MultiTarget) -> Endpoint in
    
    let url1 = target.baseURL as URL
    let url2 = url1.appendingPathComponent(target.path)
    
    let endpoint: Endpoint = Endpoint(
        url: url2.absoluteString,
        sampleResponseClosure: {.networkResponse(200, target.sampleData)},
        method: target.method,
        task: target.task,
        httpHeaderFields: target.headers
    )
    var extraHTTPHeaderFields: [String: String] = [:]
    extraHTTPHeaderFields["platform"] = "ios"
    extraHTTPHeaderFields["version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    return endpoint.adding(newHTTPHeaderFields: extraHTTPHeaderFields) // 请求头
}

//设置超时时常等
public let myRequestClosure = {(endpoint: Endpoint, closure: MoyaProvider<MultiTarget>.RequestResultClosure) -> Void in
    if var urlRequest = try? endpoint.urlRequest() {
        urlRequest.timeoutInterval = 5// 超时时长 // TODO: 修改超时时长
        closure(.success(urlRequest))
    } else {
        closure(.failure(MoyaError.requestMapping(endpoint.url)))
    }
}

// MARK: - 模拟网络请求
public let myStubClosure: (TargetType) -> Moya.StubBehavior  = { type in
    switch type {
    default:
//        return Moya.StubBehavior.never
        return Moya.StubBehavior.delayed(seconds: 5)
    }
}

// MARK: - 日志Plugin
public final class RequestLogsPlugin: PluginType {
    
    
    init() {
    }
    
    public func willSend(_ request: RequestType, target: TargetType) {
        print("开始请求")
        let url = request.request?.url
        let param = target.task
        let httpMethod = target.method
        let head = request.request?.allHTTPHeaderFields
    }
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        print("结束请求")
    }
    
}

// MARK: - 请求hud
public final class RequestLoadingPlugin: PluginType {
       var hide:Bool
 
    init(_ hideView:Bool) {
        self.hide = hideView
        guard self.hide else {
            
            return
        }
//        HUD = MBProgressHUD.showAdded(to: self.viewController.view, animated: true)
        
    }

    public func willSend(_ request: RequestType, target: TargetType) {
        print("开始请求")
//        LZNoticeHelper.wait()
    }
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        var message = "网络异常，请稍后重试";
//        LZNoticeHelper.clear()
        switch result {
        case let .success(response1):
            if response1.statusCode > 300 {
                message = "网络请求错误"
//                LZNoticeHelper.showNoticeWithText(.info, text: message, autoClear: true, autoClearTime: 2)
//                viewController.view.makeToast(message, duration: 1.0, position: ToastpositionCenter)
            }
        case let .failure(error):
            do {
                switch error {
                 
                case .underlying(let nsError as NSError, _):
                    // now can access NSError error.code or whatever
                    // e.g. NSURLErrorTimedOut or NSURLErrorNotConnectedToInternet
                    print(nsError.code)
                    if nsError.code == NSURLErrorTimedOut {
                        message = "请求超时，请稍后再试"
                    } else if nsError.code == NSURLErrorNotConnectedToInternet {
                        message = "网络未连接"
                    } else {
                        message = "请求错误，请稍后重试"
                    }
                    case .imageMapping(let response):
                        print(response)
                    case .jsonMapping(let response):
                        print(response)
                    case .statusCode(let response):
                        print(response)
                    case .stringMapping(let response):
                        print(response)
                    case .requestMapping:
                        print("nil")
                default:
                    message = "网络请求错误，请稍后重试"
                }
//                LZNoticeHelper.showNoticeWithText(.info, text: message, autoClear: true, autoClearTime: 2)
//                viewController.view.makeToast(message, duration: 1.0, position: ToastpositionCenter)
            }
        }
//        if case let .success(response1) = result {
//            print("response:\(response1)")
//            let str =  NSString(data:response1.data ,encoding: String.Encoding.utf8.rawValue)
//            print("str:\(str!)")
//            do {
//                let dataAsJSON = try JSONSerialization.jsonObject(with: response1.data)
//                let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
//                print("dataAsJSON:\(dataAsJSON)")
//                print("prettyData:\(prettyData)")
//            }catch {
//
//            }
//        }
//        if case let .failure(error) = result {
//            print("")
//        }
    }
    
}

// MARK: - 授权
public struct AuthPlugin: PluginType {
//    let token: String
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.timeoutInterval = 30
//        request.addValue(token, forHTTPHeaderField: "token")
        request.addValue("ios", forHTTPHeaderField: "platform")
        request.addValue("version", forHTTPHeaderField: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
        return request
    }
}

//检测token有效性
public final class AccessTokenPlugin: PluginType {
    private let viewController: UIViewController
    
    init(_ vc: UIViewController) {
        self.viewController = vc
    }

    public func willSend(_ request: RequestType, target: TargetType) {}
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        
        case .success(let response):
        //请求状态码
            guard  response.statusCode == 200   else {
                return
            }
            var json:Dictionary? = try! JSONSerialization.jsonObject(with: response.data,
                                                                             options:.allowFragments) as! [String: Any]
            print("请求状态码\(json?["status"] ?? "")")
            guard (json?["message"]) != nil  else {
                return
            }
            guard let codeString = json?["status"]else {return}
            //请求状态为1时候立即返回不弹出任何提示 否则提示后台返回的错误信息
            guard codeString as! Int != 1 else{return}
//           self.viewController.view .makeToast( json?["message"] as! String)
            
        case .failure(let error):
            print("出错了\(error)")
            
            break
        }
    }
}

//        provider.request(.Login(mdn: textFieldAccount.text!, password: textFieldPassword.text!.md5)) { result in
//            if case let .success(response) = result {
//                print("response:\(response)")
//                print("result:\(result)")
//                do {
//                    let str =  NSString(data:response.data ,encoding: String.Encoding.utf8.rawValue)
//                    print("str:\(str)")
//                    let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String : Any]
//                    print("json:\(json)")
//                    let dataAsJSON = try JSONSerialization.jsonObject(with: response.data)
//                    let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
//                    print("dataAsJSON:\(dataAsJSON)")
//                    print("prettyData:\(prettyData)")
////                    return prettyData
//                } catch {
//                    return //fallback to original data if it cant be serialized
//                }
//            }
//        }

//        let provider = MoyaProvider<LoginHttpApiManager>()


//        provider.request(.Test(mdn: "13311097869")) { (result) in
//            case let .success(moyaResponse):
//
//            case let .failure(error):


//            if case let .success(response1) = result {
//                print("response:\(response1)")
//                let str =  NSString(data:response1.data ,encoding: String.Encoding.utf8.rawValue)
//                print("str:\(str!)")
//                do {
//                    let dataAsJSON = try JSONSerialization.jsonObject(with: response1.data)
//                    let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
//                    print("dataAsJSON:\(dataAsJSON)")
//                    print("prettyData:\(prettyData)")
//                }catch {
//
//                }
//            }
//        }
