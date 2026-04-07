import Foundation

protocol TokenServicing {
    func tryUseToken(_ token: Token) -> Bool
    func paidRefill(_ token: Token)
    func freeRefill(_ token: Token) -> Bool
    func secondsUntilNextFreeRefill(_ token: Token) -> TimeInterval
}

final class TokenService: TokenServicing {
    func tryUseToken(_ token: Token) -> Bool { token.useToken() }
    func paidRefill(_ token: Token) { token.payedRefill() }
    func freeRefill(_ token: Token) -> Bool { token.freeRefill() }
    func secondsUntilNextFreeRefill(_ token: Token) -> TimeInterval { token.secondsUntilNextFreeRefill() }
}