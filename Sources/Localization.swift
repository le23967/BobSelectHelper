import Foundation

struct Localization {
    enum Language: String {
        case english = "en"
        case chinese = "zh"
    }

    static var current: Language { Settings.shared.language }

    struct Menu {
        static var enableHelper: String {
            current == .english ? "Enable Helper" : "启用划词助手"
        }

        static var triggerMethod: String {
            current == .english ? "Trigger Method" : "触发方式"
        }

        static var translateOnHover: String {
            current == .english ? "Translate on Hover" : "悬停后翻译"
        }

        static var translateOnClick: String {
            current == .english ? "Translate on Click" : "点击后翻译"
        }

        static var bobInputBox: String {
            current == .english ? "Bob Input Box" : "Bob 输入框"
        }

        static var alwaysExpandInputBox: String {
            current == .english ? "Always Expand Input Box" : "总是展开输入框"
        }

        static var followBobState: String {
            current == .english ? "Follow Bob's State" : "跟随 Bob 当前状态"
        }

        static var alwaysCollapseInputBox: String {
            current == .english ? "Always Collapse Input Box" : "总是折叠输入框"
        }

        static var hoverDelay: String {
            current == .english ? "Hover Delay" : "悬停延迟"
        }

        static var immediate: String {
            current == .english ? "Immediate" : "立即"
        }

        static var fast: String {
            current == .english ? "Fast (0.12s)" : "快速（0.12 秒）"
        }

        static var balanced: String {
            current == .english ? "Balanced (0.22s)" : "平衡（0.22 秒）"
        }

        static var slow: String {
            current == .english ? "Slow (0.40s)" : "较慢（0.40 秒）"
        }

        static var verySlow: String {
            current == .english ? "Very Slow (0.70s)" : "防误触（0.70 秒）"
        }

        static var iconSize: String {
            current == .english ? "Icon Size" : "悬浮图标大小"
        }

        static var small: String {
            current == .english ? "Small (26px)" : "小（26 px）"
        }

        static var smaller: String {
            current == .english ? "Smaller (30px)" : "较小（30 px）"
        }

        static var `default`: String {
            current == .english ? "Default (34px)" : "默认（34 px）"
        }

        static var larger: String {
            current == .english ? "Larger (40px)" : "较大（40 px）"
        }

        static var large: String {
            current == .english ? "Large (48px)" : "大（48 px）"
        }

        static var extraLarge: String {
            current == .english ? "Extra Large (56px)" : "特大（56 px）"
        }

        static var iconPosition: String {
            current == .english ? "Icon Position" : "图标出现位置"
        }

        static var bottomRight: String {
            current == .english ? "Bottom Right" : "右下方"
        }

        static var topRight: String {
            current == .english ? "Top Right" : "右上方"
        }

        static var bottomLeft: String {
            current == .english ? "Bottom Left" : "左下方"
        }

        static var topLeft: String {
            current == .english ? "Top Left" : "左上方"
        }

        static var autoHideDuration: String {
            current == .english ? "Auto-hide Duration" : "自动隐藏"
        }

        static var twoSeconds: String {
            current == .english ? "2 seconds" : "2 秒"
        }

        static var fiveSeconds: String {
            current == .english ? "5 seconds" : "5 秒"
        }

        static var tenSeconds: String {
            current == .english ? "10 seconds" : "10 秒"
        }

        static var neverAutoHide: String {
            current == .english ? "Never Auto-hide" : "不自动隐藏"
        }

        static var autoLaunchWithBob: String {
            current == .english ? "Auto-launch with Bob" : "打开 Bob 时自动启动"
        }

        static var autoLaunchPendingApproval: String {
            current == .english ? "Auto-launch with Bob (Pending Approval)" : "打开 Bob 时自动启动（待系统允许）"
        }

        static var openLoginItems: String {
            current == .english ? "Open Login Items and Allow" : "打开登录项设置并允许"
        }

        static var useCopyFallback: String {
            current == .english ? "Use Command-C Fallback" : "不兼容软件使用 Command-C 取词"
        }

        static var applicationFilterSettings: String {
            current == .english ? "Application Filter Settings" : "应用过滤设置"
        }

        static var openAccessibilityPermissions: String {
            current == .english ? "Open Accessibility Permissions" : "打开辅助功能权限"
        }

        static var testBobConnection: String {
            current == .english ? "Test Bob Connection" : "测试 Bob 连接"
        }

        static var instructions: String {
            current == .english ? "Instructions" : "使用说明"
        }

        static var quitHelper: String {
            current == .english ? "Quit Bob Select Helper" : "退出 Bob Select Helper"
        }

        static var language: String {
            current == .english ? "Language" : "语言"
        }

        static var settings: String {
            current == .english ? "Settings…" : "设置…"
        }

        static var languageEnglish: String { "English" }

        static var languageChinese: String { "简体中文" }
    }

    struct Panel {
        static var translateWithBob: String {
            current == .english ? "Translate with Bob" : "使用 Bob 翻译"
        }
    }

    struct Window {
        static var title: String {
            current == .english ? "Bob Select Helper" : "Bob Select Helper"
        }

        static var headline: String {
            current == .english ?
                "Select text anywhere, then click the Bob icon that appears." :
                "在任意应用中选中文字，然后点击出现的 Bob 图标。"
        }

        static var tabGeneral: String {
            current == .english ? "General" : "通用"
        }

        static var tabAppearance: String {
            current == .english ? "Appearance" : "外观"
        }

        static var tabBob: String {
            current == .english ? "Bob" : "Bob"
        }

        static var tabApplications: String {
            current == .english ? "Applications" : "应用"
        }

        static var statusReady: String {
            current == .english ? "Ready" : "已就绪"
        }

        static var statusNeedsAccessibility: String {
            current == .english ?
                "Accessibility permission is required" :
                "需要辅助功能权限"
        }

        static var grantAccess: String {
            current == .english ? "Grant Access" : "授予权限"
        }

        static var showInDock: String {
            current == .english ? "Show icon in the Dock" : "在程序坞中显示图标"
        }

        static var showInDockHint: String {
            current == .english ?
                "Off by default: a Dock icon means the app takes focus when activated. The menu-bar icon is always there." :
                "默认关闭：显示程序坞图标后，激活应用时会抢占焦点。菜单栏图标始终保留。"
        }

        static var hoverDelayLabel: String {
            current == .english ? "Hover delay" : "悬停延迟"
        }

        static var iconSizeLabel: String {
            current == .english ? "Icon size" : "图标大小"
        }

        static var autoHideLabel: String {
            current == .english ? "Auto-hide after" : "自动隐藏"
        }

        static var neverLabel: String {
            current == .english ? "Never" : "不隐藏"
        }

        static var secondsSuffix: String {
            current == .english ? "s" : " 秒"
        }
    }

    struct Fallback {
        static var sectionTitle: String {
            current == .english ? "Never use Command-C in these apps:" : "在以下应用中不使用 Command-C："
        }

        static var explanation: String {
            current == .english ?
                "Command-C is sent only where the app does not report the selection itself. It briefly changes the clipboard, which other selection tools such as PopClip react to, so they can flicker. List an app here to leave its clipboard alone." :
                "只有当应用本身不提供选中内容时才会发送 Command-C。它会短暂改变剪贴板，PopClip 等其他划词工具会因此闪烁。将应用加入此列表即可不再干扰它。"
        }

        static var empty: String {
            current == .english ?
                "No exceptions. Add an app here if another selection tool flickers in it." :
                "暂无例外。如果某个应用中其他划词工具出现闪烁，可将其加入。"
        }

        static var disabledNotice: String {
            current == .english ?
                "The Command-C fallback is off, so nothing is sent to any app." :
                "Command-C 补充取词已关闭，不会向任何应用发送。"
        }
    }

    struct Filter {
        static var windowTitle: String {
            current == .english ? "Application Filter Settings" : "应用过滤设置"
        }

        static var filterMode: String {
            current == .english ? "Filter Mode:" : "过滤模式："
        }

        static var allowAll: String {
            current == .english ? "Allow All" : "全部允许"
        }

        static var whitelist: String {
            current == .english ? "Whitelist" : "白名单"
        }

        static var blacklist: String {
            current == .english ? "Blacklist" : "黑名单"
        }

        static var explanation: String {
            current == .english ?
                "Whitelist: only the listed apps may use this helper\nBlacklist: every app except the listed ones may use this helper" :
                "白名单：仅列表中的应用可以使用划词助手\n黑名单：除列表中的应用外，其他应用均可使用划词助手"
        }

        static var applications: String {
            current == .english ? "Applications:" : "应用列表："
        }

        static var addTooltip: String {
            current == .english ? "Choose an application…" : "选择应用…"
        }

        static var removeTooltip: String {
            current == .english ? "Remove the selected application" : "移除选中的应用"
        }

        static var choosePanelPrompt: String {
            current == .english ? "Choose" : "选择"
        }

        static var choosePanelMessage: String {
            current == .english ?
                "Pick one or more applications to add to the list." :
                "选择一个或多个应用加入列表。"
        }

        static var emptyWhitelist: String {
            current == .english ?
                "No applications yet.\nThe helper will not appear anywhere until you add one." :
                "列表为空。\n在添加应用之前，划词助手不会在任何应用中出现。"
        }

        static var emptyBlacklist: String {
            current == .english ?
                "No applications yet.\nClick + to pick the apps that should not trigger the helper." :
                "列表为空。\n点击 + 选择不希望触发划词助手的应用。"
        }

        static var allowAllNotice: String {
            current == .english ?
                "The helper works in every application.\nSwitch to Whitelist or Blacklist to limit it." :
                "划词助手在所有应用中都可用。\n切换到白名单或黑名单以进行限制。"
        }
    }

    struct Dialog {
        static var allowAutolaunchTitle: String {
            current == .english ? "Allow Auto-launch with Bob" : "允许随 Bob 自动启动"
        }

        static var allowAutolaunchMessage: String {
            current == .english ?
                "macOS has registered Bob Select Helper Launcher, but you need to allow it to run in the background in System Settings > General > Login Items & Extensions. Bob Select Helper will automatically launch when you open Bob." :
                "macOS 已登记 Bob Select Helper Launcher，但需要你在\"系统设置 > 通用 > 登录项与扩展\"中允许它在后台运行。以后打开 Bob 时，Bob Select Helper 会自动启动。"
        }

        static var later: String {
            current == .english ? "Later" : "稍后"
        }

        static var welcomeTitle: String {
            current == .english ? "Bob Select Helper" : "Bob Select Helper"
        }

        static var welcomeMessage: String {
            current == .english ?
                "After selecting text by dragging, double-clicking a word, or triple-clicking a paragraph, a Bob icon will appear next to your cursor.\n\nClick the menu bar icon to customize: hover or click trigger, Bob input box behavior, auto-launch with Bob, icon size, hover delay, position, and auto-hide duration.\n\nYou'll need to grant Accessibility permissions on first use. When macOS asks if Bob Select Helper may control Bob, please allow it." :
                "拖选文字、双击单词或三击段落后，鼠标旁会出现一个 Bob 图标。\n\n点击菜单栏图标，可以自定义：悬停或点击触发、Bob 输入框总是展开/跟随/折叠、打开 Bob 时自动启动、图标大小、悬停延迟、出现位置和自动隐藏时间。\n\n首次使用需要允许辅助功能权限；系统询问是否允许控制 Bob 时，请选择允许。"
        }

        static var gotIt: String {
            current == .english ? "Got It" : "知道了"
        }

        static var errorSuffix: String {
            current == .english ?
                "\n\nPlease ensure Bob is installed and that Bob Select Helper has permission to control Bob in System Settings > Privacy & Security > Automation." :
                "\n\n请确认已经安装 Bob，并在系统设置 > 隐私与安全性 > 自动化中允许 Bob Select Helper 控制 Bob。"
        }

        static var testConnected: String {
            current == .english ? "Bob Select Helper is connected." : "Bob Select Helper 已连接。"
        }
    }
}
