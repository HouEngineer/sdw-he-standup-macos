import SwiftUI

@main
struct SDWStandupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView().environmentObject(settings)
        } label: {
            Image(systemName: settings.isPaused ? "pause.circle" : "figure.stand")
        }
        .menuBarExtraStyle(.menu)
    }
}
