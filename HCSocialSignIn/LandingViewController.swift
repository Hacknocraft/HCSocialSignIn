//
//  ViewController.swift
//  HCSocialSignIn
//
//  Created by HAO WANG on 5/23/17.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import PKHUD

class LandingViewController: UIViewController {

    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var linkedInButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions

    @IBAction func facebookLoginTapped(_ sender: Any) {
        HCFacebookManager.sharedInstance.login(viewController: self) { (result, error) in
            if error != nil {
                // some error happened
            } else if result?.isCancelled ?? false {
                // user cancelled
            } else {
                // login is successful
                self.handleFacebookLoginSuccess()
            }
        }
    }

    @IBAction func linkedInLoginTapped(_ sender: Any) {
    }

    @IBAction func twitterLoginTapped(_ sender: Any) {
    }

    // MARK: - Profile fetching
    func handleFacebookLoginSuccess() {
        HUD.show(.progress)
        HCFacebookManager.sharedInstance
            .fetchCurrentProfileInfo(parameters: ["fields": "id, name, first_name, last_name, email, picture.type(large)"]) { (info, error) in

                HUD.hide()
                self.performSegue(withIdentifier: "AuthenticationFinishSegue", sender: self.facebookButton)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("prepare")
    }
}

