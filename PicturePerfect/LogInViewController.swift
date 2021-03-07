//
//  LogInViewController.swift
//  
//
//  Created by Akshay Kumar on 1/17/21.
//

import Foundation
import UIKit
import Firebase

class LogInViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet var emailTF: UITextField!
    @IBOutlet var passwordTF: UITextField!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.

            self.emailTF.delegate = self
            self.passwordTF.delegate = self
        }
    
    @IBAction func loginUser(_ sender: UIButton) {
        if let email = emailTF.text, let pass = passwordTF.text{
            Auth.auth().signIn(withEmail: email, password: pass) { (authResult, error) in
                if let e = error{
                    print(e)
                } else{
                    self.performSegue(withIdentifier: "loginSegue", sender: self)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
