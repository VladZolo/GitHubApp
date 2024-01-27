import Foundation

struct User: Decodable {
    let username: String
    let name: String?
    let profileImageURL: URL?
    var followers: [User] = []
    var following: [User] = []
    var followerCount: Int = 0
    var followingCount: Int = 0
    var repositoriesCount: Int = 0
    var starredRepositoriesCount: Int = 0
    var isFollowing: Bool?
}
