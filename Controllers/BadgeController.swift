import Foundation

final class BadgeController {
    func awardBadge(user: User, badge: ReputationBadge) -> Bool {
        let added = user.addBadge(badge)
        return added
    }

    func revokeBadge(user: User, badgeName: String, badgeType: String? = nil) -> Bool {
        if let idx = user.badges.firstIndex(where: { $0.badgeName == badgeName && (badgeType == nil || $0.badgeType == badgeType) }) {
            user.reputation -= user.badges[idx].badgeLevel
            user.badges.remove(at: idx)
            return true
        }
        return false
    }

    func updateBadge(user: User, name: String, newLevel: Int? = nil, newDescription: String? = nil) -> Bool {
        user.updateBadge(name: name, newLevel: newLevel, newDescription: newDescription)
    }
}