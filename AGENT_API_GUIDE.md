# XDDesignKit Agent API 速查

用于根据 UI 需求选择 XDDesignKit API。完整接入和架构说明见 `README.md`。

当前可用业务组件只有 `XDButton` 和 `XDAlert`。不要假设存在 `XDLabel`、`XDTag`、`XDTextField` 等未实现组件。

本库面向 UIKit（iOS 14+），业务 Target 使用前先 `import XDDesignKit`。本页覆盖 XDDesignKit 特有的 UI 选择和约束，不重复 UIKit 继承 API。视觉以 `Examples/XDDesignKitDemo` 为准，精确签名以 `Sources/XDDesignKit` 为准；冲突时遵循源码并更新本页。

## XDButton

```swift
let button = XDButton(style: .primary, size: .large)
button.setTitle("确认", for: .normal)
button.onTap = { submit() }
```

按 UI 意图选择：

| UI 意图 | API |
| --- | --- |
| 高频主操作，固定深色底 | `.primary` |
| 跟随品牌主题的主操作 | `.brand` |
| 次要操作 | `.secondary` |
| 白底描边 | `.outline` |
| 低强调文字操作 | `.text` |
| 营销渐变操作 | `.gradient` |
| 大、中、小尺寸 | `.large` / `.medium` / `.small` |
| 左、右、上、下图标 | `.leading` / `.trailing` / `.top` / `.bottom` |
| 纯图标按钮 | `.only`，并设置 `accessibilityLabel` |
| 内置语义图标 | `.arrowForward` / `.checkmarkCircle` / `.refresh` |
| 禁用、选中、加载 | `isEnabled` / `isSelected` / `isLoading` |

影响 UI 的参数：

| API | 参数作用 |
| --- | --- |
| `XDButton(style:size:themeContext:iconProvider:)` | 样式、尺寸、主题作用域、语义图标来源 |
| `setIcon(_:placement:for:)` | Token、位置、对应 `UIControl.State` |
| `setIconImage(_:placement:mirrorsInRightToLeftLayout:usesTemplateRendering:for:)` | 自定义图片、RTL 镜像、模板渲染、状态 |
| `apply(style:size:)` | 运行时切换样式，可同时切换尺寸 |
| `bindThemeContext(_:)` / `bindIconProvider(_:)` | 运行时切换主题作用域 / 图标来源；通常在初始化时传入 |
| `stackedContentPaddingOverride` | 临时覆盖上/下图文布局留白；`nil` 恢复主题值 |
| `loadingAccessibilityValue` | Loading 时的 VoiceOver 文案 |

图标优先使用语义 Token：

```swift
button.setIcon(.arrowForward, placement: .trailing)
```

仅临时或业务专属图片使用 `setIconImage(...)`。原生 `setTitle`、`setAttributedTitle`、`setImage` 和 `addTarget` 仍可使用；不要用 `isEnabled = false` 模拟 Loading。

`XDButton` 只用于单标题、单图标操作；副标题、角标、头像或复杂组合内容改用 UIKit 或扩展组件库。视觉由 Style、Size 和 Theme 控制，不直接覆盖背景、圆角、高度或内容边距。`stackedContentPaddingOverride` 必须是有限非负数。

## XDAlert

普通提示：

```swift
XDAlert.show(
    on: self,
    title: "操作完成",
    message: "修改已保存。",
    actions: [.primary("知道了")]
)
```

按 UI 意图选择：

| UI 意图 | API |
| --- | --- |
| 主操作 | `.primary(...)` |
| 取消操作 | `.cancel(...)` |
| 删除等危险操作 | `.destructive(...)` |
| 低强调操作 | `.text(...)` |
| 复选项 | `accessory: .checkbox(...)` |
| 单行输入 | `accessory: .textInput(...)` |
| 多行输入 | `.textInput(..., layout: .multiline(maximum: ...))` |
| 插画 | `XDAlertIllustration` |
| 右上角关闭 | `showsCloseButton: true` |
| 点击蒙层关闭 | `allowsBackgroundDismissal: true` |
| 自适应、靠语义起始侧、居中对齐 | `.adaptive` / `.leading` / `.center` |

插画、右上角关闭和文字对齐需使用 `XDAlert.show(on:configuration:)`；普通标题、正文、Accessory 和 Actions 可使用便捷重载；两个重载均可传 `themeContext`。

完整标准形态由这些参数组合：

```text
XDAlertConfiguration(
    title: String? = nil,
    message: String? = nil,
    illustration: XDAlertIllustration? = nil,
    accessory: XDAlertAccessory? = nil,
    actions: [XDAlertAction] = [],
    allowsBackgroundDismissal: Bool = false,
    showsCloseButton: Bool = false,
    titleAlignment: XDAlertTextAlignment = .adaptive,
    messageAlignment: XDAlertTextAlignment = .adaptive
)
```

标题、正文、插画和 Accessory 可按需组合；`actions` 决定无按钮、单按钮或多按钮形态。配置至少要有一项内容；没有 Action 时必须启用关闭按钮或蒙层关闭。

恰好两个非 `.text` Action 时横排，其他情况竖排；Action 按数组顺序创建，界面方向交给系统处理。

Accessory 参数：

| 类型 | 可用参数 |
| --- | --- |
| `.checkbox(...)` | `title`、`isSelected`、`isEnabled` |
| `.textInput(...)` | `placeholder`、`text`、`keyboardType`、`isSecureTextEntry`、`maximumLength`、`showsCharacterCount`、`layout`、`onLimitReached` |
| 单行布局 | `.singleLine`（默认） |
| 多行布局 | `.multiline(maximum: .lines(n) / .height(h) / .unlimited)` |

Secure 输入只支持单行。插画参数为 `image`、可选 `caption` 和可选 `accessibilityLabel`。Action 工厂均支持 `title`、`automaticallyDismisses` 和 `handler`；需要自定义语义/外观组合时使用 `XDAlertAction(title:role:appearance:...)`。

分类名、试卷名等需要让用户感知剩余字数时，设置 `maximumLength` 并启用 `showsCharacterCount: true`；输入框右侧显示 `当前字数/上限`。该样式只支持单行，默认关闭。

```swift
accessory: .textInput(
    placeholder: "请输入试卷名称",
    maximumLength: 15,
    showsCharacterCount: true
)
```

自定义 Action 的 `role` 可选 `.normal` / `.cancel` / `.destructive`，`appearance` 可选 `.filled` / `.outlined` / `.text`。Action 和 Checkbox 标题不能为空；`maximumLength`、`.lines(n)` 和 `.height(h)` 必须为正数；`onLimitReached` 接收 `.maximumLength` 或 `.maximumHeight`。

需要复选或输入结果时，从 Action Context 获取：

```swift
.primary("提交") { context in
    let checked = context.checkboxIsSelected
    let text = context.textFieldText
}
```

异步操作不立即关闭：

```swift
.primary("提交", automaticallyDismisses: false) { context in
    context.setLoading(true)
    // 完成后 context.dismiss()
}
```

Alert 必须从已进入 `UIWindowScene` 的当前 `UIViewController` 展示。新代码使用 `.textInput(...)`；`.textField(...)` 仅为旧调用兼容。

输入键盘出现时，Alert 在安全区到键盘顶部的可用区域内分配留白：顶部约 3/4、底部约 1/4；内容过高时内部滚动并保持当前光标可见。

`XDAlert.show` 返回 `XDAlertHandle`，可读取 `isPresented`、`presentationFailure`，或调用 `dismiss(animated:)`。

一个 Alert 最多一个 Accessory。多个输入、富文本、列表或任意自定义 View 不属于标准 Alert；改用自定义 UIKit 页面/弹层或先扩展组件库。

## 普通 UIKit UI

没有对应组件时，使用 UIKit，并优先使用语义 Token：

```swift
label.font = XDFont.font(.body, compatibleWith: traitCollection)
label.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
stack.spacing = XDSpacing.md
```

稳定 UI 不直接写颜色、字号、间距、圆角和边框值。`XDFont.fixed` 仅用于迁移、一次性 UI 或明确固定字号的设计。

内置基础 Token：

| 用途 | API 与内置 Token |
| --- | --- |
| 颜色 `XDColor.color` | `.brandPrimary`、`.brandPrimaryHighlighted`、`.brandPrimaryDisabled`、`.brandPrimarySubtle`、`.textPrimary`、`.textSecondary`、`.textTertiary`、`.textInverse`、`.backgroundPrimary`、`.backgroundSecondary`、`.backgroundHighlighted`、`.backgroundDisabled`、`.borderPrimary`、`.borderStrong`、`.shadowPrimary` |
| 字体 `XDFont.font` | `.title1`、`.title2`、`.title3`、`.bodyLarge`、`.body`、`.bodyMedium`、`.caption`、`.captionMedium` |
| 间距 `XDSpacing` | `.xxs`、`.xs`、`.sm`、`.md`、`.lg`、`.xl` |
| 圆角 `XDRadius` | `.xs`、`.sm`、`.md`、`.lg`、`.pill` |
| 边框 `XDBorder` | `.hairline`、`.thin`、`.regular`、`.strong` |
| 透明度 `XDOpacity` | `.subtle`、`.disabled`、`.overlay` |
| 阴影 `layer.xdApplyShadow` | `.none`、`.card`、`.floating` |
| 动效 `XDMotion.resolved` | `.instant`、`.fast`、`.standard`、`.emphasized`；自动适配 Reduce Motion |

多 Scene 主题隔离时传入独立 `XDThemeContext`；普通页面默认使用全局 Context。

只使用本页列出的内置值。只有任务明确提供自定义 Theme 或 `XDIconProviding` 时，才能创建自定义 raw value。

## 生成代码检查

- UIKit 和主题操作在主线程执行。
- 使用 `.leading` / `.trailing`，不使用 left/right 表达语义方向。
- 纯图标按钮和有含义的插画包含无障碍描述。
- 检查长文本、Dynamic Type、RTL 和 Dark Mode。
- 不使用全局窗口查找 Alert 宿主。
- 设计超出组件能力时使用 UIKit 或提出扩展，不拼凑、不臆造 API。

## 维护

新增或修改公共组件、Style、Token、参数、默认值、布局规则或组合限制时同步更新本页。这里只写“什么情况下用什么 API”；安装说明放 `README.md`，架构状态和未实现规划放 `PROJECT_NOTES.md`，详细设计放组件 `DESIGN.md`。
