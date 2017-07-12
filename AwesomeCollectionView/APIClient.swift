//
//  APIClient.swift
//  AwesomeCollectionView
//
//  Created by Truong Vo on 10/7/17.
//  Copyright © 2017 RayMob. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class APIClient: NSObject {
    
    static let sharedInstance = APIClient()
    
    func requestGETURL(_ apiURL: String, success:@escaping (JSON) -> Void, failure:@escaping (Error) -> Void) {
        var strURL: String = kBaseURL
        if ((apiURL as NSString).length > 0) {
            strURL = strURL + "/" + apiURL
        }
        
        print(strURL)
        
        Alamofire.request(strURL).responseJSON { (responseObject) -> Void in
            
            //print(responseObject)
            
            if responseObject.result.isSuccess {
                let resJson = JSON(responseObject.result.value!)
                success(resJson)
            }
            
            if responseObject.result.isFailure {
                let error : Error = responseObject.result.error!
                failure(error)
            }
        }
    }
    
    func requestPOSTURL(_ apiURL : String, params : [String : AnyObject]?, headers : [String : String]?, success:@escaping (JSON) -> Void, failure:@escaping (Error) -> Void) {
        var strURL: String = kBaseURL
        if ((apiURL as NSString).length > 0) {
            strURL = strURL + "/" + apiURL
        }
        
        print(strURL)
        
        Alamofire.request(strURL, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
            
            //print(responseObject)
            
            if responseObject.result.isSuccess {
                let resJson = JSON(responseObject.result.value!)
                success(resJson)
            }
            
            if responseObject.result.isFailure {
                let error : Error = responseObject.result.error!
                failure(error)
            }
        }
    }
    
    func getSampleData(success:@escaping (JSON) -> Void, failure:@escaping (Error) -> Void) {
        // Load json file async
        // DispatchQueue.global().async {
        // Add 2 secs of delay to simulate a network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            if let path = Bundle.main.url(forResource: "test", withExtension: "json") {
                do {
                    let data = try Data(contentsOf: path)
                    let json = JSON(data: data)
                    success(json)
                } catch {
                    print(error)
                    failure(error)
                }
            }
        })
    }
    
}
