//
//  LinkedInWebViewController.swift
//  HCSocialSignIn
//
//  Created by Lebron on 05/06/2017.
//  Copyright © 2017 Hacknocraft. All rights reserved.
//

import UIKit
import Alamofire

private let authorizationEndPoint = "https://www.linkedin.com/oauth/v2/authorization"
private let accessTokenEndPoint = "https://www.linkedin.com/oauth/v2/accessToken"

class LinkedInWebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    let linkedInKey: String
    let linkedInSecret: String
    let redirectUrl: String
    let scope: [String]
    let completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?

    // MARK: - Initializers

    init(nibName nibNameOrNil: String?,
         bundle nibBundleOrNil: Bundle?,
         key: String,
         secret: String,
         redirectUrl: String,
         scope: [String],
         completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?) {
        self.linkedInKey = key
        self.linkedInSecret = secret
        self.redirectUrl = redirectUrl
        self.scope = scope
        self.completionHandler = completionHandler
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        spinner.startAnimating()

        title = "Login with LinkedIn"
        let leftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVC))
        navigationItem.leftBarButtonItem = leftButton

        startAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func dismissVC() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Request methods

    private func startAuthorization() {
        var authorizationURL = "\(authorizationEndPoint)?"
        authorizationURL += "response_type=code&"
        authorizationURL += "client_id=\(linkedInKey)&"

        if let url = redirectUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            authorizationURL += "redirect_uri=\(url)&"
        }

        let state = "linkedin\(Int(NSDate().timeIntervalSince1970))"
        authorizationURL += "state=\(state)&"

        authorizationURL += "scope=\(scope.joined(separator: "%2C"))"

        if let url = URL(string: authorizationURL) {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        } else {
            completionHandler?(false, LoginError.urlError)
        }
    }

    func requestForAccessToken(_ authorizationCode: String) {

        guard let accessTokenUrl = URL(string: accessTokenEndPoint) else {
            return
        }

        guard let redirectUrl = redirectUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return
        }

        let params = [
            "grant_type": "authorization_code",
            "code": "\(authorizationCode)",
            "redirect_uri": redirectUrl,
            "client_secret": "\(linkedInSecret)",
            "client_id": "\(linkedInKey)"
        ]

        Alamofire.request(accessTokenUrl,
                          method: .post,
                          parameters: params)
            .responseJSON(completionHandler: { (response) in

                if let json = response.result.value as? [String: Any],
                    let accessToken = json["access_token"] as? String {
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true

                    UserDefaults.standard.set(accessToken, forKey: "LIAccessToken")
                    UserDefaults.standard.synchronize()

                    DispatchQueue.main.async {
                        self.dismissVC()
                    }

                    self.completionHandler?(true, nil)
                } else {
                    self.completionHandler?(false, response.error)
                }
            })
    }

    // MARK: - UIWebViewDelegate

    func webView(_ webView: UIWebView,
                 shouldStartLoadWith request: URLRequest,
                 navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {
            return false
        }

        if url.absoluteString.hasPrefix(redirectUrl),
            url.absoluteString.range(of: "code") != nil {

            let urlParts = url.absoluteString.components(separatedBy: "&")
            if let code = urlParts.first?.components(separatedBy: "=")[1] {
                spinner.startAnimating()
                spinner.isHidden = false

                requestForAccessToken(code)
            }
            return false
        } else if url.absoluteString.contains("cancel") { // user cancel authorization
            completionHandler?(false, LoginError.cancelError)
            self.dismissVC()
            return false
        }

        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        spinner.stopAnimating()
        spinner.isHidden = true
    }
}

// MARK: - LoginError

fileprivate struct LoginError {
    static let urlError = NSError(domain: "",
                                  code: 0,
                                  userInfo: ["localizedDescription": "incorrect url"]) as Error
    static let cancelError = NSError(domain: "",
                                     code: 0,
                                     userInfo: ["localizedDescription": "user canceled authorization"]) as Error
}
