import AppKit
import SwiftUI

@MainActor
final class DesktopWindowController {
    private var window: NSWindow?
    private var frameObserver: NSKeyValueObservation?

    func show(viewModel: CalendarViewModel, settings: AppSettings) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let frame = calculateFrame(settings: settings)

        let contentView = ContentView(viewModel: viewModel, settings: settings)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 16
        hostingView.layer?.masksToBounds = true

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 窗口层级配置
        let desktopIconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        window.level = NSWindow.Level(rawValue: desktopIconLevel + 1)

        // 窗口外观
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovable = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.canHide = false
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false

        applyMovability(window: window, settings: settings)

        window.contentView = hostingView

        // 自由模式：监听窗口移动以保存位置
        if settings.calendarPosition == .free {
            setupFrameObserver(window: window, settings: settings)
        }

        self.window = window
        window.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    func toggle(viewModel: CalendarViewModel, settings: AppSettings) {
        if window?.isVisible == true {
            hide()
        } else {
            show(viewModel: viewModel, settings: settings)
        }
    }

    /// 设置变更后刷新窗口
    func refresh(settings: AppSettings) {
        guard let window = window else { return }
        let newFrame = calculateFrame(settings: settings)
        window.setFrame(newFrame, display: true, animate: true)
        applyMovability(window: window, settings: settings)

        if settings.calendarPosition == .free {
            if frameObserver == nil {
                setupFrameObserver(window: window, settings: settings)
            }
        } else {
            frameObserver = nil
        }
    }

    // MARK: - Private

    private func setupFrameObserver(window: NSWindow, settings: AppSettings) {
        frameObserver = window.observe(\.frame, options: [.new]) { [weak self] win, _ in
            MainActor.assumeIsolated {
                guard self != nil else { return }
                settings.customOrigin = win.frame.origin
            }
        }
    }

    private func calculateFrame(settings: AppSettings) -> NSRect {
        let (width, height) = settings.calendarSize.windowSize

        // 自由模式：使用保存的位置或默认右下
        if settings.calendarPosition == .free,
           let origin = settings.customOrigin {
            return NSRect(x: origin.x, y: origin.y, width: width, height: height)
        }

        guard let screen = NSScreen.main else {
            return NSRect(x: 100, y: 100, width: width, height: height)
        }

        let screenFrame = screen.visibleFrame
        let margin: CGFloat = 40

        switch settings.calendarPosition {
        case .topLeft:
            return NSRect(x: screenFrame.minX + margin,
                          y: screenFrame.maxY - height - margin,
                          width: width, height: height)
        case .topRight:
            return NSRect(x: screenFrame.maxX - width - margin,
                          y: screenFrame.maxY - height - margin,
                          width: width, height: height)
        case .bottomLeft:
            return NSRect(x: screenFrame.minX + margin,
                          y: screenFrame.minY + margin,
                          width: width, height: height)
        case .bottomRight, .free:
            // 自由模式未保存位置时默认右下角
            return NSRect(x: screenFrame.maxX - width - margin,
                          y: screenFrame.minY + margin,
                          width: width, height: height)
        }
    }

    private func applyMovability(window: NSWindow, settings: AppSettings) {
        window.isMovableByWindowBackground = settings.calendarPosition == .free
    }
}
