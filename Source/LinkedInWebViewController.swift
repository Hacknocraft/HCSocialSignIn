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

    var webView: UIWebView!
    var spinner: UIActivityIndicatorView!

    let scopes: [String]
    let completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?

    // MARK: - Initializers

    init(scopes: [String],
         completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?) {
        self.scopes = scopes
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = UIWebView()
        webView.delegate = self
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|",
                                                                   options: .directionLeadingToTrailing,
                                                                   metrics: nil,
                                                                   views: ["webView": webView])
        view.addConstraints(horizontalConstraints)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|",
                                                                 options: .directionLeadingToTrailing,
                                                                 metrics: nil,
                                                                 views: ["webView": webView])
        view.addConstraints(verticalConstraints)

        spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)

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

        let linkedInManager = HCLinkedInManager.sharedInstance
        guard let key = linkedInManager.key,
            let redirectUrl = linkedInManager.redirectUrl else {
                return
        }

        var authorizationURL = "\(authorizationEndPoint)?"
        authorizationURL += "response_type=code&"
        authorizationURL += "client_id=\(key)&"

        if let url = redirectUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            authorizationURL += "redirect_uri=\(url)&"
        }

        let state = "linkedin\(Int(NSDate().timeIntervalSince1970))"
        authorizationURL += "state=\(state)&"

        authorizationURL += "scope=\(scopes.joined(separator: "%2C"))"

        if let url = URL(string: authorizationURL) {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        } else {
            completionHandler?(false, LoginError.urlError)
        }
    }

    private func requestForAccessToken(_ authorizationCode: String) {

        guard let accessTokenUrl = URL(string: accessTokenEndPoint) else {
            return
        }

        let linkedInManager = HCLinkedInManager.sharedInstance
        guard let key = linkedInManager.key,
            let redirectUrl = linkedInManager.redirectUrl,
            let secret = linkedInManager.secret else {
                return
        }

        let params = [
            "grant_type": "authorization_code",
            "code": "\(authorizationCode)",
            "redirect_uri": redirectUrl,
            "client_secret": "\(secret)",
            "client_id": "\(key)"
        ]

        Alamofire.request(accessTokenUrl,
                          method: .post,
                          parameters: params,
                          headers: ["Content-Type": "application/x-www-form-urlencoded"])
            .responseJSON(completionHandler: { (response) in

                if let json = response.result.value as? [String: Any],
                    let accessToken = json["access_token"] as? String {

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

        guard let url = request.url,
            let redirectUrl = HCLinkedInManager.sharedInstance.redirectUrl else {
                return false
        }

        if url.absoluteString.hasPrefix(redirectUrl),
            url.absoluteString.range(of: "code") != nil,
            let code = getQueryStringParameter(url: url.absoluteString, param: "code") {

            requestForAccessToken(code)
            return false

        } else if url.path.contains("authorization-cancel") ||
            url.path.contains("login-cancel") { // user cancel authorization

            completionHandler?(false, LoginError.cancelError)
            self.dismissVC()
            return false
        }

        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }

    // MARK: - Private methods

    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let components = URLComponents(string: url) else { return nil }
        return components.queryItems?.first(where: { $0.name == param })?.value
    }

}

// MARK: - LoginError

fileprivate struct LoginError {
    static let urlError = NSError(domain: "",
                                  code: 0,
                                  userInfo: ["localizedDescription": "incorrect url"]) as Error
    static let cancelError = NSError(domain: "",
                                     code: 0,
                                     userInfo: ["localizedDescription": "user canceled"]) as Error
}
