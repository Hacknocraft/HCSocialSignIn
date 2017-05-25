//
//  HCFacebookManager.swift
//  HCSocialSignIn
//
//  Created by HAO WANG on 5/24/17.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import Foundation
import FBSDKLoginKit

/// This class handles all interaction with Facebook SDK
open class HCFacebookManager: NSObject {

    open static let sharedInstance = HCFacebookManager()

    static let defaultProfileParams = ["fields": "id, name, first_name, last_name, email, picture.type(large)"]

    /// login via Facebook
    ///
    /// - Parameters:
    ///   - viewController: controller where you are logging in from
    ///   - permissions: the permissions you want to request from the user
    ///   - complete: completion block
    open func login(viewController: UIViewController,
                    permissions: [String] = ["public_profile", "email"],
                    complete: ((_ result: FBSDKLoginManagerLoginResult?, _ error: Error?) -> Void)?) {

        let manager = FBSDKLoginManager()
        manager.logIn(withReadPermissions: permissions,
                      from: viewController) { (result, error) in

                        complete?(result, error)
        }
    }

    /// Fetch the current user's profile
    ///
    /// - Parameters:
    ///   - parameters: parameters in the profile that you wish to fetch
    ///   - complete: the completion block
    open func fetchCurrentProfileInfo(parameters: [String: String] = HCFacebookManager.defaultProfileParams,
                                      complete: ((_ profile: [String: AnyObject]?, _ error: Error?) -> Void)?) {

        let request = FBSDKGraphRequest(graphPath: "me",
                                        parameters: parameters)
        _ = request?
            .start(completionHandler: { (_, result, error) in
            if let info = result as? [String: AnyObject] {
                complete?(info, nil)
            } else {
                complete?(nil, error)
            }
        })
    }
}
