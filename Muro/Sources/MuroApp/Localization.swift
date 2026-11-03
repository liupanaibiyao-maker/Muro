import SwiftUI

// MARK: - Language setting
//
// A light localization layer added on top of the app's otherwise English,
// hardcoded strings. The user picks a language in Settings (Interface
// language); the choice is remembered in UserDefaults and drives `tr()`, the
// single place every converted view resolves a string through.
//
// English is the source of truth: a translation key *is* its English wording,
// so any string that has no Chinese entry simply falls back to English and
// the UI never shows a blank. The default language is Chinese, so a fresh
// install opens already localized.

/// The languages Muro offers. The raw value is the code stored in
/// UserDefaults; `displayName` is how each shows in the picker, in its own
/// words, the way a language menu always reads.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

extension Notification.Name {
    /// Posted whenever the interface language changes, for anything that
    /// caches a string rather than re-reading `tr()` on the next render.
    static let muroLanguageDidChange = Notification.Name("muroLanguageDidChange")
}

/// The single source of truth for the current language, mirrored into
/// UserDefaults so it survives a restart. An `ObservableObject`, so the views
/// that observe it re-render the moment the language flips.
final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()

    private static let storageKey = "muroLanguage"

    /// Chinese is the default: a first launch (no saved value yet) is Chinese.
    @Published var language: AppLanguage {
        didSet {
            guard oldValue != language else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
            NotificationCenter.default.post(name: .muroLanguageDidChange, object: self)
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        language = AppLanguage(rawValue: saved ?? "") ?? .chinese
    }
}

// MARK: - String resolution

/// Translate `key` into the current language. The key is the English string,
/// so an unknown key returns itself: English, never a hole in the UI.
func tr(_ key: String) -> String {
    switch LanguageStore.shared.language {
    case .chinese:
        return Localization.chinese[key] ?? key
    case .english:
        return key
    }
}

/// Translate `key` and fill its `%1`, `%2`, … placeholders, left to right.
/// Same English-fallback rule as `tr`.
func trf(_ key: String, _ vars: String...) -> String {
    var text = tr(key)
    for (index, var_) in vars.enumerated() {
        text = text.replacingOccurrences(of: "%\(index + 1)", with: var_)
    }
    return text
}

// MARK: - Localized value helpers
//
// The dropdown and control values that MuroKit or the model layer produce as
// English strings. These wrappers translate the *unit words*, so any value —
// "10 s", "2 h 30 min", "Never" — comes out localized whatever the number.
// `locDuration` mirrors MuroKit's `durationLabel` format exactly, only with
// Chinese units when the language is Chinese.

/// "10 秒", "5 分钟", "2 小时", "1 小时 30 分钟" — same format as
/// `durationLabel`, localized.
func locDuration(_ seconds: Int) -> String {
    let isZh = LanguageStore.shared.language == .chinese
    let unitS = isZh ? "秒" : "s"
    let unitMin = isZh ? "分钟" : "min"
    let unitH = isZh ? "小时" : "h"
    if seconds < 60 { return "\(seconds) \(unitS)" }
    if seconds < 3600 {
        let minutes = seconds / 60
        let rest = seconds % 60
        return rest == 0 ? "\(minutes) \(unitMin)" : "\(minutes) \(unitMin) \(rest) \(unitS)"
    }
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return minutes == 0 ? "\(hours) \(unitH)" : "\(hours) \(unitH) \(minutes) \(unitMin)"
}

/// The screen-saver delay menu wording: "永不", "系统默认", or a localized
/// duration. Mirrors `ScreenSaverDelay.label`.
func locSaverLabel(_ seconds: Int?) -> String {
    guard let seconds else { return tr("System default") }
    return seconds <= 0 ? tr("Never") : locDuration(seconds)
}

/// The small grey words beside a playlist in the lists. Mirrors
/// `SchedulePlace.shortTitle`.
func locShortTitle(_ place: SchedulePlace) -> String {
    switch place {
    case .desktop: return tr("desktop")
    case .lockScreen: return tr("lock")
    case .screenSaver: return tr("saver")
    }
}

/// The full place name. Mirrors `SchedulePlace.title`.
func locPlaceTitle(_ place: SchedulePlace) -> String {
    switch place {
    case .desktop: return tr("Desktop")
    case .lockScreen: return tr("Lock screen")
    case .screenSaver: return tr("Screen saver")
    }
}

// MARK: - The Chinese table
//
// The key of each entry is the English wording it stands in for (see `tr`),
// the value is the Chinese. Grows as more of the app's strings are routed
// through `tr`.

enum Localization {
    static let chinese: [String: String] = [
        // Tabs and top bar
        "Home": "首页",
        "Explore": "探索",
        "Apple": "Apple",
        "Library": "资料库",
        "Search wallpapers": "搜索壁纸",
        "Settings": "设置",
        "made by %1": "由 %1 制作",

        // Settings · General
        "GENERAL": "通用",
        "Language": "语言",
        "Interface language": "界面语言",
        "Launch at Login": "开机时启动",
        "Starts quietly in the background": "在后台静默启动",
        "Show Menu Bar Icon": "显示菜单栏图标",
        "Quick controls from the menu bar": "从菜单栏快速控制",
        "Open Muro from Launchpad or Spotlight": "从启动台或 Spotlight 打开 Muro",
        "Show Dock Icon": "显示程序坞图标",
        "Off keeps Muro in the menu bar only": "关闭后 Muro 仅保留在菜单栏",
        "Appearance": "外观",
        "Default, Light or Dark": "默认、浅色或深色",
        "Default, Light and Dark": "默认、浅色和深色",
        "Menu Bar Icon": "菜单栏图标",
        "The icon Muro shows in the menu bar": "Muro 在菜单栏显示的图标",
        "Choose your menu bar icon": "选择你的菜单栏图标",
        "Six to pick from in Settings, from the classic moon to a ringed planet.":
            "在设置中有六种可选，从经典月亮到带环行星。",
        "The Glass Moon. In the Dock it follows your Mac's icon style, light or dark.":
            "玻璃月亮。在 Dock 中它会跟随 Mac 的图标样式（浅色或深色）。",

        // Settings · Playback
        "PLAYBACK": "播放",
        "Playback Speed": "播放速度",
        "How fast wallpapers play": "壁纸播放的快慢",
        "Default Quality": "默认画质",
        "Efficient caps at 30 fps for lower CPU": "高效模式最高 30 帧，降低 CPU 占用",
        "Pause After": "播放后暂停",
        "Wallpapers keep playing": "壁纸持续播放",
        "Plays for %1, then holds on a frame": "播放 %1 后停在某一帧",
        "Off": "关",
        "Custom": "自定义",
        "Replay on Clear Desktop": "桌面清空时重播",
        "Works with a Pause After time": "需配合「播放后暂停」的时间",
        "Plays %1 again each time the desktop clears": "每次桌面清空后 %1 播放一次",
        "Start Screen Saver": "启动屏保",
        "Never": "永不",
        "System default": "系统默认",
        "Smooth": "流畅",
        "Efficient": "高效",
        "Never pause": "永不暂停",
        "Never pause this one": "此壁纸永不暂停",

        // Settings · Energy
        "ENERGY": "能耗",
        "Auto-pause in Low Power Mode": "低电量模式时自动暂停",
        "Freeze while saving energy": "省电时冻结播放",
        "Auto-pause below 20% battery": "电量低于 20% 时自动暂停",
        "Resumes automatically on power": "接上电源后自动恢复",
        "Auto-pause when covered": "被遮挡时自动暂停",
        "Freeze when a window or full screen app covers it": "窗口或全屏应用遮挡时冻结",
        "Play only on desktop": "仅在桌面播放",
        "Freeze while a window is open on that screen": "该屏幕有窗口打开时冻结",

        // Settings · Displays / Storage
        "DISPLAYS": "显示器",
        "STORAGE": "存储",
        "Library & Cache": "资料库与缓存",
        "Keeps the wallpaper in use": "正在使用的壁纸会保留",
        "Clear": "清除",
        "Clear cache": "清除缓存",
        "Apple Downloads": "Apple 下载内容",
        "Aerials and pictures from the Apple section": "来自 Apple 分区的航拍与图片",
        "Download Folder": "下载文件夹",
        "Cancel": "取消",
        "Cancelling…": "正在取消…",
        "Default": "默认",
        "Change": "更改",

        // Settings · About
        "ABOUT": "关于",
        "Software Update": "软件更新",
        "Check Now": "立即检查",
        "Download ↗": "下载 ↗",
        "Support Muro": "支持 Muro",
        "Muro is free. Sponsoring keeps it that way.": "Muro 永久免费，赞助让它保持如此。",
        "GitHub ↗": "GitHub ↗",

        // Settings · header & alerts
        "Version %1": "版本 %1",
        "Muro %1 is available. See what's new.": "Muro %1 已可用，点击查看更新。",
        "Designed & developed by %1": "由 %1 设计与开发",
        "Clear the library?": "清除资料库？",
        "OK": "好",

        // Screen saver row wording
        "macOS is deciding. Pick a time to set it.": "macOS 正在决定，请选一个时间来设定。",
        "The screen saver never starts": "屏保永不启动",
        "Starts after %1 with no activity": "无操作 %1 后启动",
        "Saved. macOS uses it after the current wait ends, or now if you lock the screen.":
            "已保存。macOS 会在当前等待结束后生效，锁定屏幕则立即生效。",

        // Update row wording
        "Checking GitHub…": "正在检查 GitHub…",
        "Muro %1 is the latest version": "Muro %1 已是最新版本",
        "Version %1 is available on GitHub": "GitHub 上有 %1 版本",
        "Couldn't check. Check your connection.": "无法检查，请确认网络连接。",
        "You are running Muro %1": "你正在运行 Muro %1",
        "You are running Muro %1, the latest version": "你正在运行最新版本 Muro %1",
        "Muro %1": "Muro %1",
        "Download Muro %1": "下载 Muro %1",
        "UPDATE AVAILABLE": "有可用更新",
        "New Update Available": "有可用更新",
        "New update available": "有可用更新",
        "up to date": "已是最新",
        "Muro is up to date": "Muro 已是最新",
        "Could not check": "无法检查",
        "Check for Updates": "检查更新",
        "Try Again": "重试",
        "Look Again": "再次查看",
        "Earlier releases": "早期版本",
        "Release Notes": "发布说明",
        "The notes for this release are on the release page.": "此次发布的说明在发布页面上。",
        "The notes for this update are on the way": "此次更新的说明即将到来",

        // Menu bar panel
        "No wallpaper applied": "尚未设置壁纸",
        "Muro %1 available": "Muro %1 可更新",
        "RECENTS": "最近使用",
        "PLAYLISTS & AUTOMATIONS": "播放列表与自动化",
        "Open Muro": "打开 Muro",
        "Checking…": "正在检查…",
        "Muro %1 is available": "Muro %1 可用",
        "Download": "下载",
        "Quit Muro": "退出 Muro",

        // Home
        "FEATURED": "精选",
        "View Wallpaper": "查看壁纸",
        "Your library is empty": "你的资料库是空的",
        "Import your own videos with the + button, or browse Explore to download wallpapers.":
            "用 + 按钮导入你自己的视频，或到「探索」里浏览并下载壁纸。",

        // Places (SchedulePlace / AppliedPlace)
        "Desktop": "桌面",
        "Lock screen": "锁屏",
        "Screen saver": "屏保",
        "desktop": "桌面",
        "lock": "锁屏",
        "saver": "屏保",
        "ALL DISPLAYS": "所有显示器",
        "ALL LOCK SCREENS": "所有锁屏",
        "LOCK SCREEN": "锁屏",
        "SCREEN SAVER": "屏保",
        "all displays": "所有显示器",
        "All displays": "所有显示器",
        "Every display": "所有显示器",
        "All Screens": "所有屏幕",
        "the screen saver": "屏保",
        "The screen saver": "屏保",
        "Screensaver": "屏保",
        "Everywhere": "所有位置",
        "everywhere": "所有位置",
        "EVERYWHERE": "所有位置",
        "PLAYING EVERYWHERE": "所有位置播放中",
        "PLAYING ON %1": "在 %1 播放中",
        "PLAYING ON ": "正在播放于 ",
        "PLAYING": "播放中",
        "PLAYING NOW": "正在播放",
        "NOW PLAYING": "正在播放",
        "Now Playing": "正在播放",
        "SHOWING NOW": "正在显示",
        " + ": " + ",
        "On %1": "在 %1",

        // Display kinds
        "Main": "主显示器",
        "Built-in": "内置",
        "External": "外接",
        "Main display": "主显示器",
        "Built-in display": "内置显示器",
        "External display": "外接显示器",

        // Appearance modes
        "Dark": "深色",
        "Light": "浅色",

        // Menu bar icon styles
        "Outline": "轮廓",
        "Glass Moon": "玻璃月亮",
        "Planet": "行星",
        "Peaks": "山峰",
        "Display": "显示器",

        // Now Playing / place menu
        "PLAYLISTS": "播放列表",
        "AUTOMATIONS": "自动化",
        "No playlists or automations yet": "暂无播放列表或自动化",

        // Library · Playlists & Automations
        "Playlists": "播放列表",
        "Automations": "自动化",
        "Playlists & Automations": "播放列表与自动化",
        "Create Playlist": "新建播放列表",
        "New Playlist": "新建播放列表",
        "New Playlist %1": "新建播放列表 %1",
        "Edit Playlist": "编辑播放列表",
        "Delete Playlist": "删除播放列表",
        "Playlist name": "播放列表名称",
        "Create Automation": "新建自动化",
        "New Automation": "新建自动化",
        "Edit Automation": "编辑自动化",
        "Delete Automation": "删除自动化",
        "Automation name": "自动化名称",
        "The playlist": "该播放列表",
        "The automation": "该自动化",
        "Playlist stopped": "播放列表已停止",
        "Automation stopped": "自动化已停止",
        "Nothing scheduled yet": "尚未安排",
        "No wallpapers in this automation yet": "此自动化中还没有壁纸",
        "Pick wallpapers and cycle them on a schedule": "选择壁纸并按计划循环播放",
        "Pick the wallpapers this automation should use": "选择此自动化要使用的壁纸",
        "Pick at least one to get started.": "至少选择一张以开始。",
        "Nothing to play": "没有可播放的内容",
        "Remove from this automation": "从该自动化中移除",
        "Remove from all displays": "从所有显示器移除",
        "Every %1 min": "每 %1 分钟",
        "Every %1 hr": "每 %1 小时",
        "Every %1 hr %2 min": "每 %1 小时 %2 分钟",
        "Custom interval": "自定义间隔",
        "Custom duration": "自定义时长",
        "Not covered": "未覆盖",
        "Covers the whole day": "覆盖全天",
        "The same schedule repeats every day.": "相同的计划每天重复。",
        "A wallpaper you set by hand, or a pause, was undone at the next step.":
            "你手动设置的壁纸或暂停在下一步被撤销。",
        "Cycle: %1 across %2 wallpaper%3": "循环：%1，共 %2 张壁纸%3",
        "Covers the whole day across %1 wallpaper%2": "全天覆盖 %1 张壁纸%2",
        "Covers %1 of the day across %2 wallpaper%3": "覆盖全天的 %1，共 %2 张壁纸%3",
        "Drag an edge to change a time": "拖动边缘以更改时间",
        "Drag the handle to reorder": "拖动手柄以重新排序",
        "Set every step at once": "一次性设置所有步骤",

        // Apply / remove
        "Apply": "应用",
        "Apply to %1": "应用到 %1",
        "Apply to all displays": "应用到所有显示器",
        "Apply %1 to %2": "将 %1 应用到 %2",
        "Apply %1 to the screen saver": "将 %1 应用到屏保",
        "Applied": "已应用",
        "✓ Applied": "✓ 已应用",
        "Applied on %1": "已应用于 %1",
        "Applied on all displays": "已应用到所有显示器",
        "Applied on all lock screens": "已应用到所有锁屏",
        "Applied everywhere": "已应用到所有位置",
        "Applied in %1 places": "已应用到 %1 个位置",
        "Remove": "移除",
        "Remove all": "全部移除",
        "Remove %1 from %2": "从 %2 移除 %1",
        "Remove %1 from all displays": "从所有显示器移除 %1",
        "Remove %1 from the screen saver": "从屏保中移除 %1",
        "Remove this download?": "移除此下载？",
        "Remove Download": "移除下载",
        "Set Wallpaper": "设置壁纸",
        "Set %1": "设置 %1",
        "Set my desktop instead": "改为设置我的桌面",
        "Setting lock screen...": "正在设置锁屏...",
        "Setting…": "设置中…",
        "Choose display": "选择显示器",

        // Delete confirmations
        "Delete": "删除",
        "Delete %1 wallpapers?": "删除 %1 张壁纸？",
        "Delete %1 screen savers?": "删除 %1 个屏保？",
        "Delete this wallpaper?": "删除此壁纸？",
        "Delete this screen saver?": "删除此屏保？",
        "Delete “%1”?": "删除“%1”？",
        "Remove %1 downloads?": "移除 %1 项下载？",
        "Are you sure?": "确定吗？",
        "This is your own video. Deleting it is permanent.": "这是你自己的视频，删除后不可恢复。",
        "These are your own videos. Deleting them is permanent.": "这些是你自己的视频，删除后不可恢复。",
        "%1 are your own videos, and those are permanent.": "%1 个是你自己的视频，不可恢复。",
        "1 is your own video, and that one is permanent.": "1 个是你自己的视频，不可恢复。",
        "It goes to the Trash.": "它会被移到废纸篓。",
        "They go to the Trash.": "它们会被移到废纸篓。",
        "Screen savers go to the Trash. The others you can download again.":
            "屏保会被移到废纸篓，其他可以重新下载。",
        "You can download them again any time.": "随时可以重新下载。",
        "You can download it again any time.": "随时可以重新下载。",
        "This %1 is deleted for good. Its wallpapers stay in your Library.":
            "此 %1 已永久删除，其壁纸仍保留在资料库中。",
        "Delete it in the Library, then download or import it again.":
            "在资料库中删除，然后重新下载或导入。",
        "Clearing the library deleted wallpapers your playlists and automations use.":
            "清除资料库删除了播放列表和自动化使用的壁纸。",
        "Clear keeps playlist wallpapers": "清除会保留播放列表的壁纸",

        // Explore / download
        "Downloaded": "已下载",
        "Try another category.": "试试其他分类。",
        "Try another category, or widen the resolution and frame rate.":
            "试试其他分类，或放宽分辨率和帧率。",
        "Nothing matches that": "没有匹配结果",
        "No wallpaper called %1. Try another word.": "没有名为 %1 的壁纸，换个词试试。",
        "No %1 called %2. Try another word.": "没有名为 %2 的 %1，换个词试试。",
        "Only the wallpapers you have already downloaded are showing.": "仅显示已下载的壁纸。",
        "Clear filters": "清除筛选",
        "Importing": "导入中",
        "Importing %1 of %2": "正在导入 %1/%2",
        "Loading wallpapers…": "正在加载壁纸…",
        "Reading Apple's wallpapers…": "正在读取 Apple 壁纸…",
        "Drop videos or screen savers here, or click to import":
            "将视频或屏保拖到此处，或点击导入",
        "MP4, MOV and M4V videos, and .saver screen savers": "MP4、MOV、M4V 视频和 .saver 屏保",
        "Muro imports MP4, MOV and M4V videos.": "Muro 支持导入 MP4、MOV、M4V 视频。",
        "%1 could not be added. %2": "%1 无法添加。%2",
        "%1 could not be deleted. %2": "%1 无法删除。%2",
        "It could not be converted to HEVC.": "无法转换为 HEVC。",
        "It has no video track.": "没有视频轨道。",
        "A picture could not be taken from it.": "无法从中截图。",
        "This video could not be imported.": "此视频无法导入。",
        "The downloaded wallpaper files could not be found.": "找不到已下载的壁纸文件。",
        "%1 is already added.": "%1 已添加。",
        "%1 is already in your Library.": "%1 已在资料库中。",
        "%1 of those videos are already in your Library.": "其中 %1 个视频已在资料库中。",
        "%1 of %2 videos could not be imported.": "%2 个视频中有 %1 个无法导入。",
        "%1 file%2 skipped.": "%1 个文件%2 已跳过。",

        // Apple section
        "The Apple section": "Apple 专区",
        "Apple's aerials and Dynamic Wallpapers, in a tab of their own.":
            "Apple 的航拍和动态壁纸，专属标签页。",
        "Apple's videos of landscapes, cities, oceans and space":
            "Apple 的风景、城市、海洋和太空视频",
        "Apple's screen savers in 4K": "Apple 的 4K 屏保",
        "8 of Apple's own, like Hello and Flurry": "8 个 Apple 自己的，如 Hello 和 Flurry",
        "Apple's wallpapers are not on this Mac yet": "此 Mac 上还没有 Apple 壁纸",
        "It brings Apple's own live wallpapers and screen savers into Muro:":
            "将 Apple 自己的动态壁纸和屏保带入 Muro：",
        "These are Apple's, not made for Muro, so some of them can use more CPU, RAM and power than Muro's own live wallpapers.":
            "这些是 Apple 的，并非为 Muro 制作，因此某些会比 Muro 自己的动态壁纸占用更多 CPU、内存和电量。",
        "The lock screen and screen saver require macOS 26 or later":
            "锁屏和屏保需要 macOS 26 或更高版本",
        "Lock-screen live wallpapers require macOS 26 or later.":
            "锁屏动态壁纸需要 macOS 26 或更高版本。",
        "This needs macOS 26": "此功能需要 macOS 26",
        "The lock screen and the screen saver on new Macs": "新 Mac 上的锁屏和屏保",
        "The lock screen on some Macs": "部分 Mac 上的锁屏",
        "Aerials": "航拍",
        "Dynamic Wallpapers": "动态壁纸",
        "Screen Savers": "屏保",
        "Your own screen savers": "你自己添加的屏保",
        "My Videos": "我的视频",
        "Liked": "喜欢",
        "Recents": "最近",
        "recents": "最近",
        "Nature": "自然",
        "Provider": "来源",
        "Resolution": "分辨率",
        "Playlist": "播放列表",
        "wallpaper": "壁纸",
        "playlist": "播放列表",
        "automation": "自动化",

        // Preview / quality
        "Preview": "预览",
        "Pause after": "播放后暂停",
        "Higher CPU": "更高 CPU",
        "Lower CPU": "更低 CPU",
        "Lighter": "更轻量",
        "Fixed": "固定",
        "Vertical video · zoomed in to fill the screen": "竖屏视频 · 放大以填充屏幕",
        "Low resolution · may look soft on the screen": "低分辨率 · 在屏幕上可能偏软",
        "Still picture · %1×%2 · %3": "静态图片 · %1×%2 · %3",
        "Still picture · %1×%2": "静态图片 · %1×%2",
        "Screen saver · drawn live by macOS": "屏保 · 由 macOS 实时绘制",
        "Drawn by macOS · moves when you unlock": "由 macOS 绘制 · 解锁时会动",
        "Video file missing · ": "视频文件缺失 · ",
        "Missing wallpaper": "缺少壁纸",

        // Transport / shuffle
        "Shuffle": "随机",
        "Shuffle On": "随机播放：开",
        "Shuffle Off": "随机播放：关",
        "Shuffle on": "随机：开",
        "Shuffle off": "随机：关",
        "Play": "播放",
        "Pause": "暂停",
        "Not selected": "未选择",
        "Selected": "已选择",
        "%1 selected": "已选择 %1",
        "Select": "选择",
        "Select All": "全选",
        "Select None": "取消选择",

        // Generic actions
        "Import": "导入",
        "Add": "添加",
        "Edit": "编辑",
        "Save": "保存",
        "Close": "关闭",
        "Open": "打开",
        "Search": "搜索",
        "Filter": "筛选",
        "Sort": "排序",
        "All": "全部",
        "New": "新建",
        "Retry": "重试",
        "Done": "完成",
        "Got it": "知道了",
        "Share": "分享",
        "Confirm": "确认",
        "Create": "创建",
        "Loading": "加载",
        "Put something here": "在此处输入内容",
        "Enter a number": "输入数字",
        "Name already in use": "名称已存在",
        "Not connected": "未连接",

        // Clock / timer / what's new
        "Clock": "时钟",
        "CLOCK": "时钟",
        "Timer": "计时器",
        "TIMER": "计时器",
        "WHEN EACH ONE PLAYS": "各自的播放时间",
        "HOW LONG EACH ONE PLAYS": "各自的播放时长",
        "CHANGE WALLPAPER EVERY": "每隔多久更换壁纸",
        "IN THE VERSION YOU HAVE": "在你当前的版本中",
        "WHAT's NEW": "新功能",
        "Across the gallery, the Library, the menu bar and Settings.":
            "贯穿画廊、资料库、菜单栏和设置。",
        "Each setting has a glass icon of its own.": "每个设置都有自己独特的玻璃图标。",
        "Do not show this message again": "不再显示此消息",
        "About this section": "关于此部分",
        "worth knowing": "值得了解",
        "this arrived since you last looked": "自上次查看后有新内容",
        "A new look for Settings": "设置的新外观",
        "A new icon": "新图标",
        "This section was added by community request.": "此部分由社区请求添加。",
        "added by request": "应要求添加",
        "Show all the 35": "显示全部 35",
        "Show scroll bars: Always": "显示滚动条：始终",
        "not downloaded means new": "未下载表示新内容",
        "not used": "未使用",

        // What's New / release-note fragments
        "Muro 6.0 and 6.0.1 quit the moment they opened on macOS 14.":
            "Muro 6.0 和 6.0.1 在 macOS 14 上打开即退出。",
        "A crash on macOS 14": "macOS 14 上的崩溃",
        "A crash when Muro opened": "Muro 打开时的崩溃",
        "A very long number made Muro quit.": "一个很长的数字导致 Muro 退出。",
        "Muro's lock-screen extension is missing. Reinstall this build of Muro.":
            "Muro 的锁屏扩展缺失，请重新安装此版本。",
        "On some Macs, Apple's older aerial list made Muro 6.0 quit the moment it opened.":
            "在部分 Mac 上，Apple 的旧航拍列表导致 Muro 6.0 打开即退出。",
        "Some other major bug fixes and improvements": "其他一些主要错误修复和改进",
        "The gallery lets go of its pictures when it is closed, so Muro uses less memory.":
            "关闭时画廊会释放图片，因此 Muro 占用更少内存。",
        "Pick their folder in Settings. A move shows how far it is and can be cancelled.":
            "在设置中选择文件夹。移动时会显示进度且可取消。",

        // Misc / errors
        "Couldn't set wallpaper": "无法设置壁纸",
        "Couldn't import video": "无法导入视频",
        "Unknown error": "未知错误",
        "One more step": "还剩一步",
        "Open System Settings": "打开系统设置",
        "Later": "以后",
        "Muro cannot read your wallpaper list": "Muro 无法读取你的壁纸列表",
        "Show the File": "显示文件",
        "Your wallpapers are safe on disk, and Muro has stopped rather than overwrite the list with an empty one. Liking, importing and downloading will not work until library.json is repaired or moved out of Muro's folder.":
            "你的壁纸在磁盘上是安全的，Muro 已停止运行而不是用空列表覆盖。在 library.json 被修复或移出 Muro 文件夹之前，喜欢、导入和下载将无法工作。",
        "It could not be read. The file may be damaged, or in a format macOS cannot open.":
            "无法读取。文件可能已损坏，或 macOS 无法打开该格式。",
        "That aerial could not be downloaded from Apple. %1": "无法从 Apple 下载该航拍。%1",
        "Muro can't find the video for “%1”. ": "Muro 找不到“%1”的视频。 ",
        "It was moved or deleted outside Muro. ": "它在 Muro 之外被移动或删除了。 ",
        "%1 is not connected": "%1 未连接",
        "%1: %2": "%1：%2",
        "The flick at the loop": "循环处的闪烁",
        "Preparing 30 fps…": "正在准备 30 fps…",
        "Moving your wallpapers…%1": "正在移动你的壁纸…%1",
        "%1% of %2": "%1% 的 %2",
        "%1 fps · %2": "%1 fps · %2",
        "Now: %1 until %2": "现在：%1 直到 %2",
        "12:00 AM to 12:00 AM": "12:00 AM 至 12:00 AM",
        "00:00 – 24:00": "00:00 – 24:00",
        "Every %1": "每 %1",
        "%1 of them": "其中 %1 个",
        "1 of them": "其中 1 个",
        "The one that is playing stays.": "正在播放的那个会保留。",
        "The %1 in use stay.": "正在使用的 %1 个会保留。",
        "The one in your playlists and automations stays.": "播放列表和自动化中的那个会保留。",
        "The %1 in your playlists and automations stay.": "播放列表和自动化中的 %1 个会保留。",
        "%1 of them is from the Apple section and can be downloaded again.":
            "其中 %1 个来自 Apple 分区，可以重新下载。",
        "%1 of them are from the Apple section and can be downloaded again.":
            "其中 %1 个来自 Apple 分区，可以重新下载。",
        "1 of them is your own video and cannot be recovered.": "其中 1 个是你自己的视频，无法恢复。",
        "%1 of them are your own videos and cannot be recovered.": "其中 %1 个是你自己的视频，无法恢复。",
        "Nothing to clear. Every wallpaper here is playing, or in a playlist or an automation.":
            "没有可清除的内容。这里的所有壁纸都在播放，或在播放列表/自动化中。",
        "Nothing to clear. The only wallpapers here are the ones in use.":
            "没有可清除的内容。这里只有正在使用的壁纸。",
        "This removes %1 %2 and frees about %3.": "这将移除 %1 张%2，释放约 %3。",
        "about %1 freed": "约释放 %1",
        "%1 of leftovers swept": "已清理 %1 的残留",
        "%1 screen savers added.": "添加了 %1 个屏保。",
        "%1 playlists and automations": "%1 个播放列表和自动化",
        "%1 in this schedule": "此计划中有 %1",
        "%1 wallpaper%2": "%1 张壁纸%2",
        "%1 wallpapers": "%1 张壁纸",
        "%1 wallpaper": "%1 张壁纸",
        "%1 in %2": "%2 中的 %1",
        "%1 from Apple": "来自 Apple 的 %1",
        "%1 PLACES": "%1 个位置",
        "%1 places": "%1 个位置",
        " %1": " %1",
        "%1 · %2": "%1 · %2",
        "Both": "两者",

        // ---- added during full-localization pass ----
        "%1 added.": "已添加 %1。",
        "%1 cycle": "%1 循环",
        "%1 display": "%1 显示器",
        "%1 download": "下载 %1",
        "%1 gap%2": "%1 个空隙%2",
        "%1 on this Mac": "本 Mac 上有 %1 个",
        "%1 wallpaper from Apple": "来自 Apple 的 %1 张壁纸",
        "%1 wallpaper in %2": "%2 中的 %1 张壁纸",
        "%1 wallpapers from Apple": "来自 Apple 的 %1 张壁纸",
        "%1 wallpapers in %2": "%2 中的 %1 张壁纸",
        "%1, and %2. Whatever is playing stays.": "%1，另有 %2。正在播放的保持不变。",
        "%1. Whatever is playing stays.": "%1。正在播放的保持不变。",
        " and ": " 和 ",
        ", ": "、",
        " than Muro's own live wallpapers.": " 相比 Muro 自己的动态壁纸。",
        "%1 %2": "%1 %2",
        "A new version of Muro is available": "有新版本的 Muro 可用",
        "CHOOSE WALLPAPERS": "选择壁纸",
        "Could not check. Try again": "无法检查，请重试",
        "Couldn’t import video": "无法导入视频",
        "Couldn’t set wallpaper": "无法设置壁纸",
        "Covers %1 of the day across %2": "覆盖一天的 %1，共 %2",
        "Covers the whole day across %1": "覆盖全天，共 %1",
        "Cycle: %1 across %2": "循环：%1，共 %2",
        "Delete Wallpaper (%1)": "删除壁纸（%1）",
        "Delete wallpaper": "删除壁纸",
        "Each wallpaper owns a slot on the clock, and the same schedule repeats every day.": "每张壁纸在时钟上拥有自己的时段，相同的计划每天重复。",
        "Each wallpaper plays for its own length of time, then the next one takes over and it loops.": "每张壁纸播放自己的时长，然后由下一张接管并循环。",
        "Every hour": "每小时",
        "Everything that changed will be listed right here: what is new, what got better, and what was fixed.": "所有变化都会列在这里：新功能、改进和修复。",
        "FPS": "帧率",
        "FROM APPLE": "来自 Apple",
        "Give each wallpaper its own time of day, or its own length": "让每张壁纸拥有自己的时间段或时长",
        "Import your own video": "导入你自己的视频",
        "It also comes out of ": "它也会脱离 ",
        "It loops back to the first wallpaper and starts again.": "循环回第一张壁纸并重新开始。",
        "Muro set your lock screen wallpaper but macOS has not picked it up yet. Open System Settings, go to Wallpaper, and choose Muro to finish it.": "Muro 已设置你的锁屏壁纸，但 macOS 尚未生效。请打开系统设置，进入壁纸，选择 Muro 以完成设置。",
        "NAME": "名称",
        "NEW": "新",
        "No wallpapers downloaded yet. Download some from Explore, or import your own with the + button in the Library.": "还没有下载壁纸。到「探索」里下载一些，或用资料库中的 + 按钮导入你自己的。",
        "Pause after: how long this wallpaper moves before holding on a frame": "播放后暂停：此壁纸移动多久后停在某一帧",
        "Pick a wallpaper above and it plays for ten minutes. Every one you add gets its own length.": "在上方选一张壁纸即可播放十分钟。每添加一张都有各自的时长。",
        "Pick a wallpaper above and it takes the whole day. Add another and the day splits between them.": "在上方选一张壁纸即可覆盖全天。再加一张，白天就在它们之间分配。",
        "Remove Download (%1)": "移除下载（%1）",
        "Search wallpapers…": "搜索壁纸…",
        "Settings…": "设置…",
        "The lock screen and the screen saver use a part of macOS that arrived in macOS 26. This Mac runs %1, so Muro can set your desktop but not those.": "锁屏和屏保使用的 macOS 组件在 macOS 26 中才提供。这台 Mac 运行的是 %1，因此 Muro 只能设置你的桌面，无法设置锁屏和屏保。",
        "These are Apple's, not made for Muro, so some of them can use ": "这些是 Apple 的，并非为 Muro 制作，其中部分可能占用",
        "They also come out of ": "它们也会脱离 ",
        "Those screen savers are already added.": "这些屏保已经添加过了。",
        "Use setting (%1)": "使用设置（%1）",
        "Videos, still pictures, and a few drawn live by macOS": "视频、静态图片，以及少量由 macOS 实时绘制的画面",
        "What's New": "新功能",
        "What's New in Muro": "Muro 的新功能",
        "YOUR SCREEN SAVERS": "你的屏保",
        "aerial": "航拍",
        "hr": "小时",
        "lock screen": "锁屏",
        "macOS can't use a still picture as the screen saver.": "macOS 无法将静态图片用作屏保。",
        "min": "分钟",
        "more CPU, RAM and power": "更多 CPU、内存和电量",
        "off": "关",
        "on": "开",
        "other gap": "其他空隙",
        "other gaps": "其他空隙",
        "s": "张",
        "screen saver": "屏保",
        "sec": "秒",
        "to": "至",
        "wallpapers": "壁纸",
    ]
}
