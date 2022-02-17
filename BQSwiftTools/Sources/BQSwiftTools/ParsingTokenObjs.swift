//
//  ComparableObjs.swift
//  ShellTool
//
//  Created by Beiqi on 2021/10/8.
//

import Foundation
import BQFoundationTool

public enum ResultCustomization: Int, Equatable {
    case ignore, onlyContents, fullRange
}

public protocol ComparableTexts: ComparableObj {
    func resetMatching()
    var resultCustomization: ResultCustomization { get }
}

public extension ComparableTexts {
    var resultCustomization: ResultCustomization { .fullRange }
}



// MARK: -

public class TokenObj {
    public let text: String
    public let chars: [Character]
    public var resultCustomization: ResultCustomization = .fullRange

    public init?(_ tk: String) {
        guard !tk.isEmpty else { return nil }
        text = tk; chars = Array(tk)
    }
 
    public fileprivate(set) var begin: CursorIndex?
    public fileprivate(set) var charsIndex: Int = 0
    public fileprivate(set) lazy var kmpNext: [Int] = chars.nextIndexesKMP

    public func resetMatching() {
        begin = nil; charsIndex = 0
    }
    
}


extension TokenObj: ComparableTexts {
    
    public func match(_ value: CursorValue, of src: ParsingSource) -> MatchingStatus {
        guard charsIndex < chars.count else {
            assertionFailure("should never happend.")
            return .missed
        }
        
        if chars[charsIndex] == value.char {
            begin = begin ?? value.index
            charsIndex += 1
            if charsIndex == chars.count {
                defer { resetMatching() }
                let res = resultCustomization == .ignore ? nil : MatchedResult(begin: begin!, end: src.nextIdx, label: text)
                return .matched(res)
            } else {
                return .expecting
            }
        } else if let b = begin {
            resetMatching()
            return .rollback(to: b)
        } else {
            return .missed
        }
    }

    // 默认采用KMP回溯
    public func backMatch(from: CursorIndex, of src: ParsingSource) -> BackMatchingStatus {
        let d = src.content.distance(from: from, to: src.nextIdx)
        var nxtIdx = d > 0 ? kmpNext[d-1] : -1
        guard nxtIdx >= 0 else { return .missed }
        var srcBegin = src.content.index(from, offsetBy: nxtIdx)
        repeat {
            if chars[nxtIdx] == src[srcBegin] {
                nxtIdx += 1;
                srcBegin = src.content.index(after: srcBegin)
            } else {
                nxtIdx = kmpNext[nxtIdx]
            }
        } while 0 <= nxtIdx && nxtIdx < chars.count && srcBegin < src.nextIdx
        
        guard srcBegin == src.nextIdx && nxtIdx > 0 else { return .missed }
        let mtBegin = src.content.index(srcBegin, offsetBy: -nxtIdx)
        assert(charsIndex < chars.count, "something wrong.")
        begin = mtBegin
        charsIndex = nxtIdx
        return .expecting
    }
}




// MARK: - 

public class BackslashObj {
    public var label = "backslash"
    public var resultCustomization: ResultCustomization = .onlyContents

    fileprivate enum BackslashStatus { case backslash(CursorIndex), openParenthesis(CursorIndex) }
    fileprivate var slshStatus = [BackslashStatus]()
    public func resetMatching() {
        slshStatus.removeAll()
    }
}

extension BackslashObj: ComparableTexts {
    
    public func match(_ value: CursorValue, of src: ParsingSource) -> MatchingStatus {
        let char = value.char; let index = value.index
        switch slshStatus.last {
        case nil:
            if char == "\\" {
                slshStatus.append(.backslash(index))
                return .expecting
            } else {
                return .missed
            }
            
        case .backslash(let bsIndex):
            if char == "(" {
                slshStatus.append(.openParenthesis(index))
                return .expecting
            } else {
                resetMatching()
                switch resultCustomization {
                case .ignore:       return .matched(nil)
                case .onlyContents: return .matched(MatchedResult(begin: index,   end: src.nextIdx, label: label))
                case .fullRange:    return .matched(MatchedResult(begin: bsIndex, end: src.nextIdx, label: label))
                }
            }
            
        case .openParenthesis(let opIndex):
            switch char {
            case "(":
                slshStatus.append(.openParenthesis(index))
                return .expecting
                
            case ")":
                slshStatus.removeLast()
                switch slshStatus.last {
                case nil:
                    assertionFailure("should never happend")
                    return .missed
                case .backslash(let bsIndex):
                    defer { resetMatching() }
                    switch resultCustomization {
                    case .ignore:       return .matched(nil)
                    case .onlyContents: return .matched(MatchedResult(begin: opIndex, end: index, label: label))
                    case .fullRange:    return .matched(MatchedResult(begin: bsIndex, end: src.nextIdx, label: label))
                    }
                case .openParenthesis:
                    return .expecting
                }

            default:
                return .expecting
            }
        }
    }
}






// MARK: - 
/// 为简化处理，excludingObj与rightObj会开启同步匹配，如果excludingObj先匹配成功，则rightObj重置；如果rightObj先匹配成功，将忽略excludingObj, 即PairTokenObj匹配成功。
public class PairTokenObj {
    let label: String
    let leftObj:  TokenObj
    let rightObj: TokenObj
    let excludingObj: ComparableTexts?
    
    public var resultCustomization: ResultCustomization = .onlyContents

    
    public required init(label: String, left: TokenObj, right: TokenObj, excludingObj: ComparableTexts? = nil) {
        self.label = label
        self.leftObj = left
        self.rightObj = right
        self.excludingObj = excludingObj
        leftObj.resultCustomization = .fullRange
        rightObj.resultCustomization = .fullRange
    }
    
    public func resetMatching() {
        resetLeftMatching()
        resetRightMatching()
        excludingObj?.resetMatching()
    }
    
    fileprivate var leftMatched: MatchedResult?
    fileprivate func resetLeftMatching() {
        leftMatched = nil
        leftObj.resetMatching()
    }
    
    fileprivate func resetRightMatching() {
        rightObj.resetMatching()
    }
}

public extension PairTokenObj {
    
    convenience init?(_ l: String, _ r: String, label: String? = nil, exclude: ComparableTexts? = nil) {
        guard let lt = TokenObj(l), let rt = TokenObj(r) else { return nil }
        self.init(label: label ?? (l+r), left: lt, right: rt, excludingObj: exclude)
    }
    
    func customResult(_ cs: ResultCustomization) -> Self {
        resultCustomization = cs; return self
    }
    static var commentSingleLine: PairTokenObj {
        PairTokenObj("//", "\n", label: "comment")!.customResult(.ignore)
    }
    static var commentMultiLines: PairTokenObj {
        PairTokenObj("/*", "*/", label: "comment")!.customResult(.ignore)
    }
    static var quotes: PairTokenObj {
        PairTokenObj(DoubleQuote, DoubleQuote, label: "quotes", exclude: BackslashObj())!
    }
}


extension PairTokenObj : ComparableTexts {
    
    public func match(_ value: CursorValue, of src: ParsingSource) -> MatchingStatus {
        if leftMatched == nil {
            let st = leftObj.match(value, of: src)
            if case .matched(let lRes) = st {
                leftMatched = lRes ?? MatchedResult(placeholder: src.nextIdx)
                return .expecting
            } else {
                return st
            }
        } else {
            return rightMatch(value, of: src)
        }
    }
    
    private func rightMatch(_ value: CursorValue, of src: ParsingSource) -> MatchingStatus {
        switch excludingObj?.match(value, of: src) {
        case .matched:
            resetRightMatching()
            return .expecting
            
        case .rollback(to: let rb):
            let _ = excludingObj?.backMatch(from: rb, of: src)            
            
        default:
            break
        }
        
        switch rightObj.match(value, of: src) {
        case .matched(let res):
            defer { resetMatching() }
            return .matched(result(withRight: res, of: src))
            
        case .rollback(let rb):
            let _ = rightObj.backMatch(from: rb, of: src)
            return .expecting
            
        default: 
            return .expecting
        }
    }
    
    
    private func result(withRight rMt: MatchedResult?, of src: ParsingSource) -> MatchedResult? {
        switch resultCustomization {
        case .ignore:
            return nil
            
        case .onlyContents:
            guard let left = leftMatched else { return nil }
            return MatchedResult(begin: left.end(of: src.content), end: rMt?.begin ?? src.nextIdx, label: label)
            
        case .fullRange:
            guard let left = leftMatched else { return nil }
            return MatchedResult(begin: left.begin, end: src.nextIdx, label: label)
        }
    }

}
