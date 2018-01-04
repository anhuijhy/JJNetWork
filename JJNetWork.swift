//
//  JJNetWork.swift
//  CouponPro
//
//  Created by 123 on 2017/11/21.
//  Copyright © 2017年 Jason. All rights reserved.
//

import Foundation
import Alamofire


class JJNetWork {
    
    static let shareJJNetWork = JJNetWork();
    
    fileprivate init(){}
    
    /// 存储目前下载的下载task，以供resume使用
    var dlArr = [Any]()
    
    /// 基础网络访问
    ///
    /// - Parameters:
    ///   - method: <#method description#>
    ///   - url: <#url description#>
    ///   - parameters: <#parameters description#>
    ///   - sucBlock: <#sucBlock description#>
    ///   - failBlock: <#failBlock description#>
    func jjRequest(_ method:HTTPMethod = .post,at url:String,p parameters:NSDictionary, suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> (Void) {
        
        let pp:Parameters = parameters as! Parameters;
        let fullUrl = WEBSERVER + url;
        Alamofire.request(fullUrl, method: method, parameters: pp, encoding: JSONEncoding.default, headers: nil).responseJSON(queue: DispatchQueue.main, options: JSONSerialization.ReadingOptions.allowFragments) { (resData) in
            if (resData.result.isSuccess){
                
                if let _ = resData.data {
                    
                    let pData:Data = resData.data!;
                    do{
                        let pDic:NSDictionary = try JSONSerialization.jsonObject(with: pData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                        print("json解释对象是\(pDic)");
                        let rescode:NSNumber = pDic.object(forKey: "code") as! NSNumber;
                        
                        if (rescode.intValue == 0){
                            //==
                            sucBlock(pDic);
                            //==
                        }else{
                            failBlock(rescode.intValue,"后台错误信息",pDic);
                        }
                    }catch let e as NSError{
                        
                        print("json解析出现问题\(e)");
                        print(resData);
                    }
                }
            }else{
                
                if let _ = resData.error {
                    let e : NSError = resData.error! as NSError;
                    //网络请求错误
                    print(e.domain);
                    failBlock(-9999,"网络错误",nil);
                }else{
                    failBlock(-9999,"网络错误",nil);
                }
            }
            
        }
        
    }
    
    //=======================================================
    /// 上传数据方法,处理参数问题，然后上传
    ///
    /// - Parameters:
    ///   - patameters: 可能的数据
    ///   - data: 上传的数据 暂时以data类型传递过来
    func jjUploadHandle(_ patameters:NSDictionary,at url:String, upload data:Data,suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> Void {
        
        do {
            
            let Url = try url.asURL();
            self.jjUpload(patameters, at: Url, upload: data, suc: sucBlock,fail: failBlock);
            
        } catch let e as NSError {
            
            print("URL转换失败\(e)");
        }
        
    }
    
    /// 参数处理完毕，上传
    ///
    /// - Parameters:
    ///   - patameters: <#patameters description#>
    ///   - url: <#url description#>
    ///   - data: <#data description#>
    ///   - sucBlock: <#sucBlock description#>
    ///   - failBlock: <#failBlock description#>
    func jjUpload(_ patameters:NSDictionary,at url:URL, upload data:Data, suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> Void {
        
        Alamofire.upload(data, to:url, method: .put, headers: nil).uploadProgress(queue: DispatchQueue.global(qos:.utility)) { pro in
            print("the upload process is\(pro.fractionCompleted)")
            }.downloadProgress(queue: DispatchQueue.global(qos: .utility)) { pro in
                print("the download process is \(pro.fractionCompleted)")
            }.validate { (req, res, data) -> Request.ValidationResult in
                return .success;
            }.responseJSON { (resData) in
                print(resData);
                if (resData.result.isSuccess){
                    
                    if let _ = resData.data {
                        
                        let pData:Data = resData.data!;
                        do{
                            let pDic:NSDictionary = try JSONSerialization.jsonObject(with: pData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                            print("json解释对象是\(pDic)");
                            let rescode:NSNumber = pDic.object(forKey: "code") as! NSNumber;
                            
                            if (rescode.intValue == 0){
                                //==
                                sucBlock(pDic);
                                //==
                            }else{
                                failBlock(rescode.intValue,"后台错误信息",pDic);
                            }
                        }catch let e as NSError{
                            
                            print("json解析出现问题\(e)");
                            print(resData);
                        }
                    }
                }else{
                    
                    if let _ = resData.error {
                        let e : NSError = resData.error! as NSError;
                        //网络请求错误
                        print(e.domain);
                        failBlock(-9999,"网络错误",nil);
                    }else{
                        failBlock(-9999,"网络错误",nil);
                    }
                }
        }
    }
    
    
    /// 上传图片
    ///
    /// - Parameters:
    ///   - patameters: <#patameters description#>
    ///   - url: <#url description#>
    ///   - data: <#data description#>
    ///   - sucBlock: <#sucBlock description#>
    ///   - failBlock: <#failBlock description#>
    func jjUploadImg(_ patameters:NSDictionary,at url:URL, upload data:Data,suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> Void {
        do {
            let Url = try url.asURL();
            Alamofire.upload(multipartFormData: { (multipartFormData) in
                
                multipartFormData.append(data, withName: "file", fileName: "file.jpeg", mimeType: "image/jpeg")
                
                for(k,v) in patameters{
                    let vs = v as! String
                    multipartFormData.append(vs.data(using: String.Encoding.utf8)!, withName: k as! String);
                }
            }, to: Url, encodingCompletion: { (res) in
                
                switch res{
                case .success(let upload, _, _):
                    upload.responseJSON(completionHandler: { (resData) in
                        print(resData);
                        if (resData.result.isSuccess){
                            
                            if let _ = resData.data {
                                
                                let pData:Data = resData.data!;
                                do{
                                    let pDic:NSDictionary = try JSONSerialization.jsonObject(with: pData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                                    print("json解释对象是\(pDic)");
                                    let rescode:NSNumber = pDic.object(forKey: "code") as! NSNumber;
                                    
                                    if (rescode.intValue == 0){
                                        //==
                                        sucBlock(pDic);
                                        //==
                                    }else{
                                        failBlock(rescode.intValue,"后台错误信息",pDic);
                                    }
                                }catch let e as NSError{
                                    
                                    print("json解析出现问题\(e)");
                                    print(resData);
                                }
                            }
                        }else{
                            
                            if let _ = resData.error {
                                let e : NSError = resData.error! as NSError;
                                //网络请求错误
                                print(e.domain);
                                failBlock(-9999,"网络错误",nil);
                            }else{
                                failBlock(-9999,"网络错误",nil);
                            }
                        }
                    })
                    break;
                case .failure(_):
                    break;
                }
            })
            
        } catch let e as NSError {
            
            print("URL转换失败\(e)");
        }
    }
    
    
    /// 下载数据
    ///
    /// - Parameters:
    ///   - url: <#url description#>
    ///   - detURL: <#detURL description#>
    ///   - sucBlock: <#sucBlock description#>
    ///   - failBlock: <#failBlock description#>
    func jjDownload(_ url:URL,at detURL:URL,res resID:String,paremeters p:Dictionary<String, Any>?,suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> Void {
        
        //先判断同一个id 是否已经下载，如果已经有数据下载过那么进行resumeData下载
        let resumepath = JJNetWork.shareJJNetWork.resIsExist(resID);
        if (resumepath.count > 0){
            //resume dl
            do {
            let resumeData = try Data.init(contentsOf: URL.init(fileURLWithPath: resumepath))
            
                JJNetWork.shareJJNetWork.jjResumeDownload(resumeData, at: detURL, res: resID, paremeters: p, suc: sucBlock, fail: failBlock)
                
            }catch let e as NSError{
                print("获取resume data 失败 重新直接下载\(e)")
                do {
                    let u = try url .asURL()
                    JJNetWork.shareJJNetWork.jjDerectDownload(u, at: detURL, res: resID, paremeters: p, suc: sucBlock, fail: failBlock)
                } catch let e as NSError{
                    print("URL错误\(e)")
                }
            }
        }else{
            
            do {
                let u = try url .asURL()
                JJNetWork.shareJJNetWork.jjDerectDownload(u, at: detURL, res: resID, paremeters: p, suc: sucBlock, fail: failBlock)
            } catch let e as NSError{
                
                print("URL错误\(e)")
            }
        }
    }
    
    
    /// 直接下载
    ///
    /// - Parameters:
    ///   - url: <#url description#>
    ///   - detURL: <#detURL description#>
    ///   - resID: <#resID description#>
    ///   - p: <#p description#>
    ///   - sucBlock: <#sucBlock description#>
    ///   - failBlock: <#failBlock description#>
    func jjDerectDownload(_ url:URL,at detURL:URL,res resID:String,paremeters p:Dictionary<String, Any>?,suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> Void {
        
        let tk =  Alamofire.download(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil, to: { (tem, _) -> (detURL: URL, options: DownloadRequest.DownloadOptions) in
            return (detURL, [.createIntermediateDirectories, .removePreviousFile])
        }).downloadProgress(queue: DispatchQueue.global(qos:.utility), closure: { (pro) in
            
            print("Progress: \(pro.fractionCompleted)")
            print("totol unitcound\(pro.totalUnitCount)")
        }).responseJSON(completionHandler: { (res) in
            print("download \(res)")
            debugPrint(res);
        }).validate({ (resq, res, _, _) -> Request.ValidationResult in
            
            print("response \(res)")
            return .success
        }).task

        dlArr.append(tk!);
    }
    
    /// Resume下载
    ///
    /// - Parameters:
    ///   - resumeData: <#resumeData description#>
    ///   - detURL: <#detURL description#>
    ///   - resID: <#resID description#>
    ///   - p: <#p description#>
    ///   - sucBlock: <#sucBlock description#>
    ///   - failBlock: <#failBlock description#>
    func jjResumeDownload(_ resumeData:Data,at detURL:URL,res resID:String,paremeters p:Dictionary<String, Any>?,suc sucBlock:@escaping (NSDictionary) -> Void, fail failBlock:@escaping (NSInteger,String,NSDictionary?) ->Void) -> Void{
        
        Alamofire.download(resumingWith: resumeData) { (tem, res) -> (detURL: URL, options: DownloadRequest.DownloadOptions) in
            return (detURL,[.createIntermediateDirectories,.removePreviousFile])
            }.downloadProgress(queue: DispatchQueue.global(qos:.utility), closure: { (pro) in
                print("resume dl Progress: \(pro.fractionCompleted)")
                print("totol unitcound\(pro.totalUnitCount)")
            }).responseJSON(completionHandler: { (res) in
                print("download \(res)")
                debugPrint(res);
            }).validate({ (resq, res, _, _) -> Request.ValidationResult in
                print("response \(res)")
                return .success
            })
    }
    
    
    /// 挂起 通常认为的暂停
    ///
    /// - Parameter resID: <#resID description#>
    func suspendPauseTask(_ resID:String) -> Void {
        //这里需要将  tk?.taskIdentifier 和 resID 对应，每一个下载可以是一个Model 包含 resID和taskIdentifier
        let task = dlArr[0] as! URLSessionTask
        task.suspend()
    }
    
    
    /// 恢复暂停
    ///
    /// - Parameter resID: <#resID description#>
    func resumeSuspendPauseTask(_ resID:String) -> Void {
        
        //这里需要将  tk?.taskIdentifier 和 resID 对应，每一个下载可以是一个Model 包含 resID和taskIdentifier
        let task = dlArr[0] as! URLSessionTask
        task.resume()
    }
    
    
    /// 取消下载
    ///
    /// - Parameter resID: <#resID description#>
    func cancelTask(_ resID:String) -> Void {
        //这里需要将  tk?.taskIdentifier 和 resID 对应，每一个下载可以是一个Model 包含 resID和taskIdentifier
        let task = dlArr[0] as! URLSessionTask
        task.cancel()
    }
    
    
    /// 断点保存
    ///
    /// - Parameter resID: <#resID description#>
    func cancelForResumeTask(_ resID:String) -> Void {
        //这里需要将  tk?.taskIdentifier 和 resID 对应，每一个下载可以是一个Model 包含 resID和taskIdentifier
        //需要根据resID找出task
        var doc = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
        let tmp = "tmp" + "/" + resID
        doc = doc.appendingPathComponent(tmp) as NSString
        let task = dlArr[0] as! URLSessionDownloadTask
        task.cancel { (data) in
            do{
                try  data?.write(to: URL.init(fileURLWithPath: doc as String), options: Data.WritingOptions.atomic)
                
            }catch let e as NSError{
                
                print("cancelForResumeDate error \(e.description)");
            }
        }
    }
    //=====================================================
    
    /// 检测资源是否存在
    ///
    /// - Parameter idStr: <#idStr description#>
    /// - Returns: <#return value description#>
    func resIsExist(_ idStr:String) -> (String) {
        var doc = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0];
        doc = doc + "/tmp" + "/" + idStr
        
        if(FileManager.default.fileExists(atPath: doc)){
            
            return doc
            
        }else{
            
            return ""
        }
    }
}



