//
//  AppDelegateExtension.swift
//  HCSocialSignIn
//
//  Created by HAO WANG on 5/24/17.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import FBSDKCoreKit

extension AppDelegate {

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

        let fbHandled = FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                              open: url,
                                                                              sourceApplication: sourceApplication,
                                                                              annotation: annotation)

        if LISDKCallbackHandler.shouldHandle(url) {
            let liHandled = LISDKCallbackHandler.application(application,
                                                             open: url,
                                                             sourceApplication: sourceApplication,
                                                             annotation: annotation)
            return liHandled || fbHandled
        }

        return fbHandled
    }

}
