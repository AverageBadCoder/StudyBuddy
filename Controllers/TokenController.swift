import Foundation

final class TokenController {
    func useToken(_ token: Token) -> Bool {
        token.useToken()
    }

    func paidRefill(_ token: Token) {
        token.payedRefill()
    }

    @discardableResult
    func freeRefill(_ token: Token) -> Bool {
        token.freeRefill()
    }

    func secondsUntilNextFreeRefill(_ token: Token) -> TimeInterval {
        token.secondsUntilNextFreeRefill()
    }
}