//
//  HttpApiManager.swift
//  mts-manager
//
//  Created by 李哲 on 2018/6/26.
//  Copyright © 2018年 李哲. All rights reserved.
//

// test for update

// test pull 1
// test pull 2
// test pull 3
import Foundation
import Moya
import ObjectMapper
import RxSwift

public enum HttpConfig {
    case Develop
    case Test
    case PreRelease
    case Release
}

public var httpConfig:HttpConfig = .Test
public var httpBaseUrl:URL{
    switch httpConfig {
    case .Develop:
        return URL.init(string:"http://xxx.xxx.xxx.xxx:8082")!
    case .Test:
        return URL.init(string:"http://xxx.xxx.xxx.xxx:60001")!
    case .PreRelease:
        return URL.init(string:"11")!
    case .Release:
        return URL.init(string:"http://xxx")!
    }
}

public var httpFreeExperienceUrl:URL{
    switch httpConfig {
    case .Develop:
        return URL.init(string:"http://xxx")!
    case .Test:
        return URL.init(string:"http://xxx")!
    case .PreRelease:
        return URL.init(string:"http://xxx")!
    case .Release:
        return URL.init(string:"http://xxx")!
    }
}

public struct NetworkRequest {
    static var requestLoading:RequestLoadingPlugin? = nil
    static var baseRxProvicer:MoyaProvider<MultiTarget>? = nil
    
    //封装快速网络请求方法
    public static func getProvice(_ hideView:Bool)->MoyaProvider<MultiTarget> {
        requestLoading = RequestLoadingPlugin(hideView)
        baseRxProvicer = MoyaProvider<MultiTarget>(endpointClosure:myEndpointClosure, requestClosure: myRequestClosure, stubClosure:myStubClosure, plugins:[networkLoggerPlugin,newworkActivityPlugin,requestLoading!])
        return baseRxProvicer!

    }
    
    
    //封装常用请求
    public static func mtsRequest<T: Mappable>(_ hideView:Bool,_ target:MultiTarget,_ type: T.Type)-> Observable<(code:Int, object:T?, message:String, serverTime:Int)>{
       return NetworkRequest.getProvice(hideView).rx
            .request(target)
            .filterSuccessfulStatusCodes()
            .mapJSON()
            .asObservable()
            .mapObject(type: type)
    }
    
    // MARK: -取消所有请求
    public static func cancelAllRequest() {
        //    MyAPIProvider.manager.session.invalidateAndCancel()  //取消所有请求
//        baseRxProvicer?.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
//            dataTasks.forEach { $0.cancel() }
//            uploadTasks.forEach { $0.cancel() }
//            downloadTasks.forEach { $0.cancel() }
//        }
        
        //let sessionManager = Alamofire.SessionManager.default
        //sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
        //    dataTasks.forEach { $0.cancel() }
        //    uploadTasks.forEach { $0.cancel() }
        //    downloadTasks.forEach { $0.cancel() }
        //}
        
    }
}
