import AppKit

/// 管理所有显示器上的全屏覆盖层窗口：创建、显隐、屏幕变化重建。
final class OverlayController {
    static let shared = OverlayController()

    private let settings = AppSettings.shared
    private var windows: [NSWindow] = []
    private var dismissTask: Task<Void, Never>?
    private var builtSignature = ""
    private var isShowing = false

    private init() {}

    var visible: Bool { isShowing }

    func show() {
        rebuildIfNeeded()
        for w in windows {
            w.orderFrontRegardless()
            (w.contentView as? BorderGlowView)?
                .fadeInThenBreathe(breathCycle: settings.breathCycleSeconds)
        }
        isShowing = true
        scheduleDismiss()
    }

    func hide() {
        dismissTask?.cancel()
        dismissTask = nil
        guard isShowing else { return }
        isShowing = false
        for w in windows {
            if let view = w.contentView as? BorderGlowView {
                view.fadeOut(duration: 0.8) { [weak w] in w?.orderOut(nil) }
            } else {
                w.orderOut(nil)
            }
        }
    }

    func screensDidChange() {
        guard isShowing else {
            builtSignature = ""
            return
        }
        let sig = signature()
        guard sig != builtSignature else { return }
        // 屏幕布局变化：立即重建并重新显示，旧窗口直接移除（不做淡出，避免与重新淡入的动画竞态），
        // 且不打断正在进行的 dismiss 计时。
        let old = windows
        windows = NSScreen.screens.map { makeWindow(for: $0) }
        builtSignature = sig
        for w in windows {
            w.orderFrontRegardless()
            (w.contentView as? BorderGlowView)?
                .fadeInThenBreathe(breathCycle: settings.breathCycleSeconds)
        }
        for w in old { w.orderOut(nil) }
    }

    // MARK: - 私有

    private func scheduleDismiss() {
        dismissTask?.cancel()
        let seconds = Double(settings.displaySeconds)
        dismissTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                // 任务被取消（新的 show 或 hide 到来）时，不再隐藏刚显示的覆盖层
                return
            }
            self?.hide()
        }
    }

    private func rebuildIfNeeded() {
        let sig = signature()
        guard sig != builtSignature || windows.isEmpty else { return }
        for w in windows {
            w.orderOut(nil)
            w.contentView = nil
        }
        windows = NSScreen.screens.map { makeWindow(for: $0) }
        builtSignature = sig
    }

    private func signature() -> String {
        let frames = NSScreen.screens.map { NSStringFromRect($0.frame) }.joined(separator: "|")
        return frames + "|" + settings.accentColorHex
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let frame = screen.frame
        let band = 0.10 * min(frame.width, frame.height)
        let window = NSWindow(contentRect: frame,
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.contentView = BorderGlowView(frame: NSRect(origin: .zero, size: frame.size),
                                            color: settings.accentColor,
                                            bandWidth: band)
        return window
    }
}
