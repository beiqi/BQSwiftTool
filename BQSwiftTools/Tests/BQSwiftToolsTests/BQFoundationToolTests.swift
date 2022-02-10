//
//  BQFoundationToolTests.swift
//  
//
//  Created by Beiqi on 2022/1/26.
//

import XCTest
@testable import BQFoundationTool

class BQFoundationToolTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEmpty() throws {
        let str = "hello"
        XCTAssertTrue(str.isNotEmpty)
        XCTAssertNotNil(str.notEmpty)

        var tmpStr: String? = nil
        XCTAssertTrue(tmpStr.isEmpty)
        XCTAssertFalse(tmpStr.isNotEmpty)
        XCTAssertNil(tmpStr?.notEmpty)
        tmpStr = ""
        XCTAssertTrue(tmpStr.isEmpty)
        XCTAssertFalse(tmpStr.isNotEmpty)
        XCTAssertNil(tmpStr?.notEmpty)
        tmpStr = str
        XCTAssertTrue(tmpStr.isNotEmpty)
        XCTAssertFalse(tmpStr.isEmpty)
        XCTAssertNotNil(tmpStr?.notEmpty)
    }
    
    func testError() {
        let error: Error = NSError(domain: "XCTest", code: -1, userInfo: nil)
        XCTAssertTrue(error.isFailed)
        XCTAssertFalse(error.isSuccessed)
        
        var tmpErr: Error? = nil
        XCTAssertTrue(tmpErr.isSuccessed)
        XCTAssertFalse(tmpErr.isFailed)

        for c in ConnectResult.allCases {
            XCTAssertEqual(c.rawValue, (c as NSError).code)
        }
        for (i, c) in ReadResult.allCases.enumerated() {
            XCTAssertEqual(i, (c as NSError).code)
        }

        tmpErr = ConnectResult.successed
        XCTAssertTrue(tmpErr.isSuccessed)
        XCTAssertFalse(tmpErr.isFailed)

        tmpErr = ConnectResult.failed
        XCTAssertFalse(tmpErr.isSuccessed)
        XCTAssertTrue(tmpErr.isFailed)

        tmpErr = ReadResult.successed
        XCTAssertTrue(tmpErr.isSuccessed)
        XCTAssertFalse(tmpErr.isFailed)
        
        tmpErr = ReadResult.nothing
        XCTAssertFalse(tmpErr.isSuccessed)
        XCTAssertTrue(tmpErr.isFailed)

        tmpErr = MyResult(tip: "something error")
        XCTAssertFalse(tmpErr.isSuccessed)
        XCTAssertTrue(tmpErr.isFailed)
        
        tmpErr = MyResult2()
        XCTAssertFalse(tmpErr.isSuccessed)
        XCTAssertTrue(tmpErr.isFailed)
    }

    func testOptionalBool() throws {
        var authed: Bool? = nil
        XCTAssertTrue(authed.isFalse)
        XCTAssertFalse(authed.isTrue)
        authed = false
        XCTAssertTrue(authed.isFalse)
        XCTAssertFalse(authed.isTrue)
        authed = true
        XCTAssertTrue(authed.isTrue)
        XCTAssertFalse(authed.isFalse)
    }

    
    func testIndention() {
        XCTAssertEqual(SpecialChar.newline.rawValue, "\n".first!)
        let array: [Any] = ["hello", ["world1", "world2", "world3"], "tommorrow", ["key1":"value1", "key2":"value2", "key3":["world1", "world2", "world3"]]]
        let pretty = """
            [
                hello,
                [
                    world1,
                    world2,
                    world3
                ],
                tommorrow,
                {
                    key1 : value1,
                    key2 : value2,
                    key3 : [
                        world1,
                        world2,
                        world3
                    ]
                }
            ]
            """
        XCTAssertEqual(pretty, array.indentedDescription)
    }
    
    func testCharacters() {
        let precomposed: Character = "\u{D55C}"                  // 한
        let decomposed: Character = "\u{1112}\u{1161}\u{11AB}"   // ᄒ, ᅡ, ᆫ
        XCTAssertEqual(precomposed, decomposed)
        let str = "\u{1112}\u{1161}\u{11AB}"
        XCTAssertEqual(str.count, 1)
        let chars: [Character] = ["\u{1112}","\u{1161}", "\u{11AB}"]
        let str2 = String(chars)
        XCTAssertEqual(str2.count, 1)
    }
    
    func testStringSorting() {
        let array1 = [1,  3,4,  6]
        let array2 = [1,2,3,  5,6,7,8]
        var same = [Int]()
        var missing1 = [Int]()
        var missing2 = [Int]()
        compareInOrders(array1, array2) { a, b in
            switch a - b {
            case 0: return .orderedSame
            case let x where x < 0: return .orderedAscending
            default: return .orderedDescending
            }
        } matching: { a, b in
            XCTAssertEqual(a, b)
            same.append(a)
        } ahsMissing: { b in
            missing1.append(b)
        } bhsMissing: { a in
            missing2.append(a)
        }
        XCTAssertEqual(same, [1,3,6])
        XCTAssertEqual(missing1, [2,5,7,8])
        XCTAssertEqual(missing2, [4])
    }
    
    func testEscapingCharacters() {
        let str = """
        hello "star"
        """
        let s0 = """
        "hello \\"star\\""
        """
        
        let s1 = str.wrappingDoubleQuotes
        XCTAssertEqual(s1, s0)
        let s2 = s1.trimingDoubleQuotes
        XCTAssertEqual(s2, str)
        
        let precomposed = "abc\u{D55C}1234" // 한
        XCTAssertEqual(precomposed.transformingEscapeCharacters, "abc한1234")
        
        let pairs = [
            ("h\n", "h\\x0a"), 
            ("h\n", "h\\u0a"), 
            ("h\n", "h\\u{0a}"), 
            ("\nhello", "\\x0ahello"), 
            ("\n", "\\x0a"),
            ("\n", "\\012"),
            ("\\\"", DoubleQuote),
            ("\u{1112}\u{1161}\u{11AB}", "\u{D55C}")
        ]
        for (a, b) in pairs {
            XCTAssertEqual(a.transformingEscapeCharacters, b.transformingEscapeCharacters)
        }
        let failures = [
            "", "0", "a",
            "\\", "\\(", "(\\",
            "h\\0",
            "\\g",
            "abcdd\\",
            "h\\u{0}",
            "h\\u{0a",
            "h\\u{0acfepp",
            "h\\uhhh0a",
            "h\\xTOKJLK",
            "\\0UFKFL",
            "FABD\\*UFKFL",
        ]
        failures.forEach { s in
            XCTAssertEqual(s, s.transformingEscapeCharacters)
        }
    }
}

enum ConnectResult: Int, Error, CaseIterable {
    case failed = -101, crashed = -102, successed = 0
}


enum ReadResult: Error, CaseIterable {
    case successed, nothing, unrecognized
}

struct MyResult: Error {
    var tip: String
}
class MyResult2: Error { }
