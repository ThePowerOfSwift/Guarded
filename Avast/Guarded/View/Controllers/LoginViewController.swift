//
//  LoginViewController.swift
//  Guarded
//
//  Created by Rodrigo Hilkner on 20/10/17.
//  Copyright © 2017 Rodrigo Hilkner. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginButton = FBSDKLoginButton()
        loginButton.delegate = self
        
        view.addSubview(loginButton)
        //TODO: substituir por constraints
        loginButton.frame = CGRect(x: 16, y: 50, width: view.frame.width - 32, height: 50)
        
        print("oi")
        
        //checking if user is already logged in
        if (FBSDKAccessToken.current() != nil) {
            print("hm")
            LoginServices.handleUserLoggedIn {
                successful in
                
                if (successful == false) {
                    print("Couldn't fetch user's facebook or database information.")
                    return
                }
                
                self.performSegue(withIdentifier: "MapViewController", sender: nil)
            }
        }
    }
    
}


extension LoginViewController: FBSDKLoginButtonDelegate {
    
    //method called after user logs in to facebook
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        guard (error == nil) else {
            print("Error on clicking facebook login button.")
            return
        }
        
        if result.isCancelled {
            print("Facebook login has been cancelled")
            return
        }
        
        LoginServices.handleUserLoggedIn {
            successful in
            
            if (successful == false) {
                print("Couldn't fetch user's facebook or database information.")
                return
            }
            
            self.performSegue(withIdentifier: "MapViewController", sender: nil)
        }
    }
    
    //method called after user logs out of facebook
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("App did log out of facebook.")
        LoginServices.handleUserLoggedOut()
    }
}
