import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show(settings: AppSettings, onDismiss: @escaping () -> Void) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = SettingsView(settings: settings) { [weak self] in
            self?.hide()
            onDismiss()
        }
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 14
        hostingView.layer?.masksToBounds = true

        // 按内容自适应尺寸
        let fittingSize = hostingView.fittingSize
        let width: CGFloat = fittingSize.width
        let height: CGFloat = fittingSize.height

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2

        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.isReleasedWhenClosed = false

        // 隐藏标准关闭按钮的视觉但保留功能（或直接隐藏 titlebar）
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.contentView = hostingView

        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }
}
