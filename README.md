# XDDesignKit

UIKit 组件库，最低支持 iOS 14，使用 Swift Package Manager。当前处于稳定内核 Alpha 阶段。

## 安装

在 Xcode 中选择 **File → Add Package Dependencies**，输入仓库地址：

```text
https://github.com/YLJunAnglee/XDDesignKit.git
```

版本规则建议选择 **Up to Next Minor Version**，起始版本填写 `0.5.2`。这样业务项目会自动获取 `0.5.x` 的兼容修复，但不会自动升级到可能包含不兼容调整的 `0.6.0`。

随后将 `XDDesignKit` Library 添加到需要使用组件的 App Target，并在代码中导入：

```swift
import XDDesignKit
```

如果项目通过 `Package.swift` 管理依赖：

```swift
dependencies: [
    .package(
        url: "https://github.com/YLJunAnglee/XDDesignKit.git",
        .upToNextMinor(from: "0.5.2")
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
let lightButton = XDButton(style: .outline, size: .large) // 白底、#222222 字、#CDCFD4 固定 1 pt 边框
let transparentOutlineButton = XDButton(style: .outlineTransparent, size: .large) // 透明底、#222222 字、#CDCFD4 固定 1 pt 边框
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

## 专用图标按钮

列表或卡片里的完成状态使用 `XDCheckboxButton`；它会自行切换状态，并同时发送 UIKit 的 `.valueChanged` 事件。更多操作使用无状态的 `XDMoreButton`；页面、卡片或自定义弹层的关闭入口使用 `XDCloseButton`：

```swift
let checkbox = XDCheckboxButton(isSelected: item.isCompleted)
checkbox.onValueChanged = { item.isCompleted = $0 }

let confirmedCheckbox = XDCheckboxButton(
    isSelected: item.isCompleted,
    selectionBehavior: .requiresConfirmation
)
confirmedCheckbox.onValueChangeRequest = { desiredValue in
    updateCompletedOnServer(desiredValue) { success in
        success
            ? confirmedCheckbox.resolveSelectionChange(to: desiredValue)
            : confirmedCheckbox.cancelSelectionChange()
    }
}

let more = XDMoreButton()
more.onTap = { [weak self] in self?.showMoreActions(for: item) }

let close = XDCloseButton()
close.onTap = { [weak self] in self?.dismiss(animated: true) }
```

三者默认布局和点击区均为 44pt，视觉图标为居中的 24pt；不要把它们约束为 24pt 或让相邻可点击控件侵入该区域。不提供标题、通用 Style 或 Loading 参数。

`XDCheckboxButton` 默认点击即切换。接口成功后才更新状态时，初始化传入 `selectionBehavior: .requiresConfirmation`：点击只触发 `onValueChangeRequest` 并进入 `isPending`，成功调用 `resolveSelectionChange(to:)`，失败调用 `cancelSelectionChange()`。

## Toggle

`XDToggle` 用于设置项等二元开关。控件承载 `52 × 44pt` 的布局和点击区域，视觉轨道为居中的 `52 × 28pt`；关闭轨道为 `#D9D9D9`，开启轨道为 `#212121`，滑块为白色。

```swift
let autoBlankToggle = XDToggle(isOn: settings.autoWordHollow)
autoBlankToggle.onValueChanged = { isOn in
    settings.autoWordHollow = isOn
}
```

需要等接口成功后才提交状态时，使用确认模式。请求期间控件进入 `isPending` 并阻止重复点击；成功提交时才发送 `.valueChanged`，失败则保持原值：

```swift
let autoBlankToggle = XDToggle(
    isOn: settings.autoWordHollow,
    selectionBehavior: .requiresConfirmation
)
autoBlankToggle.onValueChangeRequest = { requestedValue in
    saveAutoBlankSetting(requestedValue) { success in
        success
            ? autoBlankToggle.resolveValueChange(to: requestedValue)
            : autoBlankToggle.cancelValueChange()
    }
}
```

业务需要根据本地缓存或接口结果刷新时，使用 `setOn(_:animated:)`；该方法只刷新 UI，不发送 `.valueChanged`。

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

输入框推荐使用 `.textInput(...)`，默认保持单行；`.textField(...)` 仍保留用于兼容旧代码。多行输入可选择按可见行数、绝对高度或不设输入框自身上限；达到上限后输入框内部滚动：

```swift
accessory: .textInput(
    placeholder: "请输入反馈内容",
    maximumLength: 200,
    layout: .multiline(maximum: .lines(4)),
    onLimitReached: { limit in
        print("输入限制：\(limit)")
    }
)

// 也可使用 .height(160) 或 .unlimited
```

异步操作可把 Action 的 `automaticallyDismisses` 设为 `false`，再通过回调中的 `context.setLoading(_:)` 与 `context.dismiss()` 控制状态。

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

单行名称输入需要显示字数时，配合 `maximumLength` 启用 `showsCharacterCount`；右侧显示 `当前字数/上限`。未启用时保持普通输入框，计数样式不支持多行：

```swift
accessory: .textInput(
    placeholder: "请输入试卷名称",
    maximumLength: 15,
    showsCharacterCount: true
)
```

复选框图标由组件资源包提供，业务项目无需重复导入图片。复选框视觉高度遵循设计规格，实际点击热区仍保持至少 44pt。

`presenter` 必须已经关联到 `UIWindowScene`。若页面尚未进入窗口，Alert 不会绕过 Scene 协调器展示，可通过返回的 `handle.presentationFailure` 获取失败原因。

## Bottom Sheet

`XDBottomSheet` 是承载任意 UIKit 内容的通用底部容器，只管理 Surface、遮罩、安全区、键盘、下拉关闭与 Scene 队列；标题、按钮、列表以及 Sheet 内页面切换由业务内容实现。

```swift
let handle = XDBottomSheet.show(
    on: self,
    contentViewController: clozeOptionsController,
    configuration: .init(height: .content, width: .fullWidth)
)
```

也可传 `contentView:`。高度支持 `.content`、`.content(maximum:)`、`.fixed(_)`、`.fraction(_)`；宽度支持 `.fullWidth`、`.horizontalInsets(_)` 和 `.centered(maximumWidth:)`。`.fullWidth` 的 Surface 覆盖整个窗口，横屏内容使用自身 `safeAreaLayoutGuide` 避让刘海或灵动岛。内容变化或 Sheet 内页面完成切换后，调用 `handle.invalidateLayout()`。唯一可见的纵向滚动区会自动参与下拉仲裁；多个纵向滚动区域同时可见时，用 `handle.setPrimaryScrollView(_:)` 明确指定主滚动区。

需要临时进入全屏业务页并原样返回当前 Sheet 时，调用 `handle.presentOverlay(viewController)`；覆盖页退出时正常 `dismiss`，原 Sheet 不销毁、不重建。

同一业务流程的 Sheet 内二级页面仍在同一个内容 Controller 内自行切换，不叠加多个 Sheet；只有真正的全屏业务页使用 `presentOverlay`。视觉统一通过 `XDThemeComponents.bottomSheet` 的 `XDBottomSheetTheme` 配置；完整约束见 `AGENT_API_GUIDE.md` 和 `Components/BottomSheet/DESIGN.md`。

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

Demo 首页提供 `XDButton`、`XDAlert` 和 `XDBottomSheet` 独立体验页。Bottom Sheet 页面覆盖自适应/固定/比例高度、宽度策略、滚动协调、键盘避让、交互锁定、同一 Sheet 内二级页面返回，以及全屏覆盖页返回原 Sheet；Alert 页面覆盖标准形态、附加控件、插画、关闭方式，以及默认自适应和强制文本对齐示例。

## 面向 Agent 的 API 指南

如果需要让其他 Agent 根据 UI 需求生成 XDDesignKit 代码，请先阅读 [`AGENT_API_GUIDE.md`](AGENT_API_GUIDE.md)。该文档按“UI 效果 → API”组织，并记录持续维护规则。
