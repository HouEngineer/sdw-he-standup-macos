import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    var body: some View {
        Form {
            Picker("提醒间隔", selection: $settings.intervalMinutes) {
                Text("30 分钟").tag(30)
                Text("45 分钟").tag(45)
                Text("60 分钟").tag(60)
            }

            Picker("展示时长", selection: $settings.displaySeconds) {
                Text("8 秒").tag(8)
                Text("12 秒").tag(12)
                Text("20 秒").tag(20)
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
