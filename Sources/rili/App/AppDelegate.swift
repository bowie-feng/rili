import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var windowController: DesktopWindowController!
    private var settingsWindowController: SettingsWindowController!
    private var viewModel: CalendarViewModel!
    private var settings: AppSettings!

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings = AppSettings()
        viewModel = CalendarViewModel()
        windowController = DesktopWindowController()
        settingsWindowController = SettingsWindowController()
        setupStatusBar()

        // 启动时显示窗口
        windowController.show(viewModel: viewModel, settings: settings)
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(
                systemSymbolName: "calendar",
                accessibilityDescription: "桌面日历"
            ) {
                image.isTemplate = true
                button.image = image
                button.image?.size = NSSize(width: 18, height: 18)
            } else {
                button.title = "📅"
            }
        }

        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "显示/隐藏日历",
            action: #selector(toggleWindow),
            keyEquivalent: "t"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "设置…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(
            title: "关于桌面日历",
            action: nil,
            keyEquivalent: ""
        )
        let versionItem = NSMenuItem(
            title: "版本 \(AppSettings.version)",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        menu.addItem(aboutItem)
        menu.addItem(versionItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleWindow() {
        windowController.toggle(viewModel: viewModel, settings: settings)
    }

    @objc private func openSettings() {
        settingsWindowController.show(settings: settings) { [weak self] in
            // 设置关闭后刷新主窗口
            Task { @MainActor in
                self?.windowController.refresh(settings: self?.settings ?? AppSettings())
            }
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
