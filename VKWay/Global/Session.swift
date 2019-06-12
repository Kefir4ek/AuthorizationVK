//
//  Session.swift
//  VKWay
//
//  Created by Евгений Оводков on 15/05/2019.
//  Copyright © 2019 Евгений Оводков. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseFirestore


class Session {
    
    var token:String
    var id:Int {
        didSet{
            let db = Firestore.firestore()
            db.collection("users").document("\(id)").setData(["id":id], mergeFields: ["id"])
            
            
        }
    }
    
    var name:String
    var avatar:UIImage?
    
    
    static let current = Session()
    
    private init() {
        token = ""
        id    = 0
        name  = ""
    }
    
    func authorization(controller: UIViewController,_ completionHandler: @escaping ()->()){
        
        Auth.auth().signInAnonymously(completion: nil)
        
        
        id = UserDefaults.standard.integer(forKey: "id")
        
        if id == 0 {
            openAuthorizationForm(controller: controller, completionHandler: completionHandler)
            return
        }
        
        if token.isEmpty {
            token = KeychainWrapper.standard.string(forKey: "token") ?? ""
        }
        
        if token.isEmpty {
            openAuthorizationForm(controller: controller, completionHandler: completionHandler)
        }
        
        //token validation
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.vk.com"
        urlComponents.path = "/method/users.get"
        urlComponents.queryItems = [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.95")
        ]
        
        guard let url = urlComponents.url else {
            openAuthorizationForm(controller: controller, completionHandler: completionHandler)
            return
        }
        
        AF.request(url).response{ response in
            
            guard let data = response.data else {
                self.openAuthorizationForm(controller: controller, completionHandler: completionHandler)
                return
            }
            
            guard let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                self.openAuthorizationForm(controller: controller, completionHandler: completionHandler)
                return
            }
            
            guard let jsonResponse = jsonObj as? [String:Any] else {
                self.openAuthorizationForm(controller: controller, completionHandler: completionHandler)
                return
            }
            
            if jsonResponse.keys.contains("error") {
                self.openAuthorizationForm(controller: controller, completionHandler: completionHandler)
                return
            } else {
                completionHandler()
            }
        }
        
    }
    
    func logOut(controller: UIViewController) {
        
        openAuthorizationForm(controller: controller, logOut: true) {
            
        }
        
        
    }
    
    private func openAuthorizationForm(controller: UIViewController, logOut:Bool=false, completionHandler: @escaping ()->()) {
        
        let authorization = AuthorizationViewController(nibName: "AuthorizationViewController", bundle: nil)
        authorization.completitionHandler = completionHandler
        authorization.logOut = logOut
        controller.present(authorization, animated: true)
        
    }
    
}
