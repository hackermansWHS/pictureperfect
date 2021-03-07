//
//  SignUpViewController.swift
//  PicturePerfect
//
//  Created by Akshay Kumar on 1/17/21.
//

import Foundation
import UIKit
import Firebase

class SignUpViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet var emailTF: UITextField!
    @IBOutlet var passwordTF: UITextField!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.

            self.emailTF.delegate = self
            self.passwordTF.delegate = self
        }
    
    
    @IBAction func signUpUser(_ sender: UIButton) {
        if let email = emailTF.text, let pass = passwordTF.text{
            print("click")
            Auth.auth().createUser(withEmail: email, password: pass) { (authResult, error) in
                print("acooutn")
                if let e = error{
                    print(e.localizedDescription)
                } else{
                    self.performSegue(withIdentifier: "signupSegue", sender: sender)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
}
