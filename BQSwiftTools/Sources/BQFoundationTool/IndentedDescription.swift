//
//  IndentedDescription.swift
//  
//
//  Created by Beiqi on 2022/1/25.
//

import Foundation


public protocol IndentedDescription {
    func description(indent spaces: String, prefix: String) -> String
}

public extension IndentedDescription {
    var indentedDescription: String { description(indent: "    ", prefix: "") }
}

extension Array: IndentedDescription {
    
    public func description(indent spaces: String, prefix: String) -> String {
        let contents = map {
            let str: IndentedDescription = ($0 as? IndentedDescription) ?? "\($0)"
            return str.description(indent: spaces, prefix: prefix + spaces)
        }.joined(separator: String(.comma, .newline))
        return "\(prefix)[\n\(contents)\n\(prefix)]"
    }
}

extension Dictionary: IndentedDescription {
    public func description(indent spaces: String, prefix: String) -> String {
        let kPrf = prefix + spaces
        let contents = map {
            let k: IndentedDescription = ($0.key as? IndentedDescription) ?? "\($0.key)"
            let v: IndentedDescription = ($0.value as? IndentedDescription) ?? "\($0.value)"
            let ks = k.description(indent: spaces, prefix: kPrf)
            var vs = v.description(indent: spaces, prefix: kPrf)
            vs.removeFirst(kPrf.count)
            return ks + " : " + vs
        }.sorted().joined(separator: String(.comma, .newline))
        return "\(prefix){\n\(contents)\n\(prefix)}"
    }
}

extension Set: IndentedDescription {
    public func description(indent spaces: String, prefix: String) -> String {
        let contents = map {
            let str: IndentedDescription = ($0 as? IndentedDescription) ?? "\($0)"
            return str.description(indent: spaces, prefix: prefix + spaces)
        }.joined(separator: String(.comma, .newline))
        return "\(prefix)[\n\(contents)\n\(prefix)]"
    }
}

extension String: IndentedDescription {
    public func description(indent spaces: String, prefix: String) -> String {
        prefix + self
    }
}
