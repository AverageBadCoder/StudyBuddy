class ReputationBadge: Codable {
    var badgeLevel: Int
    var badgeName: String
    var badgeDescription: String
    var badgeIcon: String
    var badgeType: String

    init(badgeLevel: Int = 0,
         badgeName: String = "",
         badgeDescription: String = "",
         badgeIcon: String = "",
         badgeType: String = "") {
        self.badgeLevel = badgeLevel
        self.badgeName = badgeName
        self.badgeDescription = badgeDescription
        self.badgeIcon = badgeIcon
        self.badgeType = badgeType
    }
}