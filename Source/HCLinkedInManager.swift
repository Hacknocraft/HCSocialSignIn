//
//  HCLinkedInManager.swift
//  HCSocialSignIn
//
//  Created by Lebron on 02/06/2017.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import Alamofire

public let defaultScopes = ["r_basicprofile", "r_emailaddress"]
public let defaultPermissions = ["r_basicprofile", "r_emailaddress"]

open class HCLinkedInManager: NSObject {

    open static let sharedInstance = HCLinkedInManager()

    open var key: String?
    open var secret: String?
    open var redirectUrl: String?

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
        validateProperties()
        let linkedInWebVC = LinkedInWebViewController(scopes: scopes,
                                                      completionHandler: completion)
        let nav = UINavigationController(rootViewController: linkedInWebVC)
        viewController.present(nav, animated: true, completion: nil)
    }

    /// Fetch the current user's profile
    ///
    /// - Parameters:
    ///   - parameters: parameters in the profile that you wish to fetch
    ///   - completion: the completion block
    open func fetchCurrentProfileInfo(parameters: [String]? = nil,
                                      completion: ((_ profile: [String: Any]?, _ error: Error?) -> Void)?) {
        validateProperties()

        var targetUrlString = ""
        if let params = parameters, params != [] {
            targetUrlString = "https://api.linkedin.com/v1/people/~:(\(params.joined(separator: ",")))?format=json"
        } else {
            targetUrlString = "https://api.linkedin.com/v1/people/~?format=json"
        }

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

    // MARK: - Private methods

    private func isLinkedInAppInstalled() -> Bool {
        if let url = URL(string: "linkedin://") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }

    private func isLinkedInFrameworkLinked() -> Bool {
        if let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
            let className = "\(appName).LISDKSessionManager"
            return NSClassFromString(className) != nil
        } else {
            return false
        }
    }

    private func convertStringToJson(_ string: String) -> [String: Any]? {
        if let data = string.data(using: .utf8, allowLossyConversion: true),
            let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
            return json
        } else {
            return nil
        }
    }

    private func validateProperties() {

        if let key = key {
            assert(!key.isEmpty, "key can't be empty")
        }

        if let secret = secret {
            assert(!secret.isEmpty, "secret can't be empty")
        }

        if let redirectUrl = redirectUrl {
            assert(!redirectUrl.isEmpty, "redirectUrl can't be empty")
        }
    }
}
