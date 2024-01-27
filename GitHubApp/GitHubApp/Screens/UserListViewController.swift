import UIKit

class UserListViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var users: [User]
    private let listType: ProfileViewController.UserListType
    
    init(users: [User], listType: ProfileViewController.UserListType) {
        self.users = users
        self.listType = listType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        title = "\(listType)"
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: UserTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func userSelected(_ user: User) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController {
            profileViewController.selectedUser = user
            navigationController?.pushViewController(profileViewController, animated: true)
            navigationController?.navigationBar.isHidden = false
        }
    }
    
    @IBAction func sortAlphabeticallyTapped(_ sender: Any) {
        users.sort { $0.username.lowercased() < $1.username.lowercased() }
        tableView.reloadData()
    }
    @IBAction func sortByFollowersCountTapped(_ sender: Any) {
        users.sort { $0.followerCount > $1.followerCount }
        tableView.reloadData()
    }
    @IBAction func fromZeroRangeTapped(_ sender: Any) {
        users = users.filter { $0.followerCount <= 100 }
        users.shuffle()
        tableView.reloadData()
    }
    @IBAction func fromHundredRangeTapped(_ sender: Any) {
        users = users.filter { $0.followerCount >= 100 && $0.followerCount <= 1000 }
        users.shuffle()
        tableView.reloadData()
    }
    @IBAction func fromThousandRangeTapped(_ sender: Any) {
        users = users.filter { $0.followerCount >= 1000 }
        users.shuffle()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension UserListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let user = users[indexPath.row] 
            userSelected(user)
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.identifier, for: indexPath) as! UserTableViewCell

        let user = users[indexPath.row]
        cell.usernameLabel.text = user.username
        cell.followerCountLabel.text = "\(user.followerCount) followers"
        
        if let profileImageURL = user.profileImageURL {
            cell.loadProfileImage(from: profileImageURL)
        }
        cell.profileLogoView.layer.cornerRadius = (cell.profileLogoView.bounds.width) / 2.0
        cell.profileLogoView.clipsToBounds = true
        cell.profileLogoView.layer.borderWidth = 0.2
        cell.profileLogoView.layer.borderColor = UIColor.black.cgColor
        
        return cell
    }
}
