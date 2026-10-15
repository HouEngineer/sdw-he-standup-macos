import AppKit
import SwiftUI

/// 用 NSWindow + NSHostingController 弹设置窗口（LSUIElement 应用没有 Settings scene）。
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView().environmentObject(AppSettings.shared))
            let win = NSWindow(contentViewController: hosting)
            win.title = "久坐提醒设置"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.center()
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
