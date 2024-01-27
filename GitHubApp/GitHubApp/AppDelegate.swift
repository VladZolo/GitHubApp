import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var accessToken: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme == "ghclientapplication" else {
            return false
        }
        if let code = getCodeFromCallbackURL(url) {
            exchangeCodeForAccessToken(withCode: code)
        }
        return true
    }
    
    internal func getCodeFromCallbackURL(_ url: URL) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            return queryItems.first(where: { $0.name == "code" })?.value
        }
        return nil
    }
    
    internal func exchangeCodeForAccessToken(withCode code: String) {
        let clientId = "Iv1.27c6e516dc281d35"
        let clientSecret = "ba7941b011ab8dc5aa0969d7df96a25b996811bd"
        let tokenUrl = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let accessToken = json["access_token"] as? String {
                        self?.accessToken = accessToken
                    } else {
                        print("Access token not found in JSON response.")
                    }
                } else {
                    print("Failed to parse JSON response.")
                }
            } else {
                self?.handleAPIError(error)
            }
        }.resume()
    }
    
    private func handleAPIError(_ error: Error?) {
        if let error = error {
            print("API Request Error: \(error)")
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
}
