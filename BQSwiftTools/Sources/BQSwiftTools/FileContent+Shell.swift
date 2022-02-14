//
//  FileContent+Shell.swift
//  ShellTool
//
//  Created by Beiqi on 2021/10/18.
//

import Foundation
import BQFoundationTool

public enum Action: String, CaseIterable {
    case mergePairs
    case checkPairs
    case collectStrings
    case replaceStrings
    case localizeCodes
}

public enum ParamKey: String {
    case exts, languages, patterns, ellipsis, keyPaths, property, translatedFiles, TranslatedFilesRegExp
}

public extension Action {
    
    static var helpDescription: String { """
    \(CommonParamKey.helpDescription)
    
    * actions:
    
        mergePairs
            merge 2 inputing-files into 1 file, formatted by mapping two lines in order.
            (Lines will be removed which is empty after trimming white-spaces).
    
            eg:
            -- file1 --     &    -- file2 --    =>     ---- output ---- 
            key0                 value0                "key0" = "value0";
            key1                 value1                "key1" = "value1";
            key2                 value2                "key2" = "value2";
            ...                  ...                   ...

    
        checkPairs
            check strings-file for repeated/missing keys and difference between languages.
            
            -l, --languages
                localized languages (Xcode project created xxx.lproj directories, such as: en,id)

    
        collectStrings
            collect matched strings (default is for double-quoted), and save to outputs.
            
            -l, --languages
                localized languages (Xcode project created xxx.lproj directories, such as: en,id)
    
            --exts
                file extensions, default: strings    eg: strings,xib,swift
    
            --patterns
                search middle contents of ellipsis-place (prefix...suffix).  eg: "...",'...'
    
            --ellipsis
                default: ...
    
            --keyPaths
                only value for keyPath (in xib-files). eg: vcTitle,joinedTitles
    
    
        replaceStrings
            replace values in xxx.strings with translated-values in translatedFiles, mapping with the same values.
    
            -l, --languages
                localized languages (Xcode project created xxx.lproj directories, such as: en,id).
                Or you can specify language-value in translated-file-name as prefix or suffix. 
                such as en_translated.txt, translated_en.txt
    
            -t, --translatedFiles
            -T, --TranslatedFilesRegExp
                Which contents should be formated by key-value pairs. 
                When --languages is absent, will detect language-value of file name, such as en for en_trans.txt
                Files will relative to current working path.
    
        localizeCodes
            localize strings in code-files. for example: "xx" will be "xx".localized; but "xx".localized keep the same
    
            --exts
                file extensions, eg: swift,m,cpp (default is swift)
    
            --property
                localized property name that implemented with code, eg: localized (which is default value)
    
    """    
    }
}

public func printHelp() {
    print(Action.helpDescription)
}

public func mainFunc(_ param: CmdParams) {
    guard let actValue = param.others.first, let action = Action(rawValue: actValue) else { printHelp(); return }
    switch action {
    case .mergePairs:       mergePairs(param)
    case .checkPairs:       checkPairs(param)
    case .collectStrings:   collectStrings(param)
    case .replaceStrings:   replaceStrings(param)
    case .localizeCodes:    localizeCodes(param)
    }
}


public func mergePairs(_ param: CmdParams) {
    var repeatN: Int = 0
    var tmpKeys: [String]?
    let txter = FileItemTexter { content, file in
        let lines = content.allValidLines
        guard !lines.isEmpty else { return }
        guard let keys = tmpKeys else { tmpKeys = lines; return }
        
        let minCount = min(keys.count, lines.count)
        var dic = [String: String](); dic.reserveCapacity(minCount)
        for i in 0 ..< minCount {
            if let v = dic.updateValue(lines[i], forKey: keys[i]), v != lines[i] {
                print("conflict value (%@), (%@) for key (%@)", v, lines[i], keys[i])
            }
        }
        let path = param.output(fileName: "mergingPairs.txt", repeat: repeatN)
        dic.sortedPairStrings.writeSafely(toFile: path); repeatN += 1; tmpKeys = nil
        guard keys.count != lines.count else { return }
        let mores = minCount < keys.count ? keys[minCount...] : lines[minCount...]
        print("could not pair for : \(mores)")
    }
    param.searchFiles(with: txter.filter.onlyFiles())
}

public func checkPairs(_ param: CmdParams) {
    // 1. 比对strings文件内是否有重复key
    print("...... checking single file.strings ......")
    let singleFile = FileItemTexter { content, file in
        print("reading: ", file.filePath ?? "")
        let (_, repeats) = content.allQuotedStringInPairs(includingQuotes: true)
        for (k, sets) in repeats {
            if sets.count > 1 { 
                print("conflicts key: \(k)      multi-values: \(sets.joined(separator: ","))")
            } else {
                print("repeats   key: \(k)")
            }
        }
    }.filter.onlyCodeResFiles().only(file: .strings)
    param.searchFiles(with: singleFile)
    
    let langs = param.languages ?? Array(param.searchLanguages())
    guard 2 <= langs.count else { return }
    
    // 2.1 收集各语言环境下的strings文件
    print("...... collecting all-languages file.strings ......")
    var fileName2Path = [String:[String]]()
    let cates = FileItemBlocker { item, isDirectory, path, enm in
        let name = item.fileName
        if fileName2Path[name] == nil {
            fileName2Path[name] = [path + item]
        } else {
            fileName2Path[name]!.append(path + item)
        }
    }.filter.onlyCodeResFiles().fill(dir: .lproj).only(file: .strings)
    param.searchFiles(with: cates)
    
    // 2.2 比对各语言版本的strings文件
    print("...... comparing all-languages file.strings ......")
    let langDirts = langs.map { $0 + ".lproj/" }.sorted()
    let fnItems = fileName2Path.map { ($0.key, $0.value.sorted()) }
    for (fn, files) in fnItems {
        let all: [(pairs: [String:String], lan: String)]  = files.compactMap {
            guard let ct = String(readSafely: $0) else { return nil }
            let pairs = ct.allQuotedStringInPairs(includingQuotes: true).pairs
            return pairs.isEmpty ? nil : (pairs, $0.parentFileName)
        }
        print(" .. \(fn) .. ")

        guard !all.isEmpty else { print("    can't read files, or files has no strings ~ "); continue }
        
        // check missing file for languages
        compareInOrders(langDirts, all, compareBy: { $0.compare($1.lan) }, bsqMissing: { print("    missing file for \($0)") })
        
        guard 1 < all.count else { continue }
        let firstKeys = all.first!.pairs.keys
        var maxKeys = Set<String>(firstKeys)
        var minKeys = Set<String>(firstKeys)
        all.dropFirst().forEach {
            let kys = $0.pairs.keys
            maxKeys.formUnion(kys)
            minKeys.formIntersection(kys)
        }
        
        // check missing keys
        for (pairs, lan) in all {
            let missing = maxKeys.subtracting(pairs.keys)
            if !missing.isEmpty { print("    \(lan) missing keys: \(missing)") }
        }
        
        // check same-value keys
        var expectedVs = Set<String>()
        expectedVs.reserveCapacity(all.count)
        for k in minKeys {
            expectedVs.removeAll()
            all.forEach { expectedVs.insert($0.pairs[k]!) }
            guard expectedVs.count >= all.count else { continue }
            print("    \(k)   has same values")
        }
    }
}

class LocalStrings {
    var language: String
    var strings: Set<String> = []
    init(language: String) {
        self.language = language
    }
}

class CollectedResult {
    var locals = [LocalStrings]()
    var xibStrings   = Set<String>()
    var codeStrings  = Set<String>()
    var otherStrings = Set<String>()
    
    func localStrings(ofLanguage lan: String) -> LocalStrings {
        var ls: LocalStrings! = locals.first { $0.language == lan }
        guard ls == nil else { return ls }
        ls = LocalStrings(language: lan)
        locals.append(ls)
        return ls
    }
}

public func collectStrings(_ param: CmdParams) {
    var pairTkObjs: [PairTokenObj]?
    do {
        pairTkObjs = try param.pairTokensOfPatterns()
    } catch {
        print(error); return
    }

    var exts = param.exts ?? []
    if exts.isEmpty || exts.remove(.strings) > 0 {
        pairTkObjs?.insert(contentsOf: [.commentMultiLines, .commentSingleLine], at: 0)
        collectStringsForStringsFile(param, patterns: pairTkObjs)
    }
    if exts.remove(.xib) > 0 {
        collectStringsForXibFile(param, patterns: pairTkObjs)
    }
    
    guard !exts.isEmpty else { return }
    pairTkObjs = pairTkObjs ?? [.quotes]
    let codeExts = FileExt.forCodes.map { $0.rawValue }
    if Set(codeExts).intersection(exts).count > 0 {
        pairTkObjs?.insert(contentsOf: [.commentMultiLines, .commentSingleLine], at: 0)
    }
    collectStringsForOthersFile(param, patterns: pairTkObjs, exts: exts)
}

func collectStringsForStringsFile(_ param: CmdParams, patterns: [PairTokenObj]?) {
    let languages = param.languages ?? Array(param.searchLanguages())
    for lan in languages {
        var allValues = Set<String>()
        let noPatters = patterns?.isEmpty ?? true
        let txter = noPatters ? FileItemTexter { content, file in
            let (pairs, repeats) = content.allQuotedStringInPairs(includingQuotes: false)
            allValues.formUnion(pairs.values)
            guard !repeats.isEmpty else { return }
            allValues.formUnion(repeats.values.flatMap { $0 })
            print("\(file.lastPathComponent) has repeat key-values: \(repeats)")
        } : FileItemTexter { content, file in
            let vs = content.startParsing(patterns!).string(of: content)
            allValues.formUnion(vs)
        }
        let filter = txter.filter
            .onlyCodeResFiles()
            .fill(dirs: [lan + .lproj])
            .only(file: .strings)
        param.searchFiles(with: filter)
        
        let outPath = param.output(fileName: "all_strings.txt", suffix: "_" + lan)
        allValues.sortedLines.writeSafely(toFile: outPath)
        print("total \(allValues.count) strings")
    }
}

func collectStringsForXibFile(_ param: CmdParams, patterns: [PairTokenObj]?) {
    var allPatterns = patterns ?? []
    if let tks = param.pairTokensOfKeyPath() {
        allPatterns.append(contentsOf: tks)
    } 
    guard !allPatterns.isEmpty else {
        print("please input --keyPaths or --patterns for xib");  return
    }
    var allValues = Set<String>()
    let texter = FileItemTexter { content, file in
        let vs = content.startParsing(allPatterns).string(of: content)
        allValues.formUnion(vs)
    }
    param.searchFiles(with: texter.filter.onlyCodeResFiles().only(file: .xib))

    let outPath = param.output(fileName: "all_values_xib.txt", suffix: "")
    allValues.sortedLines.writeSafely(toFile: outPath)
    print("total \(allValues.count) strings")
}

func collectStringsForOthersFile(_ param: CmdParams, patterns: [PairTokenObj]?, exts: [String]) {
    guard let patterns = patterns, !patterns.isEmpty else {
        print("please input --patterns ");  return
    }
    patterns.forEach { let _ = $0.customResult(.onlyContents) }
    var allValues = Set<String>()
    let texter = FileItemTexter { content, file in
        let vs = content.startParsing(patterns).string(of: content)
        allValues.formUnion(vs)
    }
    param.searchFiles(with: texter.filter.onlyCodeResFiles().onlyFiles().fill(files: exts.fileExtMatching()))

    let outPath = param.output(fileName: "all_searched.txt", suffix: "")
    allValues.sortedLines.writeSafely(toFile: outPath)
    print("total \(allValues.count) strings")
}


public func replaceStrings(_ param: CmdParams) {
    guard let translatedFiles = param.searchTranslatedFiles() else {
        print("missing translated files."); return
    }
    
    let langs = param.languages ?? []
    if langs.isEmpty {
        let allLans = param.searchLanguages()
        guard allLans.count > 0 else { print("not found xxx.lproj"); return }
        translatedFiles.forEach({ lanFile in
            guard let lan = CmdParams.detectLanguage(forFile: lanFile, allLanguages: allLans)
            else { print("not found languages-fix for file: ", lanFile); return }
            param.searchAndReplace(withTranslated: lanFile, language: lan)
        })
    } else if langs.count == 1 {
        param.searchAndReplace(withTranslated: translatedFiles, language: langs[0])
    } else if langs.count == translatedFiles.count {
        for (i, file) in translatedFiles.enumerated() {
            param.searchAndReplace(withTranslated: file, language: langs[i])
        }
    } else {
        print("translated-files is not matching with languages")
    }
}

public func localizeCodes(_ param: CmdParams) {
    guard let prp = param.value(forKey: .property) else { 
        print("not found --", ParamKey.property.rawValue); return
    }
    let sfx = "." + prp
    let ext = param.exts ?? ["swift"]
    let filter = FileItemBlocker { item, isDirectory, path, _ in
        let file = path.appendingFileName(item)
        guard var content = String(readSafely: file) else { return }
        guard content.insertLocalized(suffix: sfx) else { return }
        content.writeSafely(toFile: file)
    }.filter.fill(files: ext.fileExtMatching()).onlyFiles()
    param.searchFiles(with: filter)
}



extension CmdParams {
    
    func searchFiles(with blk: @escaping FileItemBlocker.FIBlock) {
        searchFiles(with: FileItemBlocker(blk))
    }
    
    func searchFiles(with handler: FileItemHandler) {
        searchFiles(with: FileItemFilters(handler: handler).ignoreHiddenFiles())
    }
    
    func searchFiles(with filters: FileItemFilters) {
        if let allFiles = files, !allFiles.isEmpty {
            filters.startWorking(atDirectory: defaultPath, files: allFiles)
        } else if let regFiles = FilesRegExp {
            do {
                let match = try regFiles.fileNameRegExpMatching()
                let _ = filters.fill(files: match)
                filters.startWorking(atDirectory: defaultPath)
            } catch {
                print("failed to analyze regular expression: \(error)")
            }
        } else {
            filters.startWorking(atDirectory: defaultPath)
        }
    }
    
    func searchLanguages() -> Set<String> {
        XcodeProjLanguages().find(at: defaultPath)
    }
    
    
    func value(forKey param: ParamKey) -> String? {
        switch param {
        case .languages, .translatedFiles, .TranslatedFilesRegExp:
            return value(forFlexibleKey: param.rawValue)
        case .exts, .patterns, .ellipsis, .keyPaths, .property:
            return value(forLongKey: param.rawValue)
        }
    }
    func componentsOfValue(forKey param: ParamKey) -> [String]? {
        guard let vs = value(forKey: param) else { return nil }
        let list = vs.components(separatedBy: separator).compactMap({ $0.notEmpty })
        return list.isEmpty ? nil : list
    }
    
    
    var exts: [String]? { componentsOfValue(forKey: .exts) }
    var languages: [String]? { componentsOfValue(forKey: .languages) }
    var patterns: [String]? { componentsOfValue(forKey: .patterns) }
    var ellipsis: String { value(forKey: .ellipsis) ?? "..." }
    var keyPaths: [String]? { componentsOfValue(forKey: .keyPaths) }
    var property: String { value(forKey: .property) ?? "localized" }
    
    
    func pairTokensOfPatterns() throws -> [PairTokenObj]? {
        guard let patterns = patterns else { return nil }
        let spt = ellipsis
        return try patterns.map {
            let ps = $0.components(separatedBy: spt)
            guard ps.count == 2, let prefix = ps[0].notEmpty, let suffix = ps[1].notEmpty
                else { throw "~~ invalid patterns: \(ps), need valid prefix & suffix" }
            return PairTokenObj(prefix, suffix)!.customResult(.onlyContents)
        }
    }
    
    func pairTokensOfKeyPath() -> [PairTokenObj]? {
        guard let keyPaths = keyPaths else { return nil }
        return keyPaths.map { PairTokenObj("\($0)\" value=\"", "\"")!.customResult(.onlyContents) }
    }     

    func searchTranslatedFiles() -> [String]? {
        let files = componentsOfValue(forKey: .translatedFiles)
        guard files == nil else {
            return files!.map { expand(inputFile: $0) }.sorted()
        }
        
        let regFiles = componentsOfValue(forKey: .TranslatedFilesRegExp)
        guard let regFiles = regFiles else { return nil }
        
        var allFiles = Set<String>()
        regFiles.forEach { reg in
            do {
                let path = expand(inputFile: reg)
                let regExp = try path.fileName.fileNameRegExpMatching()
                let dir = path.parentDirectory
                FileItemBlocker { item, isDirectory, path, _ in
                    allFiles.insert(dir.appendingFileName(item))
                }.filter.onlyFiles().fill(files: regExp)
                    .startWorking(atDirectory: dir)
            } catch {
                print("failed to create reg expression for: ", reg, "\(error)")
            }
        }
        return allFiles.isEmpty ? nil : allFiles.sorted()
    }
    
    func searchAndReplace(withTranslated info: TranslatedInfo, language: String) {
        let (dic, hasQuotes) = info
        guard dic.count > 0 else { print("not found translated pairs"); return }
        let dirName = language + DirectoryExt.lproj
        let filter = FileItemTexter { content, file in
            var src = content
            if src.replaceQuotes(includingQuotes: hasQuotes, with: dic) {
                src.writeSafely(to: file)
            }
        } .filter.fill(dirs: dirName.fileNameMatching()).only(file: .strings)
        searchFiles(with: filter)
    }
    
    func searchAndReplace(withTranslated file: String, language: String) {
        searchAndReplace(withTranslated: [file], language: language)
    }
    func searchAndReplace(withTranslated files: [String], language: String) {
        let hasQuotes = true
        var allDic = [String:String]()
        var allRepeats = [String: Set<String>]()
        for file in files {
            guard let ct = String(readSafely: file) else { continue }
            let (dic, repeats) = ct.allQuotedStringInPairs(includingQuotes: hasQuotes)
            if !repeats.isEmpty {
                allRepeats.merge(repeats) { $0.union($1) }
            }
            for (k, v) in dic {
                if let ov = allDic.updateValue(v, forKey: k), ov != v {
                    allRepeats.formUnion(value: v, forKey: k, initialValue: ov)
                }
            }
        }
        let (repeats, conflicted) = allRepeats.checkSubset()
        if repeats.count > 0 { print("repeated translations: ", repeats) }
        if conflicted.count > 0 { 
            let ps = conflicted.keys.map { ($0, allDic[$0]!) }
            print("conflicted translations: ", conflicted)
            print("adopt translations: ", Dictionary(uniqueKeysWithValues: ps))
        }

        searchAndReplace(withTranslated: (allDic, hasQuotes), language: language)
    }
    
    static func detectLanguage(forFile file: String, allLanguages: Set<String>) -> String? {
        let name = file.fileNameWithoutExt
        return allLanguages.first { name.hasPrefix($0) || name.hasSuffix($0) }
    }
}

typealias TranslatedInfo = (map: [String:String], includingQuotes: Bool)

extension String: Error {}


