# XDDesignKit

UIKit 组件库，最低支持 iOS 14，使用 Swift Package Manager。当前处于稳定内核 Alpha 阶段。

## 安装

在 Xcode 中选择 **File → Add Package Dependencies**，输入仓库地址：

```text
https://github.com/YLJunAnglee/XDDesignKit.git
```

版本规则建议选择 **Up to Next Minor Version**，起始版本填写 `0.5.0`。这样业务项目会自动获取 `0.5.x` 的兼容修复，但不会自动升级到可能包含不兼容调整的 `0.6.0`。

随后将 `XDDesignKit` Library 添加到需要使用组件的 App Target，并在代码中导入：

```swift
import XDDesignKit
```

如果项目通过 `Package.swift` 管理依赖：

```swift
dependencies: [
    .package(
        url: "https://github.com/YLJunAnglee/XDDesignKit.git",
        .upToNextMinor(from: "0.5.0")
    )
]
```

组件自带的图片资源会随 Swift Package 一起分发，业务项目不需要重复导入 Alert 复选框等组件资源。

## 架构

```text
Tokens → XDTheme → XDThemeContext → XDThemeResolver → Component
```

- `XDTheme`：完整、不可变的主题快照。
- `XDThemeContext`：全局或 scene/window 独立主题。
- `XDThemeResolver`：结合组件当前 Trait 解析颜色、字体和 Metric。
- `XDThemeComponents`：承载 Button 等组件专属 Appearance 和 Metric。

## 字体

默认字体族为 PingFang SC，Regular、Medium 和 Semibold 会映射到对应字体文件；不可用时自动回退到系统字体。

组件和稳定业务 UI 优先使用语义 Token，字号、字重、行高、字间距和 Dynamic Type 策略都由 Theme 集中管理：

```swift
let resolver = XDThemeResolver(theme: theme, traitCollection: view.traitCollection)
label.font = resolver.font(.body)
label.attributedText = NSAttributedString(
    string: "Content",
    attributes: resolver.textAttributes(font: .body, color: .textPrimary)
)
```

迁移旧代码或少量确需固定字号的界面，可使用显式逃生口：

```swift
label.font = XDFont.fixed.regular(16)
label.font = XDFont.fixed.medium(18)
label.font = XDFont.fixed.semibold(20)
```

如果同一规格在多个稳定界面重复出现，应提取为语义 `XDFontToken`，不继续复制字号。详细分层、自定义 Token 和迁移规则见 `Sources/XDDesignKit/Theme/TYPOGRAPHY.md`。

## 基础使用

```swift
import XDDesignKit

let button = XDButton(style: .primary, size: .large)
button.setTitle("Confirm", for: .normal)
button.onTap = { print("tap") }

button.setIcon(.arrowForward, placement: .trailing)
button.loadingAccessibilityValue = "Loading"
button.isLoading = true

try XDThemeManager.shared.apply(.blueTheme)
```

默认 large 按钮高度 48pt、圆角 8pt、字体 Regular 16pt。项目两种高频样式可直接使用：

```swift
let darkButton = XDButton(style: .primary, size: .large) // #222222 底、白字
let lightButton = XDButton(style: .outline, size: .large) // 白底、#222222 字和单物理像素边框
let themedButton = XDButton(style: .brand, size: .large) // 跟随品牌主题
```

当前项目不启用暗黑自动反转，因此 `primary` 和 `outline` 在 Light/Dark Mode 下保持固定产品色；`brand` 等主题型 Style 仍按主题 Token 解析。

Button 支持纯文字、纯图标，以及 leading、trailing、top、bottom 四方向图文布局。方向性图标在 RTL 环境自动镜像：

```swift
let iconButton = XDButton(style: .text, size: .small)
iconButton.setIcon(.refresh, placement: .only)
iconButton.accessibilityLabel = "Refresh"

let promotion = XDButton(style: .gradient, size: .large)
promotion.setTitle("Upgrade", for: .normal)

let vertical = XDButton(style: .outline, size: .large)
vertical.setTitle("Complete", for: .normal)
vertical.setIcon(.checkmarkCircle, placement: .top)
vertical.stackedContentPaddingOverride = 16 // nil restores the theme value
```

业务图标优先通过 `XDIconToken` 和注入的 `XDIconProviding` 解析；临时图片可使用 `setIconImage(...)`。
如果业务改用 UIButton 原生 `setImage(_:for:)`，原生图片会接管对应状态，后续主题刷新不会恢复之前的语义图标。

多 Scene 使用独立 Context：

```swift
let context = try XDThemeContext(initialTheme: .blueTheme)
let button = XDButton(themeContext: context)
```

Storyboard/Nib 创建的 Button 可在 scene 确定后调用：

```swift
button.bindThemeContext(context)
```

## Alert

`XDAlert` 是由当前 UIKit 页面显式展示的居中弹窗；它不会猜测全局窗口，因此可安全用于多 Scene 应用。所有视觉值都来自传入的 `XDThemeContext`。

```swift
XDAlert.show(
    on: self,
    title: "确定删除分类吗？",
    message: "删除分类后，该分类下的背书文档将变成无分类",
    accessory: .checkbox(title: "同时删除分类下的背书文档"),
    actions: [
        .cancel("取消"),
        .primary("删除") { context in
            print(context.checkboxIsSelected == true)
        }
    ]
)
```

输入框使用 `.textField(...)`。异步操作可把 Action 的 `automaticallyDismisses` 设为 `false`，再通过回调中的 `context.setLoading(_:)` 与 `context.dismiss()` 控制状态。

标题和正文默认使用 `.adaptive`：短文本居中，超过单行可用宽度后按自然阅读方向对齐。业务需要固定表现时，可以分别指定 `.leading` 或 `.center`：

```swift
XDAlert.show(
    on: self,
    configuration: .init(
        title: "提示",
        message: "这是一段需要固定对齐方式的说明文字。",
        actions: [.primary("知道了")],
        titleAlignment: .center,
        messageAlignment: .leading
    )
)
```

复选框图标由组件资源包提供，业务项目无需重复导入图片。复选框视觉高度遵循设计规格，实际点击热区仍保持至少 44pt。

`presenter` 必须已经关联到 `UIWindowScene`。若页面尚未进入窗口，Alert 不会绕过 Scene 协调器展示，可通过返回的 `handle.presentationFailure` 获取失败原因。

## 自定义主题

主题必须显式声明基主题：

```swift
let brandTheme = XDTheme(
    identifier: "app.brand",
    displayName: "Brand",
    colors: [
        .brandPrimary: XDThemeColor(light: brandLight, dark: brandDark)
    ],
    basedOn: .defaultTheme
)
```

非法主题会抛出 `XDThemeValidationError`。

## 编写组件

组件遵循 `XDThemeable`，并且只通过注入 Context 对应的 Resolver 获取视觉值：

```swift
func xdApplyTheme() {
    let resolver = xdThemeResolver
    backgroundColor = resolver.color(.backgroundPrimary)
    layer.borderColor = resolver.color(.borderPrimary).cgColor
    layer.borderWidth = resolver.borderWidth(.regular)
    layer.xdApplyShadow(.card, resolver: resolver)
}
```

核心规则：

- 组件实现中不写视觉魔法数字。
- 通用值使用 Foundation Token；组件专属值放组件 Theme/Metric/Appearance。
- 组件内部不混用全局主题快捷 API。
- 必须验证 Dynamic Type、VoiceOver、RTL、Dark Mode、高对比度和 Reduce Motion。
- Layer CGColor 和 Metric 约束在 `xdApplyTheme()` 中刷新。

完整架构方向见 `PROJECT_NOTES.md`，API 规则见 `API_STABILITY.md`。

## 验证

```sh
bash Scripts/verify.sh
```

该脚本执行严格并发构建、测试和 Demo 构建。

Demo 首页提供 `XDButton` 和 `XDAlert` 独立体验页。Alert 页面覆盖标准形态、附加控件、插画、关闭方式，以及默认自适应和强制文本对齐示例。
