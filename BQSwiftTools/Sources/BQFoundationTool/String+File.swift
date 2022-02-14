//
//  String+File.swift
//  TestTool
//
//  Created by Beiqi xu on 2021/3/11.
//  Copyright © 2021 Beiqi xu. All rights reserved.
//

import Foundation


// MARK: - path & name

public extension String {
    
    /// remove extension (include ".") if it has.
    var deletingExtension: String {
        guard let ext = fileExtension.notEmpty else { return self }
        let end = index(endIndex, offsetBy: -ext.count-1) // include "."
        return String(self[..<end])
    }
    
    /// last path component
    var fileName: String { (self as NSString).lastPathComponent }
    
    /// fileName.deletingExtension
    var fileNameWithoutExt: String { fileName.deletingExtension }
    
    /// file extension ( such as "png", not including ".")
    var fileExtension: String { (self as NSString).pathExtension }
    
    /// parentDirectory.fileName
    var parentFileName: String { parentDirectory.fileName }
    
    /// remove last path component
    var parentDirectory: String { (self as NSString).deletingLastPathComponent }
    
    /// appendingPathComponent (name)
    func appendingFileName(_ name: String) -> String { (self as NSString).appendingPathComponent(name) }
    
    var fileUrl: URL { URL(fileURLWithPath: self) }
}

public extension URL {
    /// relativePath if is file url, otherwise return nil
    var filePath: String? { isFileURL ? relativePath : nil }
}




// MARK: - read & write

public extension String {
    
    init?(readSafely file: String, endcoding: Encoding = .utf8) {
        do {
            try self.init(contentsOfFile: file, encoding: endcoding)
        } catch {
            print("~~~~ failed to read contents of file: \(file)    error: \(error)")
            return nil
        }
    }
    
    internal func trySaving(file: String, _ writing: () throws -> Void) {
        do {
            try writing()
            print(" >>>> file has  saved \(utf8.count.bytesSize) : \t" + file)
        } catch {
            print(" ~~~~ file can't save : \t" + file)
            print(" ~~~~ \(error)")
        }
    }
    
    func writeSafely(toFile path: String) {
        trySaving(file: path) {  
            try write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
    
    func writeSafely(to file: URL) {
        trySaving(file: file.relativePath) {
            try write(to: file, atomically: true, encoding: .utf8)
        }
    }
    
}


public extension Int {
    
    /// xxx B/K/M/G
    var bytesSize: String {
        if      self < (1<<10) { return "\(round(shiftR: 0))B" }
        else if self < (1<<20) { return "\(round(shiftR:10))K" }
        else if self < (1<<30) { return "\(round(shiftR:20))M" }
        else                   { return "\(round(shiftR:30))G" }
    }
    
    private func round(shiftR bits: Int) -> Int {
        guard bits > 0 else { return self }
        return ((self >> (bits-1)) + 1) >> 1 // 四舍五入
    }
}

