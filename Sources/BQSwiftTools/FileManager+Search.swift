//
//  FileManager+search.swift
//  TestTool
//
//  Created by Beiqi xu on 2019/12/1.
//  Copyright © 2019 Beiqi xu. All rights reserved.
//

import Foundation



public extension FileManager.DirectoryEnumerator {
    var isDirectory: Bool { fileAttributes?[.type] as? FileAttributeType == .typeDirectory }
}


public extension FileManager {
        
    typealias ItemOperation = (FileManager.DirectoryEnumerator, _ currentItem: String, _ isDir: Bool) -> Void
    
    func searchRecursively(atDirectory dir: String, files: [String]? = nil, operation:ItemOperation) {
        print("start working on directory: " + dir)

        guard let dir = dir.trimmingCharacters(in: .whitespacesAndNewlines).notEmpty else {
            print("~~~~ invalid directory ~~~~"); return
        }
        var isDir: ObjCBool = false
        guard fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else {
            print("~~~~ directory was not existed ~~~~"); return
        }
        
        let accessing = FileAccessingRAII(path: dir)
        if accessing == nil { return }
        
        print(        "-------- start searching files -------- ")
        defer { print("--------  end searching files  -------- ") }
        guard  let fileEnum = enumerator(atPath: dir) else { return }

        if let files = files, !files.isEmpty {
            for item in files {
                let p = dir.appendingFileName(item)
                if fileExists(atPath: p, isDirectory: &isDir) {
                    if isDir.boolValue, let fileEnum = enumerator(atPath: p) {
                        operation(fileEnum, item, isDir.boolValue)
                        while let item = fileEnum.nextObject() as? String {
                            operation(fileEnum, item, fileEnum.isDirectory)
                        }
                    } else {
                        operation(fileEnum, item, isDir.boolValue)
                    }
                } else {
                    print("~~~~ file was not existed: \(p)")
                }
            }
        } else {
            while let item = fileEnum.nextObject() as? String {
                operation(fileEnum, item, fileEnum.isDirectory)
            }
        }
    }
    
    @discardableResult
    func createDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        if fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue { return true }
        
        do {
            try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            print("~~~~ failed to create directory: \(path)    error: \(error)")
            return false
        }
    }
}




fileprivate class FileAccessingRAII {
    
    #if os(macOS)
    
    private var allowedUrl: URL?
    
    deinit { allowedUrl?.stopAccessingSecurityScopedResource() }
    
    init?(path: String) {
        let oldBm = UserDefaults.standard.data(forKey: path)
        let fileUrl = URL(fileURLWithPath: path)
        let newBm = try? fileUrl.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        if let n = newBm, oldBm != oldBm { UserDefaults.standard.set(n, forKey: path) }
        guard let bm = newBm ?? oldBm else { print("~~~ can't access files ~~~ "); return nil }

        var isStale = false
        allowedUrl = try? URL(resolvingBookmarkData: bm, options: .withSecurityScope , relativeTo: nil, bookmarkDataIsStale: &isStale)
        guard let tmp = allowedUrl else { print("~~~ can't access files ~~~ "); return nil }

        let start = tmp.startAccessingSecurityScopedResource()
        print("start accessing file = \(start), by stale bookmark = \(isStale)")
    }
    
    #else
    
    init?(path: String) { }

    #endif
}


