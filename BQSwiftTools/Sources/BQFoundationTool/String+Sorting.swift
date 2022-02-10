//
//  File.swift
//  
//
//  Created by Beiqi on 2022/1/26.
//

import Foundation



public extension String {
    
    /// separatedBy lines,  trimming whitespaces,  remove empty strings.
    var allValidLines: [String] {
        components(separatedBy: .newlines).compactMap {
            $0.trimmingCharacters(in: .whitespaces).notEmpty
        }
    }
    
    var fullNSRange: NSRange { NSRange(location: 0, length: (self as NSString).length) }
    
    var isASCIIstring: Bool { 
        for c in self { 
            if !c.isASCII { return false }
        }
        return true
    }

}


public func pairString(key: String, value: String) -> String {
    String(format: "%@ = %@;", key.wrappingDoubleQuotes, value.wrappingDoubleQuotes)
}


public extension Dictionary where Key == String, Value == String {
    
    var pairStrings: String {
        let lines = map { pairString(key: $0.key, value: $0.value) }
        return lines.joined(separator: String(.newline, .newline))
    }
    
    var sortedPairStrings: String {
        var ascKeys = [String]()
        var othersKeys = [String]()
        keys.forEach { k in k.isASCIIstring ? ascKeys.append(k) : othersKeys.append(k) }
        ascKeys.sort()
        othersKeys.sort()
        
        let kvPair: (String)->String = { pairString(key: $0, value: self[$0]!) }
        var lines = othersKeys.map(kvPair)
        lines.insert("/*  not ascii strings : \(othersKeys.count)  */", at: 0)
        lines.append("/*    ascii strings : \(ascKeys.count)  */")
        lines.append(contentsOf: ascKeys.map(kvPair))
        return lines.joined(separator: String(.newline, .newline))
    }
}


public func compareInOrders<A, B, ASQ: Sequence, BSQ: Sequence>(_ ahs: ASQ, _ bhs: BSQ,
    compareBy:  (A, B)-> ComparisonResult,
    matching:   ((A, B)->Void)? = nil,
    ahsMissing: ((B)->Void)? = nil,
    bhsMissing: ((A)->Void)? = nil
)   where ASQ.Element == A, BSQ.Element == B {

    var aIt = ahs.makeIterator();    var a = aIt.next()
    var bIt = bhs.makeIterator();    var b = bIt.next()

    while let a0 = a, let b0 = b {
        switch compareBy(a0, b0) {
        case .orderedAscending:
            bhsMissing?(a0)
            a = aIt.next()
        case .orderedDescending:
            ahsMissing?(b0)
            b = bIt.next()
        case .orderedSame:
            matching?(a0, b0)
            a = aIt.next()
            b = bIt.next()
        }
    }

    if let a = a, let blk = bhsMissing {
        blk(a); while let a = aIt.next() { blk(a) }
    } else if let b = b, let blk = ahsMissing {
        blk(b); while let b = bIt.next() { blk(b) }
    }
}

public extension Collection where Element == String {
    var sortedLines: String {
        var ascKeys = [String]()
        var otherKes = [String]()
        forEach { s in
            s.isASCIIstring ? ascKeys.append(s) : otherKes.append(s)
        }

        let spliting = ascKeys.isEmpty || otherKes.isEmpty ? [] : [""]
        return (ascKeys + spliting + otherKes)
            .joined(separator: String(.newline, .newline))
    }
}
