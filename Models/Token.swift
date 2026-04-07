import Foundation

/// Token model: users start with 2 tokens, posting costs 1 token.
/// - Users can click to get 5 paid tokens (payedRefill)
/// - Users can claim 2 free tokens once per 7-day period (freeRefill)
class Token: Codable {
    /// Current available tokens
    private(set) var tokens: Int

    /// Timestamp of last successful free refill
    private var lastFreeRefillDate: Date?

    /// Configuration
    private let initialTokens = 2
    private let paidRefillAmount = 5
    private let weeklyFreeAmount = 2
    private let freeRefillInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    init() {
        self.tokens = initialTokens
        self.lastFreeRefillDate = nil
    }

    /// Use one token for posting. Returns true if successful.
    @discardableResult
    func useToken() -> Bool {
        guard tokens > 0 else { return false }
        tokens -= 1
        return true
    }

    /// Paid refill: instantly adds 5 tokens.
    func payedRefill() {
        tokens += paidRefillAmount
    }

    /// Free weekly refill: adds 2 tokens if at least 7 days have passed since last free refill.
    /// Returns true if refill applied, false if not yet available.
    @discardableResult
    func freeRefill(now: Date = Date()) -> Bool {
        if let last = lastFreeRefillDate {
            if now.timeIntervalSince(last) < freeRefillInterval {
                return false
            }
        }
        tokens += weeklyFreeAmount
        lastFreeRefillDate = now
        return true
    }

    /// Returns seconds remaining until the next free refill is available, or 0 if available now.
    func secondsUntilNextFreeRefill(now: Date = Date()) -> TimeInterval {
        guard let last = lastFreeRefillDate else { return 0 }
        let elapsed = now.timeIntervalSince(last)
        if elapsed >= freeRefillInterval { return 0 }
        return freeRefillInterval - elapsed
    }

    /// Optional: reward a single token (e.g., for achievements).
    func rewardToken() {
        tokens += 1
    }

    /// Reset tokens and free-refill timestamp (useful for tests / admin).
    func reset(tokens: Int? = nil, clearLastFreeRefill: Bool = false) {
        if let t = tokens { self.tokens = t }
        if clearLastFreeRefill { lastFreeRefillDate = nil }
    }
}
