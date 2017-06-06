//
//  HCLinkedInManager.swift
//  HCSocialSignIn
//
//  Created by Lebron on 02/06/2017.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import Alamofire

open class HCLinkedInManager: NSObject {

    open static let sharedInstance = HCLinkedInManager()

    func login(viewController: UIViewController,
               key: String,
               secret: String, redirectUrl: String,
               scope: [String],
               completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?) {

        if isLinkedinAppInstalled() { // login via LinkedIn app
            LISDKSessionManager.createSession(withAuth: [LISDK_BASIC_PROFILE_PERMISSION],
                                              state: nil,
                                              showGoToAppStoreDialog: true,
                                              successBlock: { (_) in

                completionHandler?(true, nil)

            }) { (error) in

                completionHandler?(false, error)
            }

        } else {  // login via webView

            let linkedInWebVC = LinkedInWebViewController(nibName: "LinkedInWebViewController",
                                                          bundle: nil,
                                                          key: key,
                                                          secret: secret,
                                                          redirectUrl: redirectUrl,
                                                          scope: scope,
                                                          completionHandler: completionHandler)
            let nav = UINavigationController(rootViewController: linkedInWebVC)
            viewController.present(nav, animated: true, completion: nil)
        }
    }

    open func fetchCurrentProfileInfo(parameters: [String]? = nil,
                                      complete: ((_ profile: [String: Any]?, _ error: Error?) -> Void)?) {
        var targetUrlString = ""
        if let params = parameters {
            targetUrlString = "https://api.linkedin.com/v1/people/~:(\(params.joined(separator: ",")))?format=json"
        } else {
            targetUrlString = "https://api.linkedin.com/v1/people/~?format=json"
        }

        if LISDKSessionManager.hasValidSession() {

            LISDKAPIHelper.sharedInstance().getRequest(targetUrlString, success: { (response) in

                if let res = response, res.statusCode == 200, let json = res.headers as? [String: Any] {
                    complete?(json, nil)
                }

            }, error: { (error) in

                complete?(nil, error)
            })

        } else {

            guard let token = UserDefaults.standard.object(forKey: "LIAccessToken") as? String else {
                return
            }

            guard let url = URL(string: targetUrlString) else {
                return
            }

            Alamofire.request(url, headers: ["Authorization": token])
                .responseJSON(completionHandler: { (response) in

                    if let json = response.result.value as? [String: Any] {
                        complete?(json, nil)
                    } else {
                        complete?(nil, response.error)
                    }
                })
        }
    }

    func isLinkedinAppInstalled() -> Bool {
        if let url = URL(string: "linkedin://") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
}
