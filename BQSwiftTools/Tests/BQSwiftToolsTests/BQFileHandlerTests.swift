
import XCTest
@testable import BQSwiftTools


class BQFileHandlerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStringFile() throws {
        let ext = "txt"
        let fileNameNoExt = "mytest"
        let fileName = fileNameNoExt + "." + ext
        XCTAssertEqual("".appendingFileName(fileName), fileName)
        XCTAssertEqual(fileName.fileName, fileName)
        XCTAssertEqual(fileName.fileNameWithoutExt, fileNameNoExt)
        XCTAssertEqual(fileName.fileExtension, ext)
        XCTAssertEqual(fileName.fileUrl.filePath, fileName)

        let fileName2 = fileNameNoExt + ext
        XCTAssertEqual(fileName2.fileName, fileName2)
        XCTAssertEqual(fileName2.fileNameWithoutExt, fileName2)
        XCTAssertEqual(fileName2.fileExtension, "")

        
        let path = "/Users/beiqi/hello/documents"
        let filePath = path.appendingFileName(fileName)
        XCTAssertEqual(path+"/" + fileName, (path + "/").appendingFileName(fileName))
        XCTAssertEqual(path+"/" + fileName, filePath)
        XCTAssertEqual(filePath.fileName, fileName)
        XCTAssertEqual(filePath.fileNameWithoutExt, fileNameNoExt)
        XCTAssertEqual(filePath.parentDirectory, path)
        XCTAssertEqual(filePath.parentFileName, "documents")
        XCTAssertEqual(filePath.fileUrl.filePath, filePath)
        
        let spc = "/hello"
        XCTAssertEqual(spc.parentDirectory, "/")
        XCTAssertEqual(spc.parentDirectory.parentDirectory, "/")
        XCTAssertEqual(spc.parentDirectory.parentDirectory.parentDirectory, "/")
        
        XCTAssertEqual("".notEmpty, nil)
        XCTAssertEqual(spc.notEmpty, spc)
        XCTAssertTrue(spc.isASCIIstring)
        XCTAssertFalse("wwok✘wwok✘".isASCIIstring)
        
        XCTAssertEqual(" line1 \n \n   \nline2\n".allValidLines, ["line1", "line2"])
    }

    
    func testCommandLines() {
        let cmd = "./test.o try to compile -o /param/asdfk/kdjadfk.k woment ok --path /Users/beiqi/hello/documents -v -asdfk --help "
        let myp = CmdParams(cmdArguments: cmd.split(separator: " ").map({ $0.description }))
        XCTAssertEqual(myp.executingFile, "./test.o")
        XCTAssertTrue(!myp.contains(flag: "victory") && myp.contains(flag: "v") && myp.contains(flexibleFlag: "victory"))
        XCTAssertTrue(!myp.contains(flag: "asdfk") && myp.contains(flag: "a") && myp.contains(flexibleFlag: "asdfk"))
        XCTAssertTrue(myp.contains(flag: "help") && !myp.contains(flexibleFlag: "h"))
        XCTAssertEqual(myp.value(forFlexibleKey: "path"), "/Users/beiqi/hello/documents")
        XCTAssertEqual(myp.value(forShortKey: "o"), "/param/asdfk/kdjadfk.k")
        XCTAssertEqual(myp.others[0], "try")
        XCTAssertEqual(myp.others[3], "woment")
        XCTAssertEqual(myp.others[4], "ok")
    }

    /*
    func testFileItemHandler() {
        let bdl = Bundle(for: type(of: self))
        guard let f = bdl.path(forResource: "directs", ofType: "txt") else {
            XCTAssertFalse(true, "canot read directs.txt");  return
        }
        do {
            let txts = try String(contentsOfFile: f)
            let allFiles = txts.allValidLines
            let fh = FileItemPrinter(directoryFlag: "").filter.fill(files: ["strings", "swift"].fileExtMatching()).onlyFiles()
                .onlyCodeResFiles().ignoreHiddenFiles()
            allFiles.fileIterator.start(fh)
        } catch {
            XCTAssertFalse(true, "canot read directs.txt")
        }
    }
    */
    
    func testFileItemHandlerHiddens() {
        let clcts = CollectFiles()
        let files = [
            "./.DS_Store",
            "./.git/",
            "./.git/.DS_Store",
            "./.git/CouponGoodsCCell.strings",
            "./CouponGoodsCCell.strings",
            "./Merchant_version/",
            "./Merchant_version/CouponTypePickerVC.strings",
        ]
        files.fileIterator.start(FileItemFilters(handler: clcts).ignoreHiddenFiles())
        XCTAssertEqual(clcts.allFiles, [
            "./CouponGoodsCCell.strings",
            "./Merchant_version/",
            "./Merchant_version/CouponTypePickerVC.strings",
        ])
    }
    func testFileItemExt() {
        let clcts = CollectFiles()
        let files = [
            "./.DS_Store",
            "./.git/",
            "./.git/.DS_Store",
            "./.git/CouponGoodsCCell.strings",
            "./CouponGoodsCCell.strings",
            "./Merchant_version/",
            "./Merchant_version/CouponTypePickerVC.strings",
        ]
        files.fileIterator.start(FileItemFilters(handler: clcts)
                                    .onlyFiles()
                                    .fill(files: "strings".fileExtMatching()))
        XCTAssertEqual(clcts.allFiles, [
            "./.git/CouponGoodsCCell.strings",
            "./CouponGoodsCCell.strings",
            "./Merchant_version/CouponTypePickerVC.strings",
        ])
    }
    func testFileItemIgnore() {
        let clcts = CollectFiles()
        let files = [
            "./.DS_Store",
            "./.git/",
            "./.git/.DS_Store",
            "./.git/CouponGoodsCCell.strings",
            "./CouponGoodsCCell.strings",
            "./Merchant_version/",
            "./Merchant_version/CouponTypePickerVC.strings",
        ]
        files.fileIterator.start(FileItemFilters(handler: clcts)
                                    .ignore(dirs: [".git", "Merchant_version"].fileNameMatching())
                                    .onlyFiles())
        XCTAssertEqual(clcts.allFiles, [
            "./.DS_Store",
            "./CouponGoodsCCell.strings",
        ])
    }

    func testFileItemHandlerDirs() {
        let clcts = CollectFiles()
        let files = [
            "./.DS_Store",
            "./.git/",
            "./.git/.DS_Store",
            "./.git/CouponGoodsCCell.strings",
            "./CouponGoodsCCell.strings",
            "./Merchant_version/",
            "./Merchant_version/CouponTypePickerVC.strings",
            "./Merchant_version/CouponTypePickerVC.xib",
            "./Merchant_version/hello/",
        ]
        files.fileIterator.start(FileItemFilters(handler: clcts).onlyDirs())
        XCTAssertEqual(clcts.allFiles, [
            "./.git/",
            "./Merchant_version/",
            "./Merchant_version/hello/",
        ])
    }
}


extension String {
    var isDirectory: Bool { hasSuffix("/") }
}

class TestFilesIterator: IteratorProtocol, FileEnm {
    var files: [String]
    var root: String
    init(files ls: [String], root r: String) {
        files = ls; root = r
    }
    
    private var currentIdx: Int = -1
    private var current: String? { 0 <= currentIdx && currentIdx < files.count ? files[currentIdx] : nil }
    
    var isDirectory: Bool { current?.isDirectory ?? false }
    
    func next() -> String? { currentIdx += 1;  return current }
    
    func skipDescendants() {
        guard let p = current, p.isDirectory else { return }
        var nextIdx = currentIdx + 1
        while nextIdx < files.count && files[nextIdx].hasPrefix(p) {
            currentIdx += 1; nextIdx += 1
        }
    }
    
    func start(_ h: FileItemHandler) {
        while let item = next() {
            h.handle(item: item, isDirectory: item.isDirectory, at: root, fileEnm: self)
        }
    }
}

extension Array where Element == String {
    var fileIterator: TestFilesIterator { TestFilesIterator(files: self, root: "/root/test") }
}

class CollectFiles: FileItemHandler {
    var allFiles = [String]()
    
    func handle(item: String, isDirectory: Bool, at path: String, fileEnm: FileEnm) {
        allFiles.append(item)
    }
}
