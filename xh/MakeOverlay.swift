//
//  MakeOverlay.swift
//  xHistory
//
//  Created by apple on 2024/11/8.
//

import AppKit
import CoreGraphics

func getActiveWindowGeometry() -> (x: Int, y: Int, width: Int, height: Int)? {
    guard let appName = NSWorkspace.shared.frontmostApplication?.localizedName else { return nil }
    let windowListInfo = CGWindowListCopyWindowInfo([.excludeDesktopElements,.optionOnScreenOnly], kCGNullWindowID) as NSArray? as? [[String: Any]]
    if let firstWindow = windowListInfo?.first(where: { $0["kCGWindowOwnerName"] as? String == appName && $0["kCGWindowAlpha"] as? NSNumber != 0 }) {
        if let boundsDict = firstWindow["kCGWindowBounds"] as? [String: CGFloat],
           let x = boundsDict["X"], let y = boundsDict["Y"],
           let width = boundsDict["Width"], let height = boundsDict["Height"] {
            return (Int(x), Int(y), Int(width), Int(height))
        }
    }
    return nil
}

func openCustomURLWithActiveWindowGeometry(prompt: String = "") {
    if let geometry = getActiveWindowGeometry() {
        if let url = URL(string: "xhistory://show?x=\(geometry.x)&y=\(geometry.y)&w=\(geometry.width)&h=\(geometry.height)\(prompt)") {
            _ = try? NSWorkspace.shared.open(url, options: [.withoutActivation],  configuration: [:] )
        }
    }
}

func readPlistValue(filePath: String, key: String) -> Any? {
    guard let plist = NSDictionary(contentsOfFile: filePath) else { return nil }
    return plist[key]
}
