import UIKit
import AuthenticationServices

class LoginViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    
    override func viewDidLoad() {
        navigationController?.navigationBar.isHidden = true
    }
    
    private func requestUserAuthorization() {
        let clientId = "Iv1.27c6e516dc281d35"
        let authorizationUrl = "https://github.com/login/oauth/authorize?client_id=\(clientId)"
        
        if let url = URL(string: authorizationUrl) {
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "ghclientapplication") { callbackURL, error in
                if let callbackURL = callbackURL {
                    if let code = (UIApplication.shared.delegate as? AppDelegate)?.getCodeFromCallbackURL(callbackURL) {
                        (UIApplication.shared.delegate as? AppDelegate)?.exchangeCodeForAccessToken(withCode: code)
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "tabBar", sender: nil)
                        }
                    } else {
                        print("Failed to extract code from callback URL.")
                    }
                } else {
                    self.handleAuthenticationError(error)
                }
            }
            session.presentationContextProvider = self
            session.start()
        } else {
            print("Unable to open the GitHub authorization URL.")
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
    
    private func handleAuthenticationError(_ error: Error?) {
        if let error = error {
            print("Authentication Error: \(error)")
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        requestUserAuthorization()
    }
}
