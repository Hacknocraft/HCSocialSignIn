//
//  ProfileViewController.swift
//  HCSocialSignIn
//
//  Created by HAO WANG on 5/24/17.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import AlamofireImage

class ProfileViewController: UIViewController {

    var avatarURL: String?
    var username: String?
    var userEmail: String?

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var userInfo: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = avatarURL, let imageURL = URL(string: url) {
            self.avatarImageView.af_setImage(withURL: imageURL)
        }

        if let name = username {
            userInfo.text = name + "\n"
        }

        if let email = userEmail {
            userInfo.text =  "\(userInfo.text ?? "") \(email)"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
