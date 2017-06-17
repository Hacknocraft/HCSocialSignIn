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

        let linkedInManager = HCLinkedInManager.sharedInstance

        linkedInManager.key = linkedInKey
        linkedInManager.secret = linkedInSecret
        linkedInManager.redirectUrl = redirectUrl

        linkedInManager.login(viewController: self) { (success, _) in

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
            ["fields": "id, name, first_name, last_name, email, picture.type(large)"]) { (info, error) in

                HUD.hide()
                if error == nil {
                    if let picture = info?["picture"] as? [String: AnyObject],
                        let data = picture["data"] as? [String: AnyObject],
                        let url = data["url"] as? String {

                        self.avatarURL = url
                    }
                    self.userEmail = info?["email"] as? String
                    self.username = info?["name"] as? String
                    self.userID = info?["id"] as? String
                    self.goToProfile()
                } else {
                    HUD.flash(.labeledError(title: "Request failed",
                                            subtitle: "Cannot fetch user profile from Facebook"))
                }
        }
    }

    func handleLinkedInLoginSuccess() {
        HUD.show(.progress)

        let fields = ["email-address", "first-name", "last-name", "picture-url"]
        HCLinkedInManager.sharedInstance.fetchCurrentProfileInfo(parameters: fields) { (info, error) in

            HUD.hide()

            if let json = info {

                var username = ""
                if let firstName = json["firstName"] as? String {
                    username = firstName
                }
                if let lastName = json["lastName"] as? String {
                    username += " \(lastName)"
                }
                self.username = username

                self.userEmail = json["emailAddress"] as? String
                self.avatarURL = json["pictureUrl"] as? String

                self.goToProfile()

            } else if error != nil {

                HUD.flash(.labeledError(title: "Request failed",
                                        subtitle: "Cannot fetch user profile from LinkedIn"))
            }
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
