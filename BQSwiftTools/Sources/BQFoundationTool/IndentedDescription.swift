//
//  IndentedDescription.swift
//  
//
//  Created by Beiqi on 2022/1/25.
//

import Foundation


public protocol IndentedDescription {
    /// To format pretty with indention and more deep levels
    /// - Parameters:
    ///   - deep:      for next level indention
    ///   - indention: current indention
    /// - Returns:     formatted description
    func description(deep: String, indention: String) -> String
}

public extension IndentedDescription {
    /// Default deep with 4-spaces, no indention for top level.
    var indentedDescription: String { description(deep: "    ", indention: "") }
}




// MARK: - default for Collection

extension Array: IndentedDescription {
    
    public func description(deep: String, indention: String) -> String {
        let contents = map {
            let str: IndentedDescription = ($0 as? IndentedDescription) ?? "\($0)"
            return str.description(deep: deep, indention: indention + deep)
        }.joined(separator: String(.comma, .newline))
        return "\(indention)[\n\(contents)\n\(indention)]"
    }
}

extension Dictionary: IndentedDescription {
    public func description(deep: String, indention: String) -> String {
        let kPrf = indention + deep
        let contents = map {
            let k: IndentedDescription = ($0.key as? IndentedDescription) ?? "\($0.key)"
            let v: IndentedDescription = ($0.value as? IndentedDescription) ?? "\($0.value)"
            let ks = k.description(deep: deep, indention: kPrf)
            var vs = v.description(deep: deep, indention: kPrf)
            vs.removeFirst(kPrf.count)
            return ks + " : " + vs
        }.sorted().joined(separator: String(.comma, .newline))
        return "\(indention){\n\(contents)\n\(indention)}"
    }
}

extension Set: IndentedDescription {
    public func description(deep: String, indention: String) -> String {
        let contents = map {
            let str: IndentedDescription = ($0 as? IndentedDescription) ?? "\($0)"
            return str.description(deep: deep, indention: indention + deep)
        }.joined(separator: String(.comma, .newline))
        return "\(indention)[\n\(contents)\n\(indention)]"
    }
}

extension String: IndentedDescription {
    public func description(deep: String, indention: String) -> String {
        indention + self
    }
}
