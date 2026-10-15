import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var activity: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 开发期 swift run 裸跑也不显示 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        // 防 App Nap 节流定时器
        activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated,
                                                         reason: "Reminder scheduling")

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        let settings = AppSettings.shared

        settings.$isPaused
            .dropFirst()
            .sink { paused in
                paused ? ReminderScheduler.shared.stop() : ReminderScheduler.shared.start()
            }
            .store(in: &cancellables)

        settings.$intervalMinutes
            .dropFirst()
            .sink { _ in
                if !settings.isPaused { ReminderScheduler.shared.start() }
            }
            .store(in: &cancellables)

        if !settings.isPaused {
            ReminderScheduler.shared.start()
        }
    }

    @objc private func screensChanged(_ note: Notification) {
        OverlayController.shared.screensDidChange()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
    }
}
