import SwiftUI

@main
struct SDWStandupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 菜单栏由 AppDelegate 用 NSStatusItem 实现（菜单内倒计时需逐秒刷新）。
        // LSUIElement 应用没有主窗口，这里放一个空的 Settings scene 占位。
        Settings { EmptyView() }
    }
}
