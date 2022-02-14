//
//  File.swift
//  
//
//  Created by Beiqi on 2022/1/26.
//

import Foundation



public extension String {
    
    /// separatedBy .newlines,  trimming .whitespaces,  remove empty strings.
    var allValidLines: [String] {
        components(separatedBy: .newlines).compactMap {
            $0.trimmingCharacters(in: .whitespaces).notEmpty
        }
    }
    
    /// return { 0,  (self as NSString).length }
    var fullNSRange: NSRange { NSRange(location: 0, length: (self as NSString).length) }
    
    /// return true if each character is ASCII , else return false
    var isASCIIstring: Bool { 
        for c in self { 
            if !c.isASCII { return false }
        }
        return true
    }

}


/// make pair as one line. 
///   1. wrappingDoubleQuotes with key and value.
///   2. format with equal sign.
/// - Returns: "key" = "value";
public func pairString(key: String, value: String) -> String {
    String(format: "%@ = %@;", key.wrappingDoubleQuotes, value.wrappingDoubleQuotes)
}


public extension Dictionary where Key == String, Value == String {
    
    /// pairString(key: value: )  for key-value, and joined with newline
    var pairStrings: String {
        let lines = map { pairString(key: $0.key, value: $0.value) }
        return lines.joined(separator: String(.newline, .newline))
    }
    
    /// sorting keys (group with ascii-string type),  then pairString(key: value: ) for key-value, and joined with newline
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


/// compare for matching elements of arrays sorting in ascending.
/// 
///     let array1 = [1,    3, 4,    6 ]
///     let array2 = [1, 2, 3,    5, 6, 7, 8]
///     compareInOrders(array1, array2) { a, b in
///         switch a - b {
///           case 0:       return .orderedSame
///           case let x where x < 0: return .orderedAscending
///           default:      return .orderedDescending
///         }
///     } matching: { a, b in
///         // equal a == b, will be: 1,3,6
///     } asqMissing: { b in
///         // missing matched element for b.  will be 2,5,7,8
///     } bsqMissing: { a in
///         // missing matched element for a.  will be 4
///     }
///     
/// - Parameters:
///     - asqInAscending:  array1 sorting in ascending.
///     - bsqInAscending:  array2 sorting in ascending.
///     - compareBy: compare elments for A of array1 and B of array2
///     - matching:   equal elments.
///     - asqMissing: missing  match for B of array2
///     - bsqMissing: missing match for A of array1
///     
/// - Precondition: asqInAscending, bsqInAscending is sorted in ascending, and the comparor constrains into asscending-order.
/// 
public func compareInOrders<A, B, ASQ: Sequence, BSQ: Sequence>(
    _ asqInAscending: ASQ,
    _ bsqInAscending: BSQ,
    compareBy:  (A, B)-> ComparisonResult,
    matching:   ((A, B)->Void)? = nil,
    asqMissing: ((_ unmatched: B)->Void)? = nil,
    bsqMissing: ((_ unmatched: A)->Void)? = nil
)   where ASQ.Element == A, BSQ.Element == B {

    var aIt = asqInAscending.makeIterator();    var a = aIt.next()
    var bIt = bsqInAscending.makeIterator();    var b = bIt.next()

    while let a0 = a, let b0 = b {
        switch compareBy(a0, b0) {
        case .orderedAscending:
            bsqMissing?(a0)
            a = aIt.next()
        case .orderedDescending:
            asqMissing?(b0)
            b = bIt.next()
        case .orderedSame:
            matching?(a0, b0)
            a = aIt.next()
            b = bIt.next()
        }
    }

    if let a = a, let blk = bsqMissing {
        blk(a); while let a = aIt.next() { blk(a) }
    } else if let b = b, let blk = asqMissing {
        blk(b); while let b = bIt.next() { blk(b) }
    }
}

public extension Collection where Element == String {
    
    /// sorted all elements ( group by isAscii String ), and joined with 2-newlines
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
