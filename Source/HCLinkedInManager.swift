//
//  HCLinkedInManager.swift
//  HCSocialSignIn
//
//  Created by Lebron on 02/06/2017.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import Alamofire

private let defaultScopes = ["r_basicprofile", "r_emailaddress"]
private let defaultPermissions = [LISDK_BASIC_PROFILE_PERMISSION, LISDK_EMAILADDRESS_PERMISSION]

open class HCLinkedInManager: NSObject {

    open let key: String
    open let secret: String
    open let redirectUrl: String

    public init(key: String, secret: String, redirectUrl: String) {
        self.key = key
        self.secret = secret
        self.redirectUrl = redirectUrl
    }

    /// login via LinkedIn
    ///
    /// - Parameters:
    ///   - viewController: controller where you are logging in from
    ///   - scopes: the permissions you want to request from the user, used when login via OAuth
    ///   - permissions: the permissions you want to request from the user used when login via LinkedIn app
    ///   - completion: completion block
    open func login(viewController: UIViewController,
                    scopes: [String] = defaultScopes,
                    permissions: [String] = defaultPermissions,
                    completion: ((_ success: Bool, _ error: Error?) -> Void)?) {

        if isLinkedinAppInstalled() { // login via LinkedIn app
            LISDKSessionManager.createSession(withAuth: permissions,
                                              state: nil,
                                              showGoToAppStoreDialog: false,
                                              successBlock: { (_) in
                                                completion?(true, nil)

            }) { (error) in
                completion?(false, error)
            }

        } else {  // login via webView

            let linkedInWebVC = LinkedInWebViewController(key: key,
                                                          secret: secret,
                                                          redirectUrl: redirectUrl,
                                                          scopes: scopes,
                                                          completionHandler: completion)
            let nav = UINavigationController(rootViewController: linkedInWebVC)
            viewController.present(nav, animated: true, completion: nil)
        }
    }

    /// Fetch the current user's profile
    ///
    /// - Parameters:
    ///   - parameters: parameters in the profile that you wish to fetch
    ///   - completion: the completion block
    open func fetchCurrentProfileInfo(parameters: [String]? = nil,
                                      completion: ((_ profile: [String: Any]?, _ error: Error?) -> Void)?) {
        var targetUrlString = ""
        if let params = parameters, params != [] {
            targetUrlString = "https://api.linkedin.com/v1/people/~:(\(params.joined(separator: ",")))?format=json"
        } else {
            targetUrlString = "https://api.linkedin.com/v1/people/~?format=json"
        }

        if LISDKSessionManager.hasValidSession() {

            LISDKAPIHelper.sharedInstance().getRequest(targetUrlString, success: { (response) in

                if let res = response, res.statusCode == 200 {

                    let json = self.convertStringToJson(res.data)
                    DispatchQueue.main.async {
                        completion?(json, nil)
                    }
                }

            }, error: { (error) in

                DispatchQueue.main.async {
                    completion?(nil, error)
                }
            })

        } else {

            guard let token = UserDefaults.standard.object(forKey: "LIAccessToken") as? String else {
                return
            }

            guard let url = URL(string: targetUrlString) else {
                return
            }

            Alamofire.request(url, headers: ["Authorization": "Bearer \(token)"])
                .responseJSON(completionHandler: { (response) in

                    if let json = response.result.value as? [String: Any] {
                        completion?(json, nil)
                    } else {
                        completion?(nil, response.error)
                    }
                })
        }
    }

    private func isLinkedinAppInstalled() -> Bool {
        if let url = URL(string: "linkedin://") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }

    private func convertStringToJson(_ string: String) -> [String: Any]? {
        if let data = string.data(using: .utf8, allowLossyConversion: true),
            let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
            return json
        } else {
            return nil
        }
    }
}
