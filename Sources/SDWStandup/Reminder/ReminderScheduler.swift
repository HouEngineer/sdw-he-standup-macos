import AppKit

/// 提醒调度循环：按绝对时间锚定下一次触发，休眠唤醒后不漂移。
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    private let settings = AppSettings.shared
    private var task: Task<Void, Never>?

    private init() {}

    func start() {
        task?.cancel()
        task = Task { @MainActor [weak self] in
            await self?.runLoop()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func runLoop() async {
        let interval = Double(settings.intervalMinutes) * 60
        var next = Date().addingTimeInterval(interval)
        while !Task.isCancelled {
            let delay = next.timeIntervalSinceNow
            if delay <= 0 {
                OverlayController.shared.show()
                next = Date().addingTimeInterval(interval)
            } else {
                // ContinuousClock：睡眠时间照算，唤醒后立即补触发
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }
}
