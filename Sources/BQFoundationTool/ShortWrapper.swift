//
//  File.swift
//  
//
//  Created by Beiqi on 2022/1/25.
//

import Foundation


public protocol BQEmpty {
    var isEmpty: Bool  { get }
}

public extension BQEmpty {
    var isNotEmpty: Bool  { !isEmpty }
    var notEmpty:   Self? { isEmpty ? nil : self }
}


extension Set: BQEmpty {}
extension Array: BQEmpty {}
extension String: BQEmpty {}
extension Substring: BQEmpty {}
extension Dictionary: BQEmpty {}
extension Range: BQEmpty {}
extension ClosedRange: BQEmpty {}



public extension Error {
    
    /// check as NSError, for code != 0
    /// 
    /// for enum: NSError.code will be rawValue of Integer-type otherwise will be  enum declare index. 
    /// 
    ///     enum ConnectResult: Int, Error, CaseIterable {
    ///        case failed = -101, crashed = -102, successed = 0, 
    ///     }
    ///     enum ReadResult: Error, CaseIterable {
    ///        case successed, nothing, unrecognized
    ///     }
    ///     
    /// otherwise (customed struct/class) NSError.code != 0
    /// 
    /// - Returns: (self as NSError).code == 0. 
    /// 
    var isSuccessed: Bool  { (self as NSError).code == 0 }
    
    /// - Returns: ! isSuccessed
    var isFailed:    Bool  { !isSuccessed }
}


// MARK: - Optional


public extension Optional where Wrapped : Error {
    var isSuccessed: Bool  { self?.isSuccessed ?? true }
    var isFailed:    Bool  { !isSuccessed }
}

public extension Optional where Wrapped : BQEmpty {
    var isEmpty:    Bool  { self?.isEmpty ?? true }
    var isNotEmpty: Bool  { !isEmpty }
}

public extension Optional where Wrapped == Bool {
    var isTrue:  Bool  { self ?? false }
    var isFalse: Bool  { !isTrue }
}

