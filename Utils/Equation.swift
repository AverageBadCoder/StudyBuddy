import Foundation

/// Advanced Equation formatter/parser for college use.
/// - Parses arithmetic, parentheses, functions (sqrt, sin, cos, tan, log, ln, exp, frac),
///   implicit multiplication (e.g., 2x, 2(x+1)), unary minus, and exponentiation (^).
/// - Produces output in three modes: unicode, latex, ascii.
/// - Does NOT evaluate expressions by default; set `evaluateNumeric` to true to collapse numeric-only expressions.
/// - Returns formatted string or throws a parse error.
public enum EquationError: Error {
    case parseError(String)
    case emptyInput
}

public struct EquationFormatter {
    public enum Mode { case unicode, latex, ascii }
    public init() {}

    public func format(_ input: String, mode: Mode = .unicode, evaluateNumeric: Bool = false) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw EquationError.emptyInput }
        let tokens = try Tokenizer().tokenize(trimmed)
        let tokensWithImplicit = Tokenizer.insertImplicitMultiplication(tokens)
        let rpn = try ShuntingYard().toRPN(tokensWithImplicit)
        let ast = try ASTBuilder().build(rpn)
        if evaluateNumeric, let val = ast.evaluate(values: [:]) {
            // present evaluated numeric result in requested mode
            switch mode {
            case .ascii: return "\(val)"
            case .unicode: return prettyNumber(val)
            case .latex: return String(format: "%.10g", val)
            }
        }
        switch mode {
        case .ascii: return ast.toAscii()
        case .unicode: return ast.toUnicode()
        case .latex: return ast.toLaTeX()
        }
    }

    // Small pretty numeric formatter
    private func prettyNumber(_ v: Double) -> String {
        if v == floor(v) { return String(Int(v)) }
        return String(format: "%g", v)
    }
}

// MARK: - Tokenizer

fileprivate enum Tok {
    case number(Double)
    case ident(String)     // variables or function names
    case op(String)        // + - * / ^ , 
    case lparen, rparen
}

fileprivate struct Tokenizer {
    private let input: [Character]
    private var idx: Int = 0
    init(_ s: String = "") { self.input = Array(s) }

    func tokenize(_ s: String) throws -> [Tok] {
        var toks: [Tok] = []
        var i = 0
        let chars = Array(s)
        func peek(_ offset: Int = 0) -> Character? { (i+offset) < chars.count ? chars[i+offset] : nil }

        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace { i += 1; continue }
            if c.isNumber || (c == "." && (peek(1)?.isNumber ?? false)) {
                var j = i
                var dotSeen = false
                var numStr = ""
                while j < chars.count {
                    let ch = chars[j]
                    if ch == "." {
                        if dotSeen { break }
                        dotSeen = true
                        numStr.append(".")
                    } else if ch.isNumber {
                        numStr.append(ch)
                    } else { break }
                    j += 1
                }
                if let d = Double(numStr) {
                    toks.append(.number(d))
                    i = j
                    continue
                } else {
                    throw EquationError.parseError("Invalid number at position \(i)")
                }
            }

            if c.isLetter {
                var j = i
                var id = ""
                while j < chars.count {
                    let ch = chars[j]
                    if ch.isLetter || ch.isNumber || ch == "_" { id.append(ch); j += 1 } else { break }
                }
                toks.append(.ident(id))
                i = j
                continue
            }

            switch c {
            case "+","-","*","/","^",",":
                toks.append(.op(String(c))); i += 1
            case "(":
                toks.append(.lparen); i += 1
            case ")":
                toks.append(.rparen); i += 1
            case "[":
                toks.append(.lparen); i += 1
            case "]":
                toks.append(.rparen); i += 1
            default:
                // support unicode operators like √ or × or ÷
                if c == "√" {
                    toks.append(.ident("sqrt")); i += 1
                } else if c == "×" {
                    toks.append(.op("*")); i += 1
                } else if c == "÷" {
                    toks.append(.op("/")); i += 1
                } else {
                    throw EquationError.parseError("Unexpected character '\(c)' at \(i)")
                }
            }
        }
        return toks
    }

    // Insert explicit '*' tokens where implicit multiplication was intended:
    // e.g., number followed by ident or lparen, ident followed by lparen or number, rparen followed by ident/number/lparen.
    static func insertImplicitMultiplication(_ tokens: [Tok]) -> [Tok] {
        guard !tokens.isEmpty else { return tokens }
        var out: [Tok] = []
        func isValue(_ t: Tok) -> Bool {
            switch t { case .number, .ident, .rparen: return true; default: return false }
        }
        func startsValue(_ t: Tok) -> Bool {
            switch t { case .ident, .number, .lparen: return true; default: return false }
        }
        for (i, t) in tokens.enumerated() {
            out.append(t)
            if i+1 < tokens.count {
                let a = t
                let b = tokens[i+1]
                if (isValue(a) && startsValue(b)) {
                    // e.g., 2x, 2(, )x, )(
                    out.append(.op("*"))
                }
            }
        }
        return out
    }
}

// MARK: - Shunting-yard to RPN

fileprivate class ShuntingYard {
    private let prec: [String:Int] = ["+":1,"-":1,"*":2,"/":2,"^":3]
    private let rightAssoc: Set<String> = ["^"]

    func toRPN(_ tokens: [Tok]) throws -> [Tok] {
        var output: [Tok] = []
        var ops: [Tok] = []
        for t in tokens {
            switch t {
            case .number, .ident:
                output.append(t)
            case .op(let s):
                // handle unary minus: if previous token is nil or operator or '(', then unary
                let isUnary = (s == "-") && (output.isEmpty && ops.isEmpty || {
                    // previous token was an operator or lparen
                    if let last = (output.last ?? ops.last) { return false } ; return false
                }())
                // Simpler unary handling: transform unary minus to function "neg" by scanning tokens pattern.
                if s == "-" {
                    // implement unary minus by context: if prev token is value or rparen then binary, else unary
                    let prevIsValue = { () -> Bool in
                        if let last = output.last {
                            switch last { case .number, .ident: return true; default: return false }
                        }
                        return false
                    }()
                    if !prevIsValue {
                        // push unary as ident "neg" as function
                        ops.append(.ident("neg"))
                        continue
                    }
                }
                while let top = ops.last {
                    switch top {
                    case .op(let opTop):
                        if (rightAssoc.contains(s) && (prec[s] ?? 0) < (prec[opTop] ?? 0)) ||
                           (!rightAssoc.contains(s) && (prec[s] ?? 0) <= (prec[opTop] ?? 0)) {
                            output.append(ops.removeLast())
                        } else { break }
                    case .ident:
                        // function on stack should be pushed to output when ) encountered; keep it
                        break
                    default:
                        break
                    }
                    if ops.last == top { break }
                }
                ops.append(.op(s))
            case .lparen:
                ops.append(.lparen)
            case .rparen:
                var found = false
                while let top = ops.last {
                    if case .lparen = top { ops.removeLast(); found = true; break }
                    output.append(ops.removeLast())
                }
                if !found {
                    throw EquationError.parseError("Mismatched parentheses")
                }
                // if function on top, pop to output
                if let top = ops.last, case .ident = top {
                    output.append(ops.removeLast())
                }
            }
        }
        while let top = ops.last {
            if case .lparen = top || case .rparen = top {
                throw EquationError.parseError("Mismatched parentheses")
            }
            output.append(ops.removeLast())
        }
        return output
    }
}

// MARK: - AST

fileprivate indirect enum AST {
    case number(Double)
    case variable(String)
    case unary(name: String, AST)
    case binary(name: String, AST, AST)
    case function(name: String, [AST])
}

fileprivate struct ASTBuilder {
    func build(_ rpn: [Tok]) throws -> AST {
        var stack: [AST] = []
        for t in rpn {
            switch t {
            case .number(let d): stack.append(.number(d))
            case .ident(let s):
                // treat known functions as function token marker: we will pop arguments only when function found.
                // For simplicity, treat single-argument functions and special "frac" expects 2 args.
                if s == "neg" {
                    guard let a = stack.popLast() else { throw EquationError.parseError("neg missing operand") }
                    stack.append(.unary(name: "-", a))
                } else if isFunctionName(s) {
                    // number of args: frac -> 2, others -> 1 (generalization: support n-ary with comma tokens not implemented)
                    if s == "frac" {
                        guard let b = stack.popLast(), let a = stack.popLast() else { throw EquationError.parseError("frac needs two args") }
                        stack.append(.function(name: s, [a,b]))
                    } else {
                        guard let a = stack.popLast() else { throw EquationError.parseError("\(s) missing operand") }
                        stack.append(.function(name: s, [a]))
                    }
                } else {
                    // variable
                    stack.append(.variable(s))
                }
            case .op(let s):
                guard let b = stack.popLast(), let a = stack.popLast() else { throw EquationError.parseError("binary op \(s) missing operands") }
                stack.append(.binary(name: s, a, b))
            case .lparen, .rparen:
                throw EquationError.parseError("Unexpected parenthesis in RPN")
            }
        }
        guard let root = stack.last, stack.count == 1 else {
            throw EquationError.parseError("Invalid expression")
        }
        return root
    }

    private func isFunctionName(_ s: String) -> Bool {
        let funcs = ["sqrt","sin","cos","tan","log","ln","exp","frac","abs","max","min"]
        return funcs.contains(s.lowercased())
    }
}

// MARK: - AST formatting & evaluation

fileprivate extension AST {
    func evaluate(values: [String:Double]) -> Double? {
        switch self {
        case .number(let d): return d
        case .variable(let name): return values[name]
        case .unary(let name, let a):
            guard let v = a.evaluate(values: values) else { return nil }
            switch name {
            case "-": return -v
            default: return nil
            }
        case .binary(let op, let a, let b):
            guard let va = a.evaluate(values: values), let vb = b.evaluate(values: values) else { return nil }
            switch op {
            case "+": return va + vb
            case "-": return va - vb
            case "*": return va * vb
            case "/": return va / vb
            case "^": return pow(va, vb)
            default: return nil
            }
        case .function(let name, let args):
            let lname = name.lowercased()
            let ev = args.map { $0.evaluate(values: values) }
            if ev.contains(where: { $0 == nil }) { return nil }
            let vals = ev.compactMap { $0 }
            switch lname {
            case "sqrt": return sqrt(vals[0])
            case "sin": return sin(vals[0])
            case "cos": return cos(vals[0])
            case "tan": return tan(vals[0])
            case "log": return log10(vals[0])
            case "ln": return log(vals[0])
            case "exp": return exp(vals[0])
            case "abs": return abs(vals[0])
            case "frac": return vals[0] / vals[1]
            default: return nil
            }
        }
    }

    func toAscii() -> String {
        switch self {
        case .number(let d):
            return doubleToString(d)
        case .variable(let s):
            return s
        case .unary(let name, let a):
            switch name {
            case "-": return "-" + parenthesizeIfNeeded(a)
            default: return "\(name)(\(a.toAscii()))"
            }
        case .binary(let op, let a, let b):
            return "\(parenthesizeIfNeeded(a)) \(op) \(parenthesizeIfNeeded(b))"
        case .function(let name, let args):
            if name.lowercased() == "frac", args.count == 2 {
                return "frac(\(args[0].toAscii()),\(args[1].toAscii()))"
            }
            return "\(name)(\(args.map { $0.toAscii() }.joined(separator: ",")))"
        }
    }

    func toLaTeX() -> String {
        switch self {
        case .number(let d): return doubleToString(d)
        case .variable(let s): return s
        case .unary(let name, let a):
            switch name {
            case "-": return "-\(wrapLaTeX(a))"
            default: return "\\mathrm{\(name)}(\(a.toLaTeX()))"
            }
        case .binary(let op, let a, let b):
            switch op {
            case "+","-": return "\(a.toLaTeX()) \(op) \(b.toLaTeX())"
            case "*": return "\(a.toLaTeX())\\cdot \(b.toLaTeX())"
            case "/": return "\\frac{\(a.toLaTeX())}{\(b.toLaTeX())}"
            case "^": return "{\(a.toLaTeX())}^{\(b.toLaTeX())}"
            default: return "\(a.toLaTeX()) \(op) \(b.toLaTeX())"
            }
        case .function(let name, let args):
            let lname = name.lowercased()
            switch lname {
            case "sqrt": return "\\sqrt{\(args[0].toLaTeX())}"
            case "frac" where args.count == 2: return "\\frac{\(args[0].toLaTeX())}{\(args[1].toLaTeX())}"
            case "log": return "\\log(\(args[0].toLaTeX()))"
            case "ln": return "\\ln(\(args[0].toLaTeX()))"
            case "sin","cos","tan","exp","abs":
                return "\\\(lname)(\(args[0].toLaTeX()))"
            default:
                return "\\mathrm{\(name)}(\(args.map { $0.toLaTeX() }.joined(separator: ",")))"
            }
        }
    }

    func toUnicode() -> String {
        switch self {
        case .number(let d): return doubleToString(d)
        case .variable(let s): return s
        case .unary(let name, let a):
            switch name {
            case "-": return "−" + parenthesizeIfNeeded(a)
            default: return "\(name)(\(a.toUnicode()))"
            }
        case .binary(let op, let a, let b):
            switch op {
            case "+","-": return "\(a.toUnicode()) \(op) \(b.toUnicode())"
            case "*": return "\(a.toUnicode())·\(b.toUnicode())"
            case "/":
                // prefer stacked-looking using fraction slash if simple
                if let na = a.asSimpleString(), let nb = b.asSimpleString() {
                    return "\(na)\u{2044}\(nb)" // fraction slash
                } else {
                    return "\(a.toUnicode())/\(b.toUnicode())"
                }
            case "^":
                if let exp = b.asSimpleString(), let sup = exp.unicodeSuperscript(), !sup.isEmpty {
                    return "\(a.toUnicode())\(sup)"
                } else {
                    return "\(a.toUnicode())^\(b.toUnicode())"
                }
            default: return "\(a.toUnicode()) \(op) \(b.toUnicode())"
            }
        case .function(let name, let args):
            let lname = name.lowercased()
            switch lname {
            case "sqrt": return "√(\(args[0].toUnicode()))"
            case "frac" where args.count == 2:
                if let n = args[0].asSimpleString(), let d = args[1].asSimpleString() {
                    return "\(n)\u{2044}\(d)"
                }
                return "\(args[0].toUnicode())/\(args[1].toUnicode())"
            case "log","ln","sin","cos","tan","exp","abs":
                return "\(lname)(\(args[0].toUnicode()))"
            default:
                return "\(name)(\(args.map { $0.toUnicode() }.joined(separator: ",")))"
            }
        }
    }

    // helpers
    private func parenthesizeIfNeeded(_ n: AST) -> String {
        switch n {
        case .binary: return "(\(n.toAscii()))"
        default: return n.toAscii()
        }
    }

    private func wrapLaTeX(_ n: AST) -> String {
        switch n {
        case .binary: return "\\left(\(n.toLaTeX())\\right)"
        default: return n.toLaTeX()
        }
    }

    private func doubleToString(_ d: Double) -> String {
        if d == floor(d) { return String(Int(d)) }
        return String(format: "%g", d)
    }

    // Try to produce a compact string if node is simple number or variable (no spaces/parens)
    func asSimpleString() -> String? {
        switch self {
        case .number(let d): return doubleToString(d)
        case .variable(let s): return s
        default: return nil
        }
    }
}

// MARK: - String superscript support

fileprivate extension String {
    func unicodeSuperscript() -> String? {
        let map: [Character: Character] = [
            "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹",
            "+":"⁺","-":"⁻","=":"⁼","(":"⁽",")":"⁾","n":"ⁿ"
        ]
        var out = ""
        for c in self {
            if let m = map[c] { out.append(m) } else { return nil }
        }
        return out
    }
}