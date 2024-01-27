import UIKit

class UserTableViewCell: UITableViewCell {
    
    static let identifier = "UserTableViewCell"
    static let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
    
    @IBOutlet weak var profileLogoView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!

    func configure(with user: User) {
        usernameLabel.text = user.username 
        followerCountLabel.text = "\(user.followerCount) followers"

        if let profileImageURL = user.profileImageURL {
            loadProfileImage(from: profileImageURL)
        }
    }

    internal func loadProfileImage(from url: URL) {
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
}
