import XCTest
@testable import BQSwiftTools

final class BQSwiftToolsTests: XCTestCase {

    @available(iOS 10.0, *)
    func testCmdParams() throws {
        let outpath = FileManager.default.temporaryDirectory.filePath ?? "/Users/beiqi/output/"
        let args = [
            "/Users/beiqi/test.script",
            "action",
            "--out", outpath,
            "-p", "./demo/",
            "--f", "hello.txt,world.txt,,",
            "-F", ",",
            "something_others",
            "...description...",
            "--type", "testing",
            "--shouldprint", "-t",
            "-vHs",
        ]
        let cmd = CmdParams(cmdArguments: args)
        XCTAssertEqual(cmd.executingFile, args[0])
        XCTAssertEqual(cmd.others, ["action", "something_others", "...description..."])
        XCTAssertEqual(cmd.longKVs, ["out":outpath, "type":"testing"])
        XCTAssertEqual(cmd.shortKVs, ["p":"./demo/", "f":"hello.txt,world.txt,,", "F":","])
        XCTAssertEqual(cmd.longFlags, ["shouldprint"])
        XCTAssertEqual(cmd.shortFlags, Set(["t", "v", "H", "s"]))
        
        XCTAssertEqual(cmd.separator, ",")
        XCTAssertEqual(cmd.FilesRegExp, nil)
        XCTAssertEqual(cmd.files, ["hello.txt", "world.txt"])

        XCTAssertTrue(cmd.contains(flag: "H"))
        XCTAssertTrue(cmd.contains(flag: "t"))
        XCTAssertFalse(cmd.contains(flag: "out"))
        XCTAssertFalse(cmd.contains(flag: "h"))
        XCTAssertFalse(cmd.contains(flag: "vHs"))

        XCTAssertTrue(cmd.contains(flag: "H"))
        XCTAssertTrue(cmd.contains(flag: "s"))
        
        let crtDir = cmd.currentDirectory
        XCTAssertEqual(cmd.inputPath, crtDir.appendingFileName("./demo/"))
        XCTAssertEqual(cmd.outputPath, outpath)
        XCTAssertEqual(cmd.expand(inputFile: "file"), crtDir.appendingFileName("./demo/file"))
        XCTAssertEqual(cmd.expand(outputFile: "saving.txt"), outpath.appendingFileName("saving.txt"))
        XCTAssertEqual(cmd.outputFile(expected: "saving.txt"), outpath.appendingFileName("saving.txt"))
        
        var tmpPath = cmd.outputFile(expected: "saving.txt", overwrite: true)
        "hello".writeSafely(toFile: tmpPath)
        tmpPath = tmpPath.parentDirectory.appendingFileName("saving_1.txt")
        try? FileManager.default.removeItem(atPath: tmpPath)
        tmpPath = cmd.outputFile(expected: "saving.txt", overwrite: false)
        XCTAssertEqual(tmpPath, outpath.appendingFileName("saving_1.txt"))
        "hello".writeSafely(toFile: tmpPath)
        tmpPath = tmpPath.parentDirectory.appendingFileName("saving_2.txt")
        try? FileManager.default.removeItem(atPath: tmpPath)
        tmpPath = cmd.outputFile(expected: "saving.txt", overwrite: false)
        XCTAssertEqual(tmpPath, outpath.appendingFileName("saving_2.txt"))

        tmpPath = cmd.outputFile(expected: "saving_1.txt", overwrite: false)
        XCTAssertEqual(tmpPath, outpath.appendingFileName("saving_2.txt"))
    }
    
    
}
