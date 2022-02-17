//
//  FileItemHandler.swift
//  ShellTool
//
//  Created by Beiqi on 2021/9/17.
//

import Foundation
import CoreVideo


public protocol FileEnm {
    func skipDescendants()
}

extension FileManager.DirectoryEnumerator: FileEnm { }

public protocol FileItemHandler {
    /// process current file item, in advance you can skipDescendants by fileEnm
    func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm)
}




// MARK: - Concrete Handlers -


/// transform handle-method into block
public struct FileItemBlocker : FileItemHandler {

    public typealias FIBlock = (_ item: String, _ isDirectory: Bool, _ path: String, FileEnm) -> Void

    public var block: FIBlock

    public init(_ blk: @escaping FIBlock) { block = blk }

    public func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm) {
        block(item, isDirectory, path, fileEnm)
    }
}


/// print current item (directory will ends with slash)
public struct FileItemPrinter : FileItemHandler {
    
    public var directoryFlag = String(.slash)
    
    public func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm) {
        print(isDirectory ? item + directoryFlag : item)
    }
}


/// read text-contents of current item, then pass it to self.didRead;  print error when failed.
public struct FileItemTexter : FileItemHandler {
    
    public typealias FIDidRead = (_ content: String, _ file: URL) -> Void
    
    public var didRead: FIDidRead
    
    public func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm) {
        guard !isDirectory else { return }
        let file = path.appendingFileName(item)
        guard let ct = String(readSafely: file) else { return }
        didRead(ct, file.fileUrl)
    }
}




// MARK: - Filter -

/// filter file item then pass which filled the conditions to next handler.
public class FileItemFilters: FileItemHandler {
    
    public typealias FilterFileOK = (_ item: String)->Bool
    public typealias FilterDirtOK = (_ item: String, FileEnm) -> Bool

    fileprivate var dirtOKs = [FilterDirtOK]()
    fileprivate var fileOKs = [FilterFileOK]()
    fileprivate var next: FileItemHandler?
    
    public init(handler: FileItemHandler? = nil) { next = handler }
    public init(block: @escaping FileItemBlocker.FIBlock) { next = FileItemBlocker(block) }

    public func reset(handler: FileItemHandler) -> Self { next = handler; return self }
    
    public func reverseFileFilters() -> Self { fileOKs.reverse(); return self }
    public func reverseDirtFilters() -> Self { dirtOKs.reverse(); return self }

    public func isFilled(directory item: String, fileEnm: FileEnm) -> Bool {
        for blk in dirtOKs {
            if !blk(item, fileEnm) { return false }
        }
        return true
    }
    
    public func isFilled(file item: String) -> Bool {
        for blk in fileOKs {
            if !blk(item) { return false }
        }
        return true
    }
    
    public func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm) {
        guard let nextHandler = next else { 
            print("warning: FileItemFilters was not found next handler..."); return 
        }
        guard isDirectory ? isFilled(directory: item, fileEnm: fileEnm)
                : isFilled(file: item) else { return }
        nextHandler.handle(item: item, isDirectory: isDirectory, at: path, fileEnm: fileEnm)
    }
}

public extension FileItemFilters {
    
    typealias FileMatched = (_ item: String) -> Bool
    

    func fill(dirs: [String]) -> Self { fill(dirs: dirs.fileNameMatching()) }
    func fill(dirs mt: @escaping FileMatched) -> Self {
        dirtOKs.append { crt, _ in mt(crt) }
        return self
    }
    
    func ignore(dirs: [String]) -> Self { ignore(dirs: dirs.fileNameMatching()) } 
    func ignore(dirs mt: @escaping FileMatched) -> Self {
        dirtOKs.append { crt, enm in 
            guard mt(crt) else { return true }
            enm.skipDescendants()
            return false
        }
        return self
    }
    
    func onlyDirs() -> Self {
        fileOKs.append { _ in false }
        return self
    }

    
    
    
    func fill(files: [String]) -> Self { fill(files: files.fileNameMatching()) }
    func fill(files mt: @escaping FileMatched) -> Self {
        fileOKs.append { mt($0) }
        return self
    }

    func ignore(files: [String]) -> Self { ignore(files: files.fileNameMatching()) } 
    func ignore(files mt: @escaping FileMatched) -> Self {
        fileOKs.append { !mt($0) }
        return self
    }

    func onlyFiles() -> Self {
        dirtOKs.append { _, _ in false }
        return self
    }

    func ignoreHiddenFiles() -> Self {
        let skip: FileMatched = { $0.fileName.hasPrefix(".") }
        dirtOKs.append { item, enm in
            guard skip(item) else { return true }
            enm.skipDescendants()
            return false
        }
        fileOKs.append { !skip($0) }
        return self
    }
}


public extension FileItemHandler {
    
    var filter: FileItemFilters { FileItemFilters(handler: self) }
    
    func startWorking(atDirectory dir: String, files: [String]? = nil) {
        FileManager.default.searchRecursively(atDirectory: dir, files: files) { enm, item, isDir in
            handle(item: item, isDirectory: isDir, at: dir, fileEnm: enm)
        }
    }
}




// MARK: - matching tools -

public enum SubstringPosition {
    
    case prefix, any, suffix
    
    public var substringMatcher: (String) -> (String)->Bool {
        switch self {
        case .prefix:   return String.hasPrefix
        case .suffix:   return String.hasSuffix
        case .any:      return String.contains
        }
    }
}


fileprivate extension Bool {
    var fileNameGetter: (String)->String { self ? \.fileNameWithoutExt : \.fileName }
}


public extension String {

    func fileExtMatching() -> FileItemFilters.FileMatched {
        { $0.fileExtension == self }
    }

    func fileNameMatching(excludeExt: Bool = false) -> FileItemFilters.FileMatched {
        let exName = excludeExt.fileNameGetter
        return { exName($0) == self }
    }
    
    func fileNameContaining(excludeExt: Bool = false, position: SubstringPosition = .any) -> FileItemFilters.FileMatched {
        let exName = excludeExt.fileNameGetter
        let matchSub = position.substringMatcher
        return { matchSub(exName($0))(self) }
    }
    
    func fileNameRegExpMatching(excludeExt: Bool = false) throws -> FileItemFilters.FileMatched {
        let expr = try NSRegularExpression(pattern: self, options: [])
        let exName = excludeExt.fileNameGetter
        return {
            let fname = exName($0); let rg = fname.fullNSRange
            return expr.firstMatch(in: fname, options: [], range: rg) != nil
        }
    }
}


public extension Array where Element == String {
    
    func fileExtMatching() -> FileItemFilters.FileMatched {
        guard count > 1 else { return (first ?? "").fileExtMatching() }
        let set = Set(self)
        return { set.contains($0.fileExtension) }
    }
    
    func fileNameMatching(excludeExt: Bool = false) -> FileItemFilters.FileMatched {
        guard count > 1 else { return (first ?? "").fileNameMatching(excludeExt: excludeExt) }
        let exName = excludeExt.fileNameGetter
        let set = Set(self)
        return { set.contains(exName($0)) }
    }
    
    
    func fileNameContaining(excludeExt: Bool = false, position: SubstringPosition = .any) -> FileItemFilters.FileMatched {
        guard isNotEmpty else { return { _ in true } }
        guard count > 1 else { return first!.fileNameContaining(excludeExt: excludeExt, position: position) }
        
        let exName = excludeExt.fileNameGetter
        let matchSub = position.substringMatcher
        return {
            let fname = exName($0)
            return reduce(false) { $0 || matchSub(fname)($1) }
        }
    }
    
    func fileNameRegExpMatching(excludeExt: Bool = false) throws -> FileItemFilters.FileMatched {
        guard isNotEmpty else { return { _ in false }}
        guard count > 1 else { return try first!.fileNameRegExpMatching(excludeExt: excludeExt) }
        let regs = try map { try NSRegularExpression(pattern: $0, options: []) }
        let exName = excludeExt.fileNameGetter
        return {
            let fname = exName($0); let rg = fname.fullNSRange
            return regs.reduce(false) { $0 || $1.firstMatch(in: fname, options: [], range: rg) != nil }
        }
    }

}



