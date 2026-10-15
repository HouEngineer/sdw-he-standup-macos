import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var scheduler = ReminderScheduler.shared
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    var body: some View {
        Form {
            if settings.isPaused {
                Text("提醒已暂停")
                    .foregroundStyle(.secondary)
            } else if let next = scheduler.nextFireDate {
                HStack {
                    Text("下次提醒")
                    Spacer()
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(CountdownFormatter.text(to: next))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            HStack {
                Text("提醒间隔")
                Spacer()
                TextField("", value: $settings.intervalMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                Text("分钟")
                Stepper("", value: $settings.intervalMinutes, in: 1...480)
                    .labelsHidden()
            }
            .onChange(of: settings.intervalMinutes) { v in
                let clamped = min(max(v, 1), 480)
                if clamped != v { settings.intervalMinutes = clamped }
            }

            HStack {
                Text("展示时长")
                Spacer()
                TextField("", value: $settings.displaySeconds, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                Text("秒")
                Stepper("", value: $settings.displaySeconds, in: 1...120)
                    .labelsHidden()
            }
            .onChange(of: settings.displaySeconds) { v in
                let clamped = min(max(v, 1), 120)
                if clamped != v { settings.displaySeconds = clamped }
            }

            HStack {
                Text("渐变颜色")
                Spacer()
                NSColorWellRepresentable(color: accentBinding)
            }

            Toggle("开机自动启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        try LaunchAtLogin.setEnabled(newValue)
                        launchError = nil
                    } catch {
                        launchError = error.localizedDescription
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
                }

            if let launchError {
                Text(launchError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private var accentBinding: Binding<NSColor> {
        Binding(
            get: { settings.accentColor },
            set: { settings.accentColorHex = ColorHex.string(from: $0) }
        )
    }
}

/// 用原生 NSColorWell 取色，直接得到 NSColor（避开 Color→NSColor 转换的坑）。
private struct NSColorWellRepresentable: NSViewRepresentable {
    @Binding var color: NSColor

    func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell()
        well.color = color
        well.target = context.coordinator
        well.action = #selector(Coordinator.changed(_:))
        return well
    }

    func updateNSView(_ well: NSColorWell, context: Context) {
        well.color = color
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject {
        var parent: NSColorWellRepresentable
        init(_ parent: NSColorWellRepresentable) { self.parent = parent }
        @objc func changed(_ well: NSColorWell) {
            parent.color = well.color
        }
    }
}
