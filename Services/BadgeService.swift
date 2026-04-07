import Foundation

final class BadgeService {
    func awardBadge(_ badge: ReputationBadge, to user: User) -> Bool {
        user.addBadge(badge)
    }

    func revokeBadge(named name: String, type: String? = nil, from user: User) -> Bool {
        if let idx = user.badges.firstIndex(where: { $0.badgeName == name && (type == nil || $0.badgeType == type) }) {
            user.reputation -= user.badges[idx].badgeLevel
            user.badges.remove(at: idx)
            return true
        }
        return false
    }

    func evaluateAndAward(for user: User, trigger: String) -> Bool {
        // Placeholder: sample rule — first answer posted awards +1 badge
        if trigger == "firstAnswer", user.answers.count == 1 {
            let b = ReputationBadge(badgeLevel: 1, badgeName: "First Answer", badgeDescription: "Posted first answer", badgeIcon: "⭐", badgeType: "milestone")
            return awardBadge(b, to: user)
        }
        return false
    }
}
```// filepath: /Users/c26jm/StudyBuddy/Services/BadgeService.swift
import Foundation

final class BadgeService {
    func awardBadge(_ badge: ReputationBadge, to user: User) -> Bool {
        user.addBadge(badge)
    }

    func revokeBadge(named name: String, type: String? = nil, from user: User) -> Bool {
        if let idx = user.badges.firstIndex(where: { $0.badgeName == name && (type == nil || $0.badgeType == type) }) {
            user.reputation -= user.badges[idx].badgeLevel
            user.badges.remove(at: idx)
            return true
        }
        return false
    }

    func evaluateAndAward(for user: User, trigger: String) -> Bool {
        // Placeholder: sample rule — first answer posted awards +1 badge
        if trigger == "firstAnswer", user.answers.count == 1 {
            let b = ReputationBadge(badgeLevel: 1, badgeName: "First Answer", badgeDescription: "Posted first answer", badgeIcon: "⭐", badgeType: "milestone")
            return awardBadge(b, to: user)
        }
        return false
    }