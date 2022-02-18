//
//  ParsingProtocol.swift
//  ShellTool
//
//  Created by Beiqi on 2021/9/30.
//

import Foundation

public typealias CursorIndex = String.Index
public typealias CursorValue = (char: Character, index: CursorIndex)

public enum MatchingStatus {
    case missed, expecting, matched(MatchedResult?), rollback(to: CursorIndex)
}
public enum BackMatchingStatus: Int {
    case missed, expecting
}

extension MatchingStatus: Equatable {
    public static func == (lhs: MatchingStatus, rhs: MatchingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.missed, .missed), (.expecting, .expecting):
            return true
        case let (.matched(a), .matched(b)):
            return a == b
        case let (.rollback(a), .rollback(b)):
            return a == b
        default:
            return false
        }
    }
}




public struct MatchedResult {
    public var label: String = ""
    public var begin: CursorIndex
    
    public enum EndValue { case count(Int), end(CursorIndex) }
    public var endValue: EndValue = .count(0)
}

public extension MatchedResult {

    init(start at: CursorIndex, label lb: String = "") {
        label = lb; begin = at; endValue = .count(1)
    }
    init(placeholder at: CursorIndex, label lb: String = "") {
        label = lb; begin = at; endValue = .count(0)
    }
    init(begin bg: CursorIndex, end ed: CursorIndex, label lb: String = "") {
        label = lb; begin = bg; endValue = .end(ed)
    }
    
    mutating func increaseCount() {
        switch endValue {
        case .count(let c):
            endValue = .count(c + 1)
        case .end(_):
            assertionFailure("unsupported...")
        }
    }
    
    var isEmpty: Bool {
        switch endValue {
        case .count(let c): return c <= 0
        case .end(let ed):  return begin >= ed
        }
    }
    
    func end(of content: String) -> CursorIndex {
        switch endValue {
        case .end(let ed):  return ed
        case .count(let c): return content.index(begin, offsetBy: c)
        }
    }
    func subrange(of content: String) -> Range<String.Index> {
        begin ..< end(of: content)
    }
    func substring(of content: String) -> String.SubSequence {
        content[subrange(of: content)]
    }
}

extension MatchedResult.EndValue: Equatable { }
extension MatchedResult : Equatable { }


public extension Array where Element == MatchedResult {
    mutating func tryToAppend(_ st: MatchingStatus) {
        guard case let .matched(res) = st else { return }
        tryToAppend(res)
    }
    mutating func tryToAppend(_ res: MatchedResult?) {
        guard let res = res, !res.isEmpty else { return }
        append(res)
    }
    
    func substrings(of content: String) -> [Substring] {
        map { content[$0.subrange(of: content)] }
    }
    
    func string(of content: String) -> [String] {
        map { content[$0.subrange(of: content)].description }
    }
}




// MARK: - ParsingSource

public struct ParsingSource {
    public let content: String
    public fileprivate(set) var nextIdx: CursorIndex
    
    public init(content ct: String) {
        content = ct
        nextIdx = ct.startIndex
    }
}

public extension ParsingSource {

    subscript(_ idx: CursorIndex) -> Character { content[idx] }
    
    var isEnd: Bool { nextIdx == content.endIndex }
    var isBegin: Bool { nextIdx == content.startIndex }
    var currentIdx: CursorIndex? { isBegin ? nil : content.index(before: nextIdx) }

    func index(after to: CursorIndex) -> CursorIndex? {
        guard to < content.endIndex else { return nil }
        return content.index(after: to)
    }
    
    mutating func move(to: CursorIndex) { nextIdx = to }
    mutating func moveForward() { move(after: nextIdx) }
    mutating func move(after to: CursorIndex) { 
        guard to < content.endIndex else { return }
        nextIdx = content.index(after: to)
    }
    mutating func resetCursor() { move(to: content.startIndex) }
    
    enum NextEnumeration { case forward, stop }
    enum EnumResult { case finished(Int), abandoned(Int) }

    @discardableResult
    func enumerate(from: CursorIndex, _ op: (_ value: CursorValue, _ steps: Int) -> NextEnumeration) -> EnumResult {
        var steps = 0
        var idx = from
        while idx < nextIdx {
            if op((self[idx], idx), steps) == .forward {
                idx = content.index(after: idx)
                steps += 1
            } else {
                return .abandoned(steps)
            }
        }
        return .finished(steps)
    }
}

extension ParsingSource: IteratorProtocol {

    public mutating func next() -> CursorValue? {
        guard !isEnd else { return nil }
        defer { moveForward() }
        return (content[nextIdx], nextIdx)
    }
}




// MARK: - parse & compare

public protocol ComparableObj: AnyObject {
    func match(_ value: CursorValue, of src: ParsingSource) -> MatchingStatus
    func backMatch(from: CursorIndex, of src: ParsingSource) -> BackMatchingStatus
}

public extension ComparableObj {
    
    // 默认采用暴力回溯
    func backMatch(from: CursorIndex, of src: ParsingSource) -> BackMatchingStatus {
        return backMatchOnce(from: from, of: src)
    }
    
    private func backMatchOnce(from: CursorIndex, of src: ParsingSource) -> BackMatchingStatus {
        var st: BackMatchingStatus = .missed
        src.enumerate(from: src.index(after: from)!) { value, steps in
            switch match(value, of: src) {
            case .expecting:
                st = .expecting
            case .missed:
                st = .missed
            case .rollback(let rb):
                st = backMatchOnce(from: rb, of: src)
                return .stop
            case .matched:
                assertionFailure("should never happend.")
            }
            return .forward
        }
        return st
    }
}

public extension ParsingSource {
    
    mutating func startParsing(_ obj: ComparableObj) -> [MatchedResult] {
        resetCursor()
        var results = [MatchedResult]()
        while let v = next() {
            switch obj.match(v, of: self) {
            case let .matched(res):
                results.tryToAppend(res)
                
            case let .rollback(to):
                let _ = obj.backMatch(from: to, of: self)

            case .missed, .expecting:
                break
            }
        }
        return results
    }

    mutating func startParsing(_ objs: [ComparableObj]) -> [MatchedResult] {
        switch objs.count {
        case 0:  return []
        case 1:  return startParsing(objs[0])
        default: break
        }
        
        resetCursor()
        var member = 0
        var results = [MatchedResult]()
        while let value = next() {
            let mat = objs.match(value, of: self, startAt: member)
            switch mat?.st {
            case let .matched(res):
                results.tryToAppend(res)
                member = 0 // 队首优先级高
                
            case let .rollback(to: rb):
                let sub_mat = objs.tailingsMatch((self[rb], rb), of: self, after: mat!.member)
                switch sub_mat?.st {
                case .matched(let res):
                    results.tryToAppend(res)
                    member = 0 // 队首优先级高
                default:
                    member = sub_mat?.member ?? 0
                }
                move(after: rb)
                
            case .expecting:
                member = mat!.member
            case .missed, nil:
                continue
            }
        }

        return results
    }
    
}


fileprivate extension Array where Element == ComparableObj {

    // return not missed member.
    func match(_ value: CursorValue, of src: ParsingSource, startAt member: Int) -> (st: MatchingStatus, member: Int)? {
        guard let ci = CircleRange(begin: member, size: count) else { return nil }
        for i in IteratorSequence(ci) {
            let st = self[i].match(value, of: src)
            if st != .missed { return (st, i) }
        }
        return nil
    }

    // return not missed member.
    func tailingsMatch(_ value: CursorValue, of src: ParsingSource, after member: Int) -> (st: MatchingStatus, member: Int)? {
        for i in (member + 1) ..< count {
            let st = self[i].match(value, of: src)
            switch st {
            case .matched:
                return (st, i)
                
            case .rollback:
                assertionFailure("should never happend")
                
            case .expecting:
                return (st, i)
                
            case .missed:
                continue
            }
        }
        return nil
    }
}


// MARK: - tool

public struct CircleRange {
    let begin: Int
    let size:  Int
    var round: Int
    private var nextValue: Int
    
    init?(begin: Int, size: Int, round: Int = 1) {
        guard 0 < size, 0 <= begin && begin < size, round > 0 else { return nil }
        self.begin = begin
        self.size = size
        self.round = round
        self.nextValue = begin
    }
}

extension CircleRange: IteratorProtocol {
    
    public typealias Element = Int

    public mutating func next() -> Int? {
        guard round > 0 else { return nil }
        let res = nextValue
        nextValue += 1
        if nextValue == size { nextValue = 0 }
        if nextValue == begin { round -= 1 }
        return res
    }
}


public extension Array where Element == Character {
    var nextIndexesKMP: [Int] {
        switch count {
        case 0: return []
        case 1: return [-1]
        default: break
        }
        
        var next = Array<Int>(repeating: -1, count: count)
        var i = 0; var j = -1
        while i < count-1 {
            if j == -1 || self[i] == self[j] {
                i += 1; j += 1
                if self[i] == self[j] {
                    next[i] = next[j]
                } else {
                    next[i] = j
                }
            } else {
                j = next[j]
            }
        }
        
        return next
    }
}
