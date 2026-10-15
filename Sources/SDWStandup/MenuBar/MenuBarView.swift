import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        statusSection
        Divider()
        Toggle("暂停提醒", isOn: $settings.isPaused)
        Divider()
        Button("立即提醒（预览）") {
            OverlayController.shared.show()
        }
        Divider()
        Button("设置…") {
            SettingsWindowController.shared.show()
        }
        Divider()
        Button("退出") {
            NSApp.terminate(nil)
        }
    }

    @ViewBuilder private var statusSection: some View {
        if settings.isPaused {
            Text("提醒已暂停")
        } else if let next = ReminderScheduler.shared.nextFireDate {
            Text("下次提醒：" + CountdownFormatter.text(to: next))
        }
    }
}
