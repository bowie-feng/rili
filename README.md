# 桌面日历 (Desktop Calendar)

> macOS 桌面悬浮日历 — 农历、事项管理、透明无边框面板

一个运行在 macOS 桌面上的轻量级日历应用。以半透明悬浮面板的形式常驻桌面，支持农历显示、待办事项管理，多种尺寸和屏幕位置可选。

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/version-1.2.0-green" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="License">
</p>

---

## ✨ 功能

- 📅 **月历网格** — 完整月历展示，支持前后翻月和快速回到今天
- 🌙 **农历** — 每个日期显示农历信息，自动标记春节、中秋等传统节日
- 📝 **事项管理** — 创建、编辑、删除待办事项，支持标题、日期、时间、备注
- 🏷️ **彩色标签** — 事项以彩色圆角标签显示在日期格子中，超出 2 条自动折叠
- 🔢 **日期角标** — 每个日期右上角显示当日待办总数
- 🪟 **桌面悬浮** — 无边框半透明面板，始终停留在桌面层级，不抢焦点
- 📏 **三种尺寸** — 标准 (430×660) / 较大 (510×770) / 最大 (590×880)
- 📍 **五种位置** — 左上 / 右上 / 左下 / 右下 / 自由拖动
- 🚀 **开机自启** — 通过 SMAppService 注册，系统原生支持
- 🎛️ **菜单栏控制** — 状态栏图标，`⌘T` 显示/隐藏，`⌘,` 打开设置

---

## 📋 系统要求

| 项目 | 要求 |
|------|------|
| macOS | 14.0 (Sonoma) 或更高 |
| Swift | 6.0 |

---

## 📦 安装

### 下载 Release（推荐）

从 [Releases](https://github.com/bowie-feng/rili/releases) 页面下载最新的 `.app.zip`，解压后拖入 `/Applications` 即可。

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/bowie-feng/rili.git
cd rili

# 快速运行
make run

# 构建 .app 包
make app

# 安装到 /Applications
make install
```

#### 可用命令

| 命令 | 说明 |
|------|------|
| `make build` | 构建 Debug 版本 |
| `make run` | 构建并运行 |
| `make release` | 构建 Release 版本 |
| `make app` | 构建 .app 包（含 Release 二进制和图标） |
| `make install` | 构建 .app 并复制到 /Applications |
| `make clean` | 清理构建产物 |

---

## 🏗️ 架构

```
Sources/rili/
├── main.swift                     # 入口：创建 NSApp，设置 accessory 策略
├── App/
│   └── AppDelegate.swift          # 状态栏、菜单、窗口生命周期
├── Models/
│   ├── AppSettings.swift          # 尺寸/位置枚举、设置持久化
│   └── CalendarEvent.swift        # 事项数据模型
├── Services/
│   └── EventStore.swift           # JSON 文件持久化、CRUD 操作
├── Utils/
│   └── LunarCalendar.swift        # 农历转换、传统节日
├── ViewModels/
│   └── CalendarViewModel.swift    # 核心逻辑：月份状态、网格计算、事项聚合
├── Views/
│   ├── ContentView.swift          # 根视图：导航栏 + 日历网格 + 选中日期栏
│   ├── CalendarGridView.swift     # 7 列日历网格、日期格、事项标签、颜色
│   ├── MonthNavigationView.swift  # 月份导航头
│   ├── EventEditView.swift        # 添加/编辑/删除事项表单
│   └── SettingsView.swift         # 设置面板
└── Window/
    ├── DesktopWindowController.swift  # 悬浮面板：层级、定位、拖动
    └── SettingsWindowController.swift # 设置弹窗
```

**数据流**: `AppDelegate` → `AppSettings` + `EventStore` → `CalendarViewModel` → `ContentView`

**零外部依赖** — 仅使用 Apple 原生框架（SwiftUI、AppKit、Observation）。

---

## 📝 数据存储

- **事项数据**: `~/Library/Application Support/rili/events.json`
- **设置**: `UserDefaults.standard`（key: `rili_appSettings`）

---

## 📖 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| [v1.2.0](https://github.com/bowie-feng/rili/releases/tag/v1.2.0) | 2026-06-08 | UI 重构：加宽格子、去毛玻璃、高对比度、优化上下间距 |
| [v1.1.1](https://github.com/bowie-feng/rili/releases/tag/v1.1.1) | 2026-06-08 | 代码签名修复、EventStore 性能优化、旧 plist 清理、代码重构 |
| [v1.1.0](https://github.com/bowie-feng/rili/releases/tag/v1.1.0) | 2026-06-08 | 事项标签点击跳转、SMAppService 迁移、设置 UI 重构、窗口尺寸微调 |
| [v1.0.0](https://github.com/bowie-feng/rili/releases/tag/v1.0.0) | 2026-06-07 | 初始发布：月历网格、农历、事项管理、桌面悬浮面板 |

---

## 📄 许可证

MIT License
