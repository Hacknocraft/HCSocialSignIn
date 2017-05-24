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

        let handled = FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                            open: url,
                                                                            sourceApplication: sourceApplication,
                                                                            annotation: annotation)

        return handled
    }

}
