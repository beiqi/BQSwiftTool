//
//  CommandLine+Tool.swift
//  TestTool
//
//  Created by Beiqi xu on 2019/12/1.
//  Copyright © 2019 Beiqi xu. All rights reserved.
//

import Foundation
import BQFoundationTool



/// anylyzed command line arguments 
public struct CmdParams {
    
    /// current executing script file
    public internal(set) var executingFile: String
    
    /// values for unmatched keys
    public internal(set) var others = [String]()
    
    /// for long keys (at least 2 chars, without dash)
    public internal(set) var longKVs = [String: String]()
    
    /// for short keys (without dash)
    public internal(set) var shortKVs = [Character: String]()
    
    /// for long keys (at least 2 chars, without dash) which has not found matched value
    public internal(set) var longFlags = Set<String>()
    
    /// for short keys (without dash) which has not found matched value or for multi-unions
    public internal(set) var shortFlags = Set<Character>()
}

public extension CmdParams {
    
    /// analyze command line arguments. which key is formatted with dash(one or two) prefix.
    ///  
    ///     --file => long  key "file", can follow with value or not
    ///     --f    => short key "f",    can follow with value or not
    ///     -f     => short key "f",    can follow with value or not
    ///     -fvT   => short keys ["f", "v", "T"], and form union to .shortFlags 
    ///     
    /// - Parameter args: First element should be executingFile,  default is CommandLine.arguments
    ///  
    init(cmdArguments args: [String] = CommandLine.arguments) {
        
        self.init(executingFile: args.first ?? "")
        
        // save old value as flags when new value is not nil
        var lastKey: Substring? {
            didSet {
                guard let k = oldValue?.notEmpty, lastKey != nil else { return }
                if k.count == 1 {
                    shortFlags.insert(k.first!)
                } else {
                    longFlags.insert(String(k))
                }
            }
        }

        for p in args.dropFirst() {
            if p.hasPrefix("--") {
                lastKey = p.dropFirst(2)
            } else if p.hasPrefix("-") {
                let k = p.dropFirst(1)
                if k.count > 1 {
                    shortFlags.formUnion(k)
                    lastKey = ""
                } else {
                    lastKey = k
                }
            } else if let k = lastKey?.notEmpty {
                lastKey = nil
                if k.count == 1 {
                    shortKVs[k.first!] = p
                } else {
                    longKVs[String(k)] = p
                }
            } else {
                others.append(p)
            }
        }
        
        lastKey = "" // clear to save old lastKey.
    }
}

extension CmdParams: CustomStringConvertible {
    public var description: String {
        String(describing: self)
    }
}







// MARK: - searching keys -

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







// MARK: - common param keys -

/// common defined params
public enum CommonParamKey: String, CaseIterable {
    
    /// -p, --path
    /// 
    /// working directory or file, relative to running-context path or full path. 
    case path

    /// -o, --out
    /// 
    /// output directory (exist or end with slash /) or file, relative to --path or full file path.
    case out

    /// -f, --files
    /// 
    /// custom inputing files. relative to --path or full file path.
    case files

    /// -F, --FilesRegExp
    /// 
    /// custom inputing files in regular-expression mode. 
    /// relative to --path or full file path.
    case FilesRegExp

    /// -s, --separator
    /// 
    /// custom separator of multi-files, using in --files / --FilesRegExp. 
    /// default is comma(,)
    case separator
}

public extension CommonParamKey {
    
    /// help info for all cases
    static var helpDescription: String { """
            
        common params: 
            
            -p, --path
                working directory or file, relative to running-context path or full path.
            
            -f, --files
                custom inputing files. relative to --path or full file path.
            
            -F, --FilesRegExp
                custom inputing files in regular-expression mode. 
                relative to --path or full file path.
            
            -s, --separator
                custom separator of multi-files, using in --files / --FilesRegExp
                default is comma(,)
            
            -o, --out
                output directory (exist or end with slash /) or file, relative to --path or full file path.
            
        """
    }
}

public extension CmdParams {
    
    /// get value of CommonParamKey as flexiable type
    func value(forKey k: CommonParamKey) -> String? {
        value(forFlexibleKey: k.rawValue)
    }
    /// get value and separated by separator, remove all empty strings
    func componentsOfValue(forKey k: CommonParamKey) -> [String]? { 
        value(forKey: k)?.components(separatedBy: separator)
            .compactMap { $0.notEmpty }.notEmpty
    }
    
    var separator: String { value(forKey: .separator) ?? "," }
    var FilesRegExp: [String]? { componentsOfValue(forKey: .FilesRegExp) }
    var files: [String]? { componentsOfValue(forKey: .files) }
    
    /// current script executing path
    var currentDirectory: String { FileManager.default.currentDirectoryPath }
    
    /// value of .path, relative to currentDirectory
    var inputPath: String {
        guard let w = value(forKey: .path) else { return currentDirectory }
        return w.isFullPath ? w : currentDirectory.appendingFileName(w)
    }
    
    /// value of .out, relative to inputPath
    var outputPath: String {
        guard let o = value(forKey: .out) else { return inputPath }
        return o.isFullPath ? o : inputPath.appendingFileName(o)
    }
    
    /// expand input file path if need
    /// - Parameter f: file name, relative path, or full path
    /// - Returns: full file path relative inputPath
    func expand(inputFile f: String) -> String {
        f.isFullPath ? f : inputPath.appendingFileName(f)
    }
    
    /// expand output file path if need
    /// - Parameter f: file name, relative path, or full path
    /// - Returns: full file path relative outputPath
    func expand(outputFile f: String) -> String {
        f.isFullPath ? f : outputPath.appendingFileName(f)
    }
    
    /// try to locate output file path.
    /// - Parameters:
    ///   - filename: relative to outputPath.  ignore filename if outputPath is not an diretory.
    ///   - overwrite: will append suffix (_1, _2, ...)  when file exists for disabled overwriting
    /// - Returns: adapted file path
    func outputFile(expected filename: String, overwrite: Bool = true) -> String {
        let path = outputPath
        let pathInfo = path.detectPath(alsoCreateDirectory: true)
        let filePath = pathInfo.isDirectory ? path.appendingFileName(filename) : path
        let fileInfo = filePath.detectPath(alsoCreateDirectory: true)
        
        guard !fileInfo.isDirectory, fileInfo.exist && !overwrite else { return filePath }
        
        let dir = filePath.parentDirectory
        let name = filePath.fileName
        let dotIdx = name.lastIndex(of: ".") ?? name.endIndex
        let subname = name[..<dotIdx]
        let ext = name[dotIdx...]
        let mng = FileManager.default
        let has_1 = subname.hasSuffix("_1")
        let namePrf = has_1 ? subname.dropLast(1) : (subname + "_")
        let begin = has_1 ? 2 : 1
        for i in begin...20 {
            let file = dir.appendingFileName(namePrf + "\(i)" + ext)
            if !mng.fileExists(atPath: file) { return file }
        }
        return dir.appendingFileName(subname + "_1" + ext)
    }
}


public extension String {
    
    /// begin with slash /
    var isFullPath: Bool { hasPrefix("/") }
    
    /// end with slash /
    var isDirectory: Bool { hasSuffix("/") }
    
    
    /// detect current path file info. 
    /// 
    /// when file exists, do nothing. otherwise check as directory when ends with slash (/), 
    /// and create directory when it sets.
    /// - Parameter alsoCreateDirectory: create directory when not exists
    func detectPath(alsoCreateDirectory: Bool = false) -> (isDirectory: Bool, exist: Bool) {
        let mng = FileManager.default
        var ocIsDir: ObjCBool = false
        var exist = mng.fileExists(atPath: self, isDirectory: &ocIsDir)
        guard !exist else { return (ocIsDir.boolValue, exist) }
        guard alsoCreateDirectory else { return (isDirectory, exist) }
        if isDirectory {
            exist = mng.createDirectory(self)
            return (isDirectory: true, exist)
        } else {
            mng.createDirectory(parentDirectory)
            return (false, false)
        }
    }
}
