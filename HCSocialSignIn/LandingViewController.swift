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

    var userID: String?
    var avatarURL: String?
    var username: String?
    var userEmail: String?

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

        let linkedInKey = "81zmve1omyn2cn"
        let linkedInSecret = "ErrcmDNQXkwJtQd4"
        let redirectUrl = "http://hacknocraft.com/"
        let scope = ["r_basicprofile", "r_emailaddress"]

        HCLinkedInManager.sharedInstance.login(viewController: self,
                                               key: linkedInKey,
                                               secret: linkedInSecret,
                                               redirectUrl: redirectUrl,
                                               scope: scope) { (success, _) in

                                                if success {
                                                    self.handleLinkedInLoginSuccess()
                                                }
        }
    }

    @IBAction func twitterLoginTapped(_ sender: Any) {
    }

    // MARK: - Profile fetching

    func handleFacebookLoginSuccess() {
        HUD.show(.progress)
        HCFacebookManager.sharedInstance
            .fetchCurrentProfileInfo(parameters:
            ["fields": "id, name, first_name, last_name, email, picture.type(large)"]) { (info, _) in

                HUD.hide()
                if let picture = info?["picture"] as? [String: AnyObject],
                    let data = picture["data"] as? [String: AnyObject],
                    let url = data["url"] as? String {

                    self.avatarURL = url
                }
                self.userEmail = info?["email"] as? String
                self.username = info?["name"] as? String
                self.userID = info?["id"] as? String
                self.goToProfile()
        }
    }

    func handleLinkedInLoginSuccess() {
        HUD.show(.progress)

        let fields = ["id", "email-address", "first-name", "last-name", "public-profile-url"]
        HCLinkedInManager
            .sharedInstance
            .fetchCurrentProfileInfo(parameters: fields) { (info, _) in

                HUD.hide()

                let firstName = info?["firstName"] as? String
                let lastName = info?["lastName"] as? String
                self.username = "\(String(describing: firstName)) \(String(describing: lastName))"

                self.userEmail = info?["emailAdress"] as? String
                self.userID = info?["id"] as? String
                self.avatarURL = info?["publicProfileUrl"] as? String

                self.goToProfile()
        }
    }

    // MARK: - Navigate

    func goToProfile() {

        self.performSegue(withIdentifier: "AuthenticationFinishSegue", sender: self.facebookButton)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AuthenticationFinishSegue" {
            if let destinationVC = segue.destination as? ProfileViewController {
                destinationVC.username = self.username
                destinationVC.userEmail = self.userEmail
                destinationVC.avatarURL = self.avatarURL
            }
        }
    }
}
