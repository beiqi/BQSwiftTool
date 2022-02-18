//
//  FileNames.swift
//  ShellTool
//
//  Created by Beiqi on 2021/11/4.
//

import Foundation

public enum FileExt: String {
    case strings
    case xib
    case h
    case m
    case mm
    case c
    case cpp
    case java
    case swift

    static var forCodes: [FileExt] {
        [ .h, .m, .mm, .c, .cpp, .java, .swift ]
    }
}

public func +(_ name: String, ext: FileExt) -> String { name + "." + ext.rawValue }

public enum DirectoryExt: String {
    case lproj
    case bundle
    case xcassets
    case framework
    case xcodeproj
    case xcworkspace
}

public func +(_ name: String, ext: DirectoryExt) -> String { name + "." + ext.rawValue }

public enum Directory: String {
    case Pods
    case DerivedData
    case Base_lproj = "Base.lproj"
}




public extension Array where Element == String {

    func contains(_ ext: FileExt) -> Bool { contains(ext.rawValue) }

    mutating func remove(_ ext: FileExt) -> Int {
        guard isNotEmpty else { return 0 }
        let orgCount = count
        let str = ext.rawValue
        removeAll { $0 == str }
        return orgCount - count
    }
}






public extension FileItemFilters {
    
    func ignore(file exts: FileExt ...) -> Self {
        let mt = exts.map { $0.rawValue }.fileExtMatching()
        return ignore(files: mt)
    }
    func ignore(dir exts: DirectoryExt ...) -> Self {
        let mt = exts.map { $0.rawValue }.fileExtMatching()
        return ignore(dirs: mt)
    }
    func ignore(dir directorys: Directory ...) -> Self {
        let mt = directorys.map { $0.rawValue }.fileNameMatching()
        return ignore(dirs: mt)
    }
    
    
    func fill(file exts: FileExt ...) -> Self {
        let mt = exts.map { $0.rawValue }.fileExtMatching()
        return fill(files: mt)
    }
    func fill(dir exts: DirectoryExt ...) -> Self {
        let mt = exts.map { $0.rawValue }.fileExtMatching()
        return fill(dirs: mt)
    }
    func fill(dir directorys: Directory ...) -> Self {
        let mt = directorys.map { $0.rawValue }.fileNameMatching()
        return fill(dirs: mt)
    }

    

    func onlyCodeResFiles() -> Self {
        ignoreHiddenFiles()
            .ignore(dir: .Pods, .DerivedData)
            .ignore(dir: .bundle, .xcassets, .framework, .xcodeproj, .xcworkspace)
    }
    
    func only(file ext: FileExt) -> Self {
        onlyFiles().fill(file: ext)
    }
    func only(dir ext: DirectoryExt) -> Self {
        onlyDirs().fill(dir: ext)
    }
}


// MARK: - xcodeproj -


public class XcodeProjLanguages: FileItemHandler {
    
    public var allLangs = Set<String>()
    
    public func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm) {
        allLangs.insert(item.fileNameWithoutExt)
        fileEnm.skipDescendants()
    }
    
    func find(at dir: String) -> Set<String> {
        filter.onlyCodeResFiles().only(dir: .lproj).ignore(dir: .Base_lproj)
            .startWorking(atDirectory: dir)
        return allLangs
    }
}
