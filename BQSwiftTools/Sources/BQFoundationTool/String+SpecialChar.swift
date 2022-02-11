//
//  String+tool.swift
//  ShellTool
//
//  Created by Beiqi on 2021/10/19.
//

import Foundation

public enum SpecialChar: Character {
    /// /
    case slash       = "/"
    /// \
    case backslash   = "\\"
    /// '
    case singleQuote = "'"
    /// "
    case doubleQuote = "\""
    /// ,
    case comma       = ","
    
    
    /// "\a" Bell
    case a_BL = "\u{07}"  
    
    /// "\b" Backspace
    case b_BS = "\u{08}"  
    
    /// "\t" Horizontal Tab
    case t_HT = "\u{09}"  
    
    /// "\n" Line Feed / New Line
    case n_LF = "\u{0a}"  
    
    /// "\v" Vertical Tab
    case v_VT = "\u{0b}"  
    
    /// "\f" Form Feed / New Page
    case f_FF = "\u{0c}"  
    
    /// "\r" Carriage Return
    case r_CR = "\u{0d}"  
    
}

public extension SpecialChar {
    ///  alias for .n_LF
    static var newline: Self { .n_LF }
    ///  alias for .t_HT
    static var tab:     Self { .t_HT }
    ///  alias for .slash
    static var slant:   Self { .slash }
    ///  alias for .backslash
    static var escape:  Self { .backslash }
}

///  for String(SpecialChar.doubleQuote)
public let  DoubleQuote = String(.doubleQuote)




public extension String {
    
    init(_ spcs: SpecialChar ...) { self.init(spcs.map { $0.rawValue }) }
    init(_ spcs: [SpecialChar])   { self.init(spcs.map { $0.rawValue }) }
    
    mutating func append(_ s: SpecialChar ...) { append(String(s)) }
    
    
    /// eg:  hello \"star\"  =>  hello "star"
    var transformingEscapeCharacters: String {
        guard isNotEmpty else { return self }
        let backslash = SpecialChar.backslash.rawValue
        var res = String(); res.reserveCapacity(count)
        var iterator = makeIterator()
        var c = iterator.next()
        while c != nil {
            guard c == backslash else {
                res.append(c!)
                c = iterator.next()
                continue
            }
            
            let (value, peep) = iterator.detectEscapingCharacter()
            if let value = value {
                res.append(value)
            } else {
                res.append(c!)
            }
            switch peep?.count ?? 0 {
            case 0:     c = iterator.next()
            case 1:     c = peep?.last
            default:    c = peep?.last; peep?.dropLast().forEach { res.append($0) }
            }
        }
        
        return res
    }
    
    /// eg:  hello "star"  =>  hello \"star\"
    var insertingBackslashForDoubleQuotes: String { 
        guard isNotEmpty else { return self }
        var res = self
        var idx = res.endIndex
        var quoteIdx: Index?
        repeat {
            idx = res.index(before: idx)
            switch res[idx] {
            case "\"":
                quoteIdx = idx
            case "\\":
                quoteIdx = nil
            default:
                guard let tmpIdx = quoteIdx else { break }
                quoteIdx = nil
                res.insert("\\", at: tmpIdx)
            }
        } while idx != res.startIndex
        return res
    }
    
    /// "{insertingBackslashForDoubleQuotes}"
    var wrappingDoubleQuotes: String { DoubleQuote + insertingBackslashForDoubleQuotes + DoubleQuote }
    
    /// trim endian doublequotes (if it has),  then return transformingEscapeCharacters
    var trimingDoubleQuotes: String {
        switch count {
        case 0, 1:  return self
        case 2:     return self == "\"\"" ? "" : transformingEscapeCharacters
        default:    break
        }
        let c = SpecialChar.doubleQuote.rawValue
        let s0 = startIndex; let s1 = index(after: s0)
        let e0 = index(before: endIndex); let e1 = index(before: e0)
        let hasEndianQuotes = self[s0] == c && self[e0] == c && self[e1] != SpecialChar.backslash.rawValue
        return hasEndianQuotes ? String(self[s1...e1]).transformingEscapeCharacters : transformingEscapeCharacters
    }
}


// MARK: - 

enum DigitBase {
    case Oct, Hex
}

extension DigitBase {
    
    var maxDigitsCount: Int {
        switch self {
        case .Oct: return 10
        case .Hex: return 8
        }
    }
    
    func append(digit: Int, to: inout Int) {
        switch self {
        case .Oct:  to = (to << 3) + digit
        case .Hex:  to = (to << 4) + digit
        }
    }
    
    func digit(_ c: Character) -> Int? {
        guard let d = c.hexDigitValue else { return nil }
        switch self {
        case .Oct: 
            return 0 <= d && d < 8 ? d : nil
        case .Hex: 
            return d
        }
    }
}

struct DigitInfo {
    var value: Int = 0
    var chars = [Character]()
    var peep: Character?
    var failed: Bool?
    var hasInitialValue: Bool?
}

extension DigitInfo {
    
    init(initialValue: Int?) {
        guard let v = initialValue else { return }
        value = v
        hasInitialValue = true
    }
    
    func unicodeChar(prePeep: [Character]? = nil) -> (value: Character?, peep: [Character]?) {
        guard let uc = valueAsUnicodeScalar else {
            return (nil, allPeeps(prePeep, chars))
        }
        return (Character(uc), allPeeps())
    }
    
    var valueAsUnicodeScalar: Unicode.Scalar? {
        guard failed.isFalse,
              value != 0,
              chars.isNotEmpty || hasInitialValue.isTrue else { return nil }
        return Unicode.Scalar(value)
    }
    
    var isUnicodeScalarValue: Bool { valueAsUnicodeScalar != nil }
    
    private func allPeeps(_ pres: [Character]? ...) -> [Character]? {
        var res = [Character]()
        for ls in pres {
            guard let ls = ls else { continue }
            res.append(contentsOf: ls)
        }
        guard let p = peep else { return res.notEmpty }
        res.append(p)
        return res
    }
}

extension String.Iterator {
    
    mutating func detectUnicode(base: DigitBase, initial: Int? = nil, expectedEnd: Character? = nil) -> DigitInfo {
        var maxDigits = base.maxDigitsCount
        var info = DigitInfo(initialValue: initial)
        while let c = next() {
            if let d = base.digit(c) {
                base.append(digit: d, to: &info.value)
                info.chars.append(c)
            } else {
                info.peep = c
                break
            }
            maxDigits -= 1
            if maxDigits <= 0 { break }
        }
        
        if let e = expectedEnd {
            if info.peep == nil {
                info.peep = next()
            }
            if info.peep == e, info.isUnicodeScalarValue {
                info.peep = nil
            } else {
                info.failed = true
            }
        }
        return info
    }
    
    mutating func detectEscapingCharacter() -> (value: Character?, peep: [Character]?) {
        guard let c = next() else { return (nil, nil) }
        switch c {
        case "a":    return (SpecialChar.a_BL.rawValue, nil)
        case "b":    return (SpecialChar.b_BS.rawValue, nil)
        case "t":    return (SpecialChar.t_HT.rawValue, nil)
        case "n":    return (SpecialChar.n_LF.rawValue, nil)
        case "v":    return (SpecialChar.v_VT.rawValue, nil)
        case "f":    return (SpecialChar.f_FF.rawValue, nil)
        case "r":    return (SpecialChar.r_CR.rawValue, nil)
            
        case "\\", "\"", "'", "?":
            return (c, nil)
            
        case "0"..."7":
            let info = detectUnicode(base: .Oct, initial: c.hexDigitValue)
            return info.unicodeChar(prePeep: [c])
            
        case "x":
            let info = detectUnicode(base: .Hex)
            return info.unicodeChar(prePeep: [c])
            
        case "u":
            guard let c2 = next() else { return (nil, nil) }
            if c2.isHexDigit {
                let info = detectUnicode(base: .Hex, initial: c2.hexDigitValue)
                return info.unicodeChar(prePeep: [c, c2])
            } else if c2 == "{" {
                let info = detectUnicode(base: .Hex, expectedEnd: "}")
                return info.unicodeChar(prePeep: [c, c2])
            } else {
                return (nil, [c, c2])
            }
            
        default:
            return (nil, [c])
        }
    }
}

