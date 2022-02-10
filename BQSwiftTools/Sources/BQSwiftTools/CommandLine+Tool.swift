//
//  CommandLine+Tool.swift
//  TestTool
//
//  Created by Beiqi xu on 2019/12/1.
//  Copyright © 2019 Beiqi xu. All rights reserved.
//

import Foundation
import BQFoundationTool



public struct CmdParams {
    public internal(set) var executingFile: String
    public internal(set) var others = [String]()
    public internal(set) var longKVs = [String: String]()
    public internal(set) var shortKVs = [Character: String]()
    public internal(set) var longFlags = Set<String>()
    public internal(set) var shortFlags = Set<Character>()
}

extension CmdParams: CustomStringConvertible {
    public var description: String {
        String(describing: self)
    }
}




public extension CommandLine {
    
    static func analyzeMyParams(_ args: [String] = arguments) -> CmdParams {
        var res = CmdParams(executingFile: args.first ?? "")
        var longKey: String?
        var shortKey: Character?
        for p in args.dropFirst() {
            if p.hasPrefix("--") {
                if p.count > 3 {
                    res.insertFlag(key: &longKey)
                    longKey = String(p.dropFirst(2))
                } else {
                    print(String(format: "!!!warning: param (%@) translated to short param (%@)", p, p.dropFirst().description))
                    res.insertFlag(key: &shortKey)
                    shortKey = p.count == 3 ? p.last : nil
                }
            } else if p.hasPrefix("-") {
                res.insertFlag(key: &shortKey)
                if p.count > 2 { // translate to multi short flags
                    res.shortFlags.formUnion(p.dropFirst())
                } else if p.count == 2 {
                    shortKey = p.last
                }
            } else if let l = longKey {
                longKey = nil
                res.longKVs[l] = p
            } else if let s = shortKey {
                shortKey = nil
                res.shortKVs[s] = p
            } else {
                res.others.append(p)
            }
        }
        res.insertFlag(key: &longKey)
        res.insertFlag(key: &shortKey)
        return res
    }
}




public extension CmdParams {
    
    func value(forShortKey c: Character) -> String? { shortKVs[c] }

    func value(forLongKey k: String) -> String? { 
        switch k.count {
        case 0:  return nil
        case 1:  return shortKVs[k.first!]
        default: return longKVs[k]
        }
    }
    
    func value(forFlexibleKey k: String) -> String? { 
        switch k.count {
        case 0:  return nil
        case 1:  return shortKVs[k.first!]
        default: return longKVs[k] ?? shortKVs[k.first!]
        }
    }
}


public extension CmdParams {
   
    mutating func insertFlag(key: UnsafeMutablePointer<String?>) {
        guard let f = key.pointee else { return }
        key.pointee = nil
        switch f.count {
        case 0:  return
        case 1:  shortFlags.insert(f.first!)
        default: longFlags.insert(f)
        }
    }
    
    mutating func insertFlag(key: UnsafeMutablePointer<Character?>) {
        guard let c = key.pointee else { return }
        key.pointee = nil
        shortFlags.insert(c)
    }
    
    func contains(flag c: Character) -> Bool { shortFlags.contains(c) }
    
    func contains(flag l: String) -> Bool {
        switch l.count {
        case 0:  return false
        case 1:  return shortFlags.contains(l.first!)
        default: return longFlags.contains(l)
        }
    }
    
    func contains(flexibleFlag f: String) -> Bool {
        switch f.count {
        case 0:  return false
        case 1:  return shortFlags.contains(f.first!)
        default: return longFlags.contains(f) || shortFlags.contains(f.first!)
        }        
    }
}







// MARK: - custom keys -

public enum CommonParamKey: String, CaseIterable {
    case path
    case out
    case files
    case FilesRegExp
    case separator
}

public extension CommonParamKey {
    
    static var helpDescription: String { """
            
        common params: 
            
            -p, --path
                working / searching in this directory, default is current path.
            
            -f, --files
                custom inputing files for --path
            
            -F, --FilesRegExp
                custom inputing files in regular-expression mode for --path
            
            -s, --separator
                custom separator for multi-files for --files / --FilesRegExp; default is comma(,)
            
            -o, --out
                output directory or file, default will be --path (current path when no value). 
                output-files may be append suffix (eg: _1, _2, ...) when there are multi-files.
            
        """
    }
}

public extension CmdParams {
    func value(forKey k: CommonParamKey) -> String? { value(forFlexibleKey: k.rawValue) }
    func componentsOfValue(forKey k: CommonParamKey) -> [String]? { value(forKey: k)?.components(separatedBy: separator) }
    
    var separator: String { value(forKey: .separator) ?? "," }
    var FilesRegExp: [String]? { componentsOfValue(forKey: .FilesRegExp) }
    var files: [String]? { componentsOfValue(forKey: .files) }
    
    var currentDirectory: String { FileManager.default.currentDirectoryPath }
    
    var path: String? { value(forKey: .path) }
    var defaultPath: String {
        guard let w = path else { return currentDirectory }
        return w.isFullPath ? w : currentDirectory.appendingFileName(w)
    }
    
    var out: String? { value(forKey: .out) }
    var defaultOut: String {
        guard let o = out else { return defaultPath }
        return o.isFullPath ? o : defaultPath.appendingFileName(o)
    }
    
    func expand(inputFile f: String) -> String {
        f.isFullPath ? f : defaultPath.appendingFileName(f)
    }
    
    func expand(outputFile f: String) -> String {
        f.isFullPath ? f : defaultOut.appendingFileName(f)
    }
    
    func output(fileName: String, suffix s: String) -> String {
        let path = defaultOut
        var isDir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        if !exist && path.isDirectory {
            FileManager.default.createDirectory(path)
            return path.appendingFileName(fileName).filePath(insertSuffix: s)
        } else if exist && isDir.boolValue {
            return path.appendingFileName(fileName).filePath(insertSuffix: s)
        } else {
            return path.filePath(insertSuffix: s)
        }
    }

    func output(fileName: String, repeat n: Int) -> String {
        output(fileName: fileName, suffix: n > 0 ? "_\(n)" : "")
    }
}


public extension String {
    var isFullPath: Bool { hasPrefix("/") }
    var isDirectory: Bool { hasSuffix("/") }
    
    func filePath(insertSuffix sfx: String) -> String {
        guard !sfx.isEmpty else { return self }
        let ext = fileExtension
        guard !ext.isEmpty else { return self + sfx }
        var tmp = self
        tmp.insert(contentsOf: sfx, at: index(endIndex, offsetBy: -tmp.count-1))
        return tmp
    }
}
