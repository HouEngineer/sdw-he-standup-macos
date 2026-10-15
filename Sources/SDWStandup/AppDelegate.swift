import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var activity: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    private var statusItem: NSStatusItem?
    private var countdownItem: NSMenuItem?
    private var pauseItem: NSMenuItem?
    private var menuTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 开发期 swift run 裸跑也不显示 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        // 防 App Nap 节流定时器
        activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated,
                                                         reason: "Reminder scheduling")

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        setupMenuBar()

        let settings = AppSettings.shared

        settings.$isPaused
            .dropFirst()
            .sink { [weak self] paused in
                self?.refreshPauseUI()
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

    func applicationWillTerminate(_ notification: Notification) {
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
    }

    @objc private func screensChanged(_ note: Notification) {
        OverlayController.shared.screensDidChange()
    }

    // MARK: - 菜单栏（NSStatusItem）

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = statusIcon(paused: AppSettings.shared.isPaused)

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        let countdown = NSMenuItem(title: " ", action: nil, keyEquivalent: "")
        countdown.isEnabled = false
        menu.addItem(countdown)
        menu.addItem(.separator())

        let pause = NSMenuItem(title: "暂停提醒", action: #selector(togglePause(_:)), keyEquivalent: "")
        pause.target = self
        menu.addItem(pause)

        let preview = NSMenuItem(title: "立即提醒（预览）", action: #selector(previewReminder(_:)), keyEquivalent: "")
        preview.target = self
        menu.addItem(preview)

        let settings = NSMenuItem(title: "设置…", action: #selector(openSettings(_:)), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "退出", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
        countdownItem = countdown
        pauseItem = pause
        updateCountdown()
    }

    // MARK: - NSMenuDelegate：菜单打开期间逐秒刷新倒计时

    func menuWillOpen(_ menu: NSMenu) {
        refreshPauseUI()
        updateCountdown()
        // 菜单跟踪运行在 event tracking mode，需注册 .common 才能在打开期间触发
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
        RunLoop.main.add(timer, forMode: .common)
        menuTimer = timer
    }

    func menuDidClose(_ menu: NSMenu) {
        menuTimer?.invalidate()
        menuTimer = nil
    }

    // MARK: - 私有

    private func updateCountdown() {
        guard let countdownItem else { return }
        if AppSettings.shared.isPaused {
            countdownItem.title = "提醒已暂停"
        } else if let next = ReminderScheduler.shared.nextFireDate {
            countdownItem.title = "下次提醒：" + CountdownFormatter.text(to: next)
        } else {
            countdownItem.title = " "
        }
    }

    private func refreshPauseUI() {
        let paused = AppSettings.shared.isPaused
        statusItem?.button?.image = statusIcon(paused: paused)
        pauseItem?.title = paused ? "恢复提醒" : "暂停提醒"
    }

    private func statusIcon(paused: Bool) -> NSImage? {
        let image = NSImage(systemSymbolName: paused ? "pause.circle" : "figure.stand",
                            accessibilityDescription: "久坐提醒")
        image?.isTemplate = true
        return image
    }

    // MARK: - 菜单动作

    @objc private func togglePause(_ sender: Any?) {
        AppSettings.shared.isPaused.toggle()
    }

    @objc private func previewReminder(_ sender: Any?) {
        OverlayController.shared.show()
    }

    @objc private func openSettings(_ sender: Any?) {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
