import UIKit

class ProfileViewController: UIViewController {
    
    var user: User?
    var isCurrentUserProfile: Bool = false
    var selectedUser: User?
    
    @IBOutlet weak var profileLogoView: UIImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileUsernameLabel: UILabel!
    @IBOutlet weak var followUnfollowButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var repositoriesButtonLabel: UIButton!
    @IBOutlet weak var starredRepositoriesLabel: UIButton!
    @IBOutlet weak var logoutButtonLabel: UIButton!
    
    enum UserListType {
        case Followers
        case Following
        case Search
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "ProfileViewController", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        self.view = view
        if let user = selectedUser {
            let userName = user.username
            fetchSelectedUserProfile(url: "https://api.github.com/users/\(userName)")
        } else {
            fetchUserProfile(url: "https://api.github.com/user")
        }
    }
    
    func getRequestTemplate(accessToken: String, url: String) -> URLRequest {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func getUserProfile(url: String, accessToken: String, completion: @escaping (User?) -> Void) {
        let request = getRequestTemplate(accessToken: accessToken, url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let username = json["login"] as? String
                        let name = json["name"] as? String
                        let profileImageURLString = json["avatar_url"] as? String
                        let profileImageURL = URL(string: profileImageURLString ?? "")
                        let followersCount = json["followers"] as? Int ?? 0
                        let followingCount = json["following"] as? Int ?? 0
                        let user = User(username: username ?? "", name: name, profileImageURL: profileImageURL, followerCount: followersCount, followingCount: followingCount)
                        completion(user)
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                    completion(nil)
                }
            } else if let error = error {
                print("Error fetching user profile: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func fetchRepositoriesCount(url: String, accessToken: String, completion: @escaping (Int?) -> Void) {
        var totalCount = 0
        var page = 1
        
        func fetchRepositoriesPage() {
            let urlString = "\(url)?page=\(page)"
            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data, error == nil {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                            totalCount += json.count
                            
                            if json.count == 30 {
                                page += 1
                                fetchRepositoriesPage()
                            } else {
                                completion(totalCount)
                            }
                        } else {
                            completion(nil)
                        }
                    } catch {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }.resume()
        }
        fetchRepositoriesPage()
    }
    
    func fetchUserProfile(url: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let accessToken = appDelegate.accessToken else {
            print("Access token not available.")
            return
        }
        getUserProfile(url: url, accessToken: accessToken) { [weak self] user in
            
            self?.user = user
            self?.isCurrentUserProfile = true
            self?.updateUI(user: self?.user)
            
            self?.fetchRepositoriesCount(url: "\(url)/repos", accessToken: accessToken) { count in
                self?.user?.repositoriesCount = count ?? 0
                self?.updateUI(user: self?.user)
            }
            
            self?.fetchRepositoriesCount(url: "\(url)/starred", accessToken: accessToken) { count in
                self?.user?.starredRepositoriesCount = count ?? 0
                self?.updateUI(user: self?.user)
            }
            
            self?.listOfFollowingOrFollowerUsers(url: "\(url)/following", accessToken: accessToken) { followingUsers in
                self?.user?.following = followingUsers ?? []
                self?.updateUI(user: self?.user)
            }
            
            self?.listOfFollowingOrFollowerUsers(url: "\(url)/followers", accessToken: accessToken) { followerUsers in
                self?.user?.followers = followerUsers ?? []
                self?.updateUI(user: self?.user)
            }
        }
    }
    
    func fetchSelectedUserProfile(url: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let accessToken = appDelegate.accessToken else {
            print("Access token not available.")
            return
        }
        getUserProfile(url: url, accessToken: accessToken) { [weak self] user in
            self?.selectedUser = user
            self?.isCurrentUserProfile = false
            if let currentUser = self?.user, let selectedUser = user?.username,
                      currentUser.following.contains(where: { $0.username == selectedUser }) {
                       self?.selectedUser?.isFollowing = true
                   }
            self?.updateUI(user: self?.selectedUser)
            
            self?.fetchRepositoriesCount(url: "\(url)/repos", accessToken: accessToken) { count in
                self?.selectedUser?.repositoriesCount = count ?? 0
                self?.updateUI(user: self?.selectedUser)
            }
            
            self?.fetchRepositoriesCount(url: "\(url)/starred", accessToken: accessToken) { count in
                self?.selectedUser?.starredRepositoriesCount = count ?? 0
                self?.updateUI(user: self?.selectedUser)
            }
            
            self?.listOfFollowingOrFollowerUsers(url: "\(url)/following", accessToken: accessToken) { followingUsers in
                self?.selectedUser?.following = followingUsers ?? []
                self?.updateUI(user: self?.selectedUser)
            }
            
            self?.listOfFollowingOrFollowerUsers(url: "\(url)/followers", accessToken: accessToken) { followerUsers in
                self?.selectedUser?.followers = followerUsers ?? []
                self?.updateUI(user: self?.selectedUser)
            }
        }
    }

    func listOfFollowingOrFollowerUsers(url: String, accessToken: String, completion: @escaping ([User]?) -> Void) {
        let request = getRequestTemplate(accessToken: accessToken, url: url)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        let dispatchGroup = DispatchGroup()
                        var followingOrFollowerUsers: [User] = []

                        for item in jsonArray {
                            let username = item["login"] as? String
                            let avatarURLString = item["avatar_url"] as? String
                            let avatarURL = URL(string: avatarURLString ?? "")
                            if let username = username {
                                dispatchGroup.enter()
                                self.fetchFollowersCountOfFollowingOrFollowerUser(username: username, accessToken: accessToken) { followersCount in
                                    let user = User(username: username, name: nil, profileImageURL: avatarURL, followerCount: followersCount)
                                    followingOrFollowerUsers.append(user)
                                    dispatchGroup.leave()
                                }
                            }
                        }
                        dispatchGroup.notify(queue: .main) {
                            completion(followingOrFollowerUsers)
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                    completion(nil)
                }
            } else if let error = error {
                print("Error fetching following users: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func fetchFollowersCountOfFollowingOrFollowerUser(username: String, accessToken: String, completion: @escaping (Int) -> Void) {
        let request = getRequestTemplate(accessToken: accessToken, url: "https://api.github.com/users/\(username)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let followersCount = json["followers"] as? Int {
                        completion(followersCount)
                    } else {
                        print("Invalid JSON response.")
                        completion(0)
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                    completion(0)
                }
            } else if let error = error {
                print("Error fetching followers count: \(error)")
                completion(0)
            }
        }.resume()
    }
    
//    func checkIfCurrentUserProfile() -> Bool {
//        return self.user?.username == user?.username
//    }
    
    func updateUI(user: User?) {
        DispatchQueue.main.async { [weak self] in
            self?.profileNameLabel.text = user?.name
            self?.profileUsernameLabel.text = user?.username
            
            if let profileImageURL = user?.profileImageURL {
                self?.loadProfileImage(from: profileImageURL)
            }
            self?.profileLogoView.layer.cornerRadius = (self?.profileLogoView.bounds.width ?? 80) / 2.0
            self?.profileLogoView.clipsToBounds = true
            self?.profileLogoView.layer.borderWidth = 0.5
            self?.profileLogoView.layer.borderColor = UIColor.black.cgColor
            self?.followUnfollowButton.isHidden = self?.isCurrentUserProfile ?? false
            self?.settingsButton.isHidden = !(self?.isCurrentUserProfile ?? false)
            self?.logoutButtonLabel.isHidden = !(self?.isCurrentUserProfile ?? false)
            
            if let followerCount = user?.followerCount {
                self?.followersButton.setTitle(" \(followerCount) followers", for: .normal)
            } else {
                self?.followersButton.setTitle(" 0 followers", for: .normal)
            }
            if let followingCount = user?.followingCount {
                self?.followingButton.setTitle(" \(followingCount) following", for: .normal)
            } else {
                self?.followingButton.setTitle(" 0 following", for: .normal)
            }
            if let repositoriesCount = user?.repositoriesCount {
                self?.repositoriesButtonLabel.setTitle("Repositories: \(repositoriesCount)", for: .normal)
            } else {
                self?.repositoriesButtonLabel.setTitle("Repositories: 0", for: .normal)
            }
            if let starredRepositoriesCount = user?.starredRepositoriesCount {
                self?.starredRepositoriesLabel.setTitle("Starred: \(starredRepositoriesCount)", for: .normal)
            } else {
                self?.starredRepositoriesLabel.setTitle("Starred: 0", for: .normal)
            }
            if let user = user {
                if user.isFollowing ?? false {
                            self?.followUnfollowButton.setTitle("Unfollow", for: .normal)
                        } else {
                            self?.followUnfollowButton.setTitle("Follow", for: .normal)
                        }
                    }
        }
    }
    
    func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileLogoView.image = image
                }
            } else {
                print("Error loading profile image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
//    func followUser(user: User?) {
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        guard let username = user?.username,
//              let accessToken = appDelegate.accessToken else {
//            return
//        }
//
//        let followURLString = "https://api.github.com/user/following/\(username)"
//        var request = URLRequest(url: URL(string: followURLString)!)
//        request.httpMethod = "PUT"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error following user: \(error)")
//            } else {
//                // Update user's following status and UI
//                self.selectedUser?.isFollowing = true
//                DispatchQueue.main.async {
//                    self.updateUI(user: self.selectedUser)
//                }
//            }
//        }.resume()
//    }
//
//    func unfollowUser(user: User?) {
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        guard let username = user?.username,
//              let accessToken = appDelegate.accessToken else {
//            return
//        }
//
//        let unfollowURLString = "https://api.github.com/user/following/\(username)"
//        var request = URLRequest(url: URL(string: unfollowURLString)!)
//        request.httpMethod = "DELETE"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error unfollowing user: \(error)")
//            } else {
//                // Update user's following status and UI
//                self.selectedUser?.isFollowing = false
//                DispatchQueue.main.async {
//                    self.updateUI(user: self.selectedUser)
//                }
//            }
//        }.resume()
//    }

    @IBAction func repositoriesButtonTapped(_ sender: Any) {
    }
    @IBAction func starredButtonTapped(_ sender: Any) {
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.accessToken = nil
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    @IBAction func followUnfollowButtonTapped(_ sender: UIButton) {
//        guard let user = selectedUser else {
//                return
//            }
//
//            if user.isFollowing {
//                unfollowUser(user: user)
//            } else {
//                followUser(user: user)
//            }
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func followersButtonTapped(_ sender: Any) {
        if let user = selectedUser {
            let followerUsers = user.followers
            openUserListScene(users: followerUsers, listType: .Followers)
        } else {
            guard let followerUsers = user?.followers else {
                return
            }
            openUserListScene(users: followerUsers, listType: .Followers)
        }
    }
    
    @IBAction func followingButtonTapped(_ sender: Any) {
        if let user = selectedUser {
            let followingUsers = user.following
            openUserListScene(users: followingUsers, listType: .Following)
        } else {
            guard let followingUsers = user?.following else {
                return
            }
            openUserListScene(users: followingUsers, listType: .Following)
        }
    }
    
    private func openUserListScene(users: [User], listType: UserListType) {
        let userListViewController = UserListViewController(users: users, listType: listType)
        self.navigationController?.pushViewController(userListViewController, animated: true)
    }
}
