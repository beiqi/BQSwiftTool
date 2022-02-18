//
//  String+Searching.swift
//  ShellTool
//
//  Created by Beiqi on 2021/10/18.
//

import Foundation
import BQFoundationTool

public protocol MatchedResultCondition {
    func fullfill(_ res: MatchedResult) -> Bool
}

public struct MatchedResultHandler: MatchedResultCondition {
    public var condition: (MatchedResult) -> Bool
    public func fullfill(_ res: MatchedResult) -> Bool { condition(res) }
    public static var allTrue: MatchedResultHandler { MatchedResultHandler {_ in true} }
    public static var allFalse: MatchedResultHandler { MatchedResultHandler {_ in false} }
}

public prefix func !(_ cdt: MatchedResultCondition) -> MatchedResultHandler {
    MatchedResultHandler { !cdt.fullfill($0) }
}

public func &&(_ lhs: MatchedResultCondition, _ rhs: MatchedResultCondition) -> MatchedResultHandler {
    MatchedResultHandler { lhs.fullfill($0) && rhs.fullfill($0) }
}

public func ||(_ lhs: MatchedResultCondition, _ rhs: MatchedResultCondition) -> MatchedResultHandler {
    MatchedResultHandler { lhs.fullfill($0) || rhs.fullfill($0) }
}


public extension String {

    func startParsing(_ obj: ComparableObj) -> [MatchedResult] {
        var src = ParsingSource(content: self)
        return src.startParsing(obj)
    }
    func startParsing(_ objs: [ComparableObj]) -> [MatchedResult] {
        var src = ParsingSource(content: self)
        return src.startParsing(objs)
    }

    
    func condition(hasPrefix prf: String) -> MatchedResultCondition {
        let prfCount = prf.count
        if prfCount == 0 { return MatchedResultHandler.allTrue }
        else if count <= prfCount { return MatchedResultHandler.allFalse }
        
        let minBegin = index(startIndex, offsetBy: prfCount)
        return MatchedResultHandler { res in 
            let begin = res.begin
            if minBegin <= begin {
                return self[index(begin, offsetBy: -prfCount) ..< begin] == prf
            } else {
                return false
            }
        }
    }
    
    func condition(hasSuffix sfx: String) -> MatchedResultCondition {
        let sfxCount = sfx.count
        if sfxCount == 0 { return MatchedResultHandler.allTrue }
        else if count <= sfxCount { return MatchedResultHandler.allFalse }
        
        let maxEnd = index(endIndex, offsetBy: -sfxCount)
        return MatchedResultHandler { res in 
            let begin = res.end(of: self)
            if begin <= maxEnd {
                return self[begin ..< index(begin, offsetBy: sfxCount)] == sfx
            } else {
                return false
            }
        }
    }

}


public extension String {
    
    func searchAllDoubleQuoted(includingQuotes: Bool, where cdt: MatchedResultCondition? = nil) -> [MatchedResult] {
        let objs: [PairTokenObj] = [.commentSingleLine, .commentMultiLines, .quotes.customResult(includingQuotes ? .fullRange : .onlyContents)]
        let res = startParsing(objs)
        guard let cdt = cdt else { return res }
        return res.filter { cdt.fullfill($0) }
    }

    func allQuotedStringInPairs(includingQuotes: Bool) -> (pairs: [String: String], repeats: [String: Set<String>]) {
        let subs = searchAllDoubleQuoted(includingQuotes: includingQuotes).string(of: self)
        guard subs.count > 0 else { return ([:], [:]) }

        var repeats = [String: Set<String>]()
        var pairs = [String:String](); pairs.reserveCapacity(subs.count/2)
        
        for i in stride(from: 1, to: subs.count, by: 2) {
            let k = subs[i-1]
            let v = subs[i]
            if let ov = pairs.updateValue(v, forKey: k) {
                repeats.formUnion(value: v, forKey: k, initialValue: ov)
            }
        }
        
        if subs.count % 2 != 0, let k = subs.last {
            let v = "~~ not found value in pair ~~"
            repeats.formUnion(value: v, forKey: k)
        }
        
        return (pairs, repeats)
    }
    
    mutating func replaceQuotes(includingQuotes: Bool = true, with kvs: [String: String]) -> Bool {
        var changed = false
        for res in searchAllDoubleQuoted(includingQuotes: includingQuotes).reversed() {
            let rg = res.subrange(of: self)
            if let v = kvs[String(self[rg])] {
                replaceSubrange(rg, with: v)
                changed = true
            }
        }
        return changed
    }
}

public extension Dictionary {
    mutating func formUnion<T: Hashable>(value v: T, forKey k: Key, initialValue: T? = nil) where Value == Set<T> {
        guard self[k] == nil else { self[k]!.insert(v); return }
        self[k] = [v]
        guard let df = initialValue, df != v else { return }
        self[k]!.insert(df)
    }
    func checkSubset<T: Hashable>() -> (repeated: [Key:T], conflicted: Self) where Value == Set<T> {
        var repeated = [Key:T]()
        var conflicted = Self()
        for (k, allv) in self {
            switch allv.count {
            case 0:  continue
            case 1:  repeated[k] = allv.first!
            default: conflicted[k] = allv
            }
        }
        return (repeated, conflicted)
    }
}

public extension String {

    func allValuesInXib(forKeys keys: [String]) -> [String] {
        let objs = keys.map { PairTokenObj("\($0)\" value=\"", DoubleQuote)! }
        return startParsing(objs).string(of: self)
    }

    mutating func insertLocalized(suffix: String = ".localized") -> Bool {
        var changed = false
        let res = searchAllDoubleQuoted(includingQuotes: true, where: !condition(hasSuffix: suffix))
        for r in res.reversed() {
            insert(contentsOf: suffix, at: r.end(of: self))
            changed = true
        }
        return changed
    }
    
}
