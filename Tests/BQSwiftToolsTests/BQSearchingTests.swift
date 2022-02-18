
import XCTest
@testable import BQSwiftTools

class BQSearchingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let rg = 5 ..< 5
        for i in rg { 
            XCTAssertEqual(0, i)
        }
        /** // crash
         let rg2 = try 6 ..< 5
         for i in rg2 { print(i) }
         */
    }

    func testCircleRange() throws {
        var rg = CircleRange(begin: 0, size:3)!
        XCTAssertTrue(IteratorSequence(rg).elementsEqual(0..<3))
        rg = CircleRange(begin: 1, size:3)!
        XCTAssertTrue(IteratorSequence(rg).elementsEqual([1,2,0]))
        rg = CircleRange(begin: 2, size:3)!
        XCTAssertTrue(IteratorSequence(rg).elementsEqual([2,0,1]))
        rg = CircleRange(begin: 0, size:1)!
        XCTAssertTrue(IteratorSequence(rg).elementsEqual([0]))
    }
    
    func testDefers() {
        let eg = TestExample()
        XCTAssertEqual(eg.increaseValueLater(3), 3)
        XCTAssertEqual(eg.value, 1)
        XCTAssertEqual(eg.trySwitch(1), 1)
        XCTAssertEqual(eg.value, 0)
        XCTAssertEqual(eg.trySwitch(2), 0)
        XCTAssertEqual(eg.value, 0)
        XCTAssertEqual(eg.trySwitch(3), 3)
        XCTAssertEqual(eg.value, 3)
    }
    
    func testStride() {
        let array = stride(from: 0, through: 3, by: 1).map { $0 }
        XCTAssertEqual(array, [0, 1, 2, 3])
        let array2 = stride(from: 0, to: 3, by: 1).map { $0 }
        XCTAssertEqual(array2, [0, 1, 2])
        
    }
    func testKMP() {
        let chars = Array("abab")
        let idxes = chars.nextIndexesKMP
        XCTAssertEqual(idxes, [-1,0,-1,0])
    }
    
    func testSearch() {
        var src = ParsingSource(content: "abacababcabacababc")
        var res = src.startParsing(TokenObj("abab")!)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res.substrings(of: src.content), ["abab", "abab"])
        
        src = ParsingSource(content: "aabbccddeeffaabbaabbccddeeffabbc")
        res = src.startParsing(TokenObj("abbc")!)
        XCTAssertEqual(res.count, 3)
        XCTAssertEqual(res.substrings(of: src.content), ["abbc", "abbc", "abbc"])

        src = ParsingSource(content: "aaaabbbbccccaaaabbbccccaaaabbbbc")
        res = src.startParsing(TokenObj("aaaabbbb")!)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res.substrings(of: src.content), ["aaaabbbb", "aaaabbbb"])

    }
    
    func testSearching() {
        var src = ParsingSource(content: testSearchingText)
        let res1 = src.startParsing(PairTokenObj.quotes)
        let subs1 = res1.substrings(of: src.content)
        let res2 = src.startParsing([PairTokenObj.commentSingleLine, PairTokenObj.commentMultiLines, PairTokenObj.quotes])
        let subs2 = res2.substrings(of: src.content)
        XCTAssert(subs1.count >= subs2.count)
        var i = 0; var j = 0
        while i < subs1.count, j < subs2.count {
            if subs1[i] == subs2[j] { i += 1; j += 1 }
            else { i += 1 }
        }
        XCTAssert(i == res1.count && j == res2.count)
    }
    
    var testSearchingText: String {
        return """
//
//  SettingViewController.swift
//  ChengXiaoYue
//
//  Created by Beiqi xu on 2020/7/3.
//  Copyright © 2020 SendaBox. All rights reserved.
//

import UIKit
import YYWebImage
import OverseasAccount
import FoundationTool

struct AppItemInfo: Codable {
    var releaseNotes: String?
    var version: String?
}

struct AppleAppInfo: Codable {
    var resultCount: Int
    var results: [AppItemInfo]
}
/*
extension String {
    func versionsCompareTo(_ v: String) -> Int {
        let vcs1 = split(separator: ".")
        let vcs2 = v.split(separator: ".")
        let c1 = vcs1.count; let c2 = vcs2.count
        for idx in 0 ..< min(c1, c2) {
            switch (Int(vcs1[idx]) ?? 0) - (Int(vcs2[idx]) ?? 0) {
            case 0: continue
            case (let x) where x > 0: return 1
            case (let x) where x < 0: return -1
            default: break
            }
        }
        return c1 - c2
    }
}

class SettingViewController: UIViewController {

    fileprivate var appId: String { "1525861322" }
    fileprivate var appURI: String { "https://itunes.apple.com/cn/lookup?id=" + appId }
    fileprivate var appWeb: String { "https://itunes.apple.com/cn/app/id" + appId }
    
    @IBOutlet fileprivate weak var newVersionItemV: UIControl!
    @IBOutlet fileprivate weak var logoutV: UIControl!
    @IBOutlet fileprivate weak var serverAdrLb: UILabel!
    @IBOutlet fileprivate weak var serverAdrSpaceV: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLb.text = nil
        if let v = newVersionItemV, v.isShown {
            checkNewVersion()
        }
        languageLb.text = "uilanguage".localized
        logoutV.isShown = LoginUser.isLogined
        
        #if Intranet
        let show = true
        #else
        let show = LoginUser.current?.isMyselfInWhiteList ?? false || AppServerArea.hasBeenModified
        #endif
        serverAdrSpaceV.isShown = show
        serverAdrLb.superview?.isShown = show
        guard show else { return }
        serverAdrLb.text = AppServerArea.current.rawValue
    }
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavBar(false)
        updateCacheLb()
    }
    
    fileprivate var appItemInfo: AppItemInfo?
    fileprivate func updateVersionTip() {
        guard isViewLoaded, view.superview != nil else { return }
        guard let info = appItemInfo, let newV = info.version else { versionLb.text = nil; return }
        let v = DeviceAppInfo.appInfo.bundleVersion
        let hasNew = v.versionsCompareTo(newV) < 0
        versionLb.text = hasNew ? "有新版本".localized : "已是最新".localized
        guard hasNew, let notes = info.releaseNotes?.notEmpty else { return }
        let vc = UIAlertController(title: "新版本".localized, message: notes, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "确定".localized, style: .default, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    

    fileprivate func checkNewVersion() {
        let task = URLSession.shared.dataTask(with: appURI.webUrl!) {[weak self] (data, rsp, e) in
            guard let data = data, e.isSuccessed else { return }
            let res:AppleAppInfo? = data.safeDecode().t
            guard let item = res?.results.first else { return }
            DispatchQueue.main.async {
                self?.appItemInfo = item
                self?.updateVersionTip()
            }
        }
        task.resume()
    }
    
    @IBAction func doEnterSecure(_ sender: Any) {
        let vc = OAAccountAndSafeViewCtr.oaDefaultVC()
        navigationController?.guideLoginThenPush(vc, animated: true)

//        let vc = AccountSecureViewController()
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    fileprivate func updateCacheLb() {
        guard let cache = YYWebImageManager.shared().cache else {
            cacheLb.text = "0B"
            return
        }
        let sz = cache.diskCache.totalCost()
        cacheLb.text = sz.appBytes
    }
    
    @IBOutlet weak var cacheLb: UILabel!
    @IBAction func doClearCache(_ sender: Any) {
        let vc = UIAlertController(title: nil, message: "已缓存的图片等信息将会被清除".localized, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "取消".localized, style: .cancel, handler:nil))
        vc.addAction(UIAlertAction(title: "确定".localized, style: .default, handler: {[weak self] (_) in
            YYWebImageManager.shared().cache?.diskCache.removeAllObjects()
            self?.cacheLb.text = "0B"
        }))
        present(vc, animated: true, completion: nil)
    }
    
    @IBOutlet weak var languageLb: UILabel!
    
    @IBAction func doChangeLanguage(_ sender: Any) {
        let vc = UIAlertController(title: "切换语言".localized, message: nil, preferredStyle: .actionSheet)
        let crtLan = "uilanguage".localized
        let allLans = [("English", "en"), ("Bahasa Indonesia", "id")] //, ("中文", "zh-Hans")]
        for (lan, code) in allLans {
            let act = UIAlertAction(title: lan, style: .default) { _ in
                UIApplication.shared.windows.first?.changeLanguageTo(code: code)
            }
            act.isEnabled = lan != crtLan
            vc.addAction(act)
        }
        
        vc.addAction(UIAlertAction(title: "取消".localized, style: .cancel, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var versionLb: UILabel!
    @IBAction func checkAppVersion(_ sender: Any) {
        navigationController?.pushWebVC(url: appWeb)
    }
    
    @IBAction func doClickFeedback(_ sender: Any) {
        let vc = FeedBackViewController()
        navigationController?.guideLoginThenPush(vc, animated: true)
    }
    
    @IBAction func doClickAbout(_ sender: Any) {
        let vc = AboutViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func doClickSwitchAccount(_ sender: Any) {
        let vc = AppAccountsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func doClickLogout(_ sender: Any) {
        let vc = UIAlertController(title: "", message: "确定退出该账号？".localized, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "取消".localized, style: .default, handler: nil))
        vc.addAction(UIAlertAction(title: "退出".localized, style: .destructive, handler: { (_) in
            AccountMng.shared.logout()
            UIApplication.shared.cxyResetUI()
        }))
        present(vc, animated: true, completion: nil)
    }
    
#if Intranet
    @IBAction func doClickChangeServerAddress(_ sender: Any) { }
#else
    @IBAction func doClickChangeServerAddress(_ sender: Any) {
        var acts: [FTAlertAction] = AppServerArea.all.map { nm in
            return .normal(tip: nm.rawValue) {
                UserDefaults.standard.cachedAppServer = nm
                self.toast("Take effect at next startup")
            }
        }
        acts.append(.cancel(tip: "Cancel", blk: nil))
        alert(type: .actionSheet, title: "Change Server Host", actions: acts)
    }
#endif
    
}

"""
    }
}

class TestExample {
    var value: Int = 0
    func increaseValueLater(_ v: Int = 0) -> Int {
        defer { value += 1 }
        return value + v
    }
    
    func reset() { value = 0 }
    func trySwitch(_ i: Int) -> Int {
        switch i {
        case 1:
            defer { reset() }
            value = i
            return value

        case 2:
            defer { reset() }
            value = i
            
        default:
            value = i
        }
        return value
    }
}
