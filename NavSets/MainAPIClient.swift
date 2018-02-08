//
//  MainAPIClient.swift
//  NavSets
//
//  Created by Adam Greenstein on 12/5/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import Foundation
import Alamofire
import Stripe

class MainAPIClient: NSObject, STPEphemeralKeyProvider {
    
    static let sharedClient = MainAPIClient()
    var baseURLString: String? = nil
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
//    func createCustomer(_ result: STPPaymentResult, user: UserModel, completion: @escaping STPErrorBlock){
//        var json_response: String? = nil
//        let url = self.baseURL.appendingPathComponent("create_customer")
//        let params: [String: Any] = [
//            "source": result.source.stripeID,
////            "stripeToken": token
//        ]
//        Alamofire.request(url, method: .post, parameters: params)
//            .validate(statusCode: 200..<300)
//            .responseJSON { responseJSON in
//                switch responseJSON.result {
//                case .success(let json):
//                    print("Success with JSON: \(json)")
////                    print(json as? [String: AnyObject])
//                    json_response = json as? String
//                    completion(nil)
//                case .failure(let error):
//                    print("Request failed with error: \(error)")
//                    completion(error)
//                }
//        }
//        print (json_response as Any)
//        user.stripeID = json_response
//    }
    
    func completeCharge(_ result: STPPaymentResult,
                        amount: Int, currency: String, customer: String,
                        completion: @escaping STPErrorBlock) {
        let url = self.baseURL.appendingPathComponent("charge")
        let params: [String: Any] = [
            "source": result.source.stripeID,
            "amount": amount,
            "currency": currency,
            "customer_id": customer,
        ]
        Alamofire.request(url, method: .post, parameters: params)
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
        }
    }
    
    func authenticate(customer: String) -> String {
        var finished = 0
        var result = ""
        let url = self.baseURL.appendingPathComponent("authenticate")
        let params: [String: Any] = [
            "customer_id": customer,
            ]
        Alamofire.request(url, method: .post, parameters: params)
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    finished = 1
                    result = (json as? String)!
                case .failure(let error):
                    finished = 1
                    print (error)
                }
        }
        // wait for the request to finish so we can actually get the result
        while finished == 0 {
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: NSDate.distantFuture)
        }
        return result
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        Alamofire.request(url, method: .post, parameters: [
            "api_version": apiVersion,
            ])
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    completion(json as? [String: AnyObject], nil)
                case .failure(let error):
                    print (error)
                    completion(nil, error)
                }
        }
    }
}

