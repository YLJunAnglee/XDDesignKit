# XDDesignKit Agent API 速查

用于根据 UI 需求选择 XDDesignKit API。完整接入和架构说明见 `README.md`。

当前可用业务组件有 `XDButton`、`XDCheckboxButton`、`XDMoreButton`、`XDCloseButton`、`XDAlert` 和 `XDBottomSheet`。不要假设存在 `XDLabel`、`XDTag`、`XDTextField` 等未实现组件。

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

## 专用图标按钮

| UI 意图 | API |
| --- | --- |
| 列表/卡片完成状态，本地立即切换 | `XDCheckboxButton(isSelected:)` + `onValueChanged` |
| 列表/卡片完成状态，接口成功后才切换 | `selectionBehavior: .requiresConfirmation` + `onValueChangeRequest` |
| 列表/卡片更多操作 | `XDMoreButton()` + `onTap` |
| 页面、卡片或自定义弹层的关闭入口 | `XDCloseButton()` + `onTap`；需要 28pt 视觉图标时用 `XDCloseButton(visualSize: .large)` |

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
more.onTap = { showMoreActions(for: item) }

let close = XDCloseButton(visualSize: .large)
close.onTap = { dismiss(animated: true) }
```

三者默认布局和点击区均为 44pt。`XDCloseButton` 默认视觉图标为居中的 24pt，需要与 28pt 业务图标对齐时使用 `visualSize: .large`；无论视觉尺寸为何都不要把点击区约束为视觉尺寸，也不要让相邻可点击控件侵入该区域。不传文字、不提供通用 Style 或 Loading。需要场景主题隔离时，在初始化时传入 `themeContext`。

`XDCheckboxButton` 默认 `.immediate`，点击后马上更新并发送 `.valueChanged` / `onValueChanged`。`.requiresConfirmation` 点击后只调用 `onValueChangeRequest`，期间 `isPending == true` 且不可重复点击；成功调用 `resolveSelectionChange(to:)`（此时才发送状态变化通知），失败调用 `cancelSelectionChange()` 并保留原状态。复用列表单元格前先取消未完成请求或确保异步回调仍对应同一条数据。

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

## XDBottomSheet

`XDBottomSheet` 只负责通用底部容器：遮罩、Surface、安全区、键盘、下拉关闭、Scene 队列和生命周期。标题、关闭按钮、拖拽指示条、列表、按钮和业务页面导航全部由调用方自己实现；不要假设存在 `XDBottomSheetController`、内置标题栏、`push` / `pop` 或多档 Detent API。

按内容复杂度选择入口：

| 场景 | 使用方式 |
| --- | --- |
| 一次性的简单操作内容 | `contentView:` |
| 列表、输入、异步状态或复杂约束 | `contentViewController:` |
| Sheet 内“一级 → 二级 → 返回” | 一个业务 `UIViewController` 内自行切换，再调用 `invalidateLayout()` |
| Sheet → 全屏业务页 → 返回原 Sheet | `handle.presentOverlay(...)`，全屏页正常 `dismiss` |
| 连续但彼此独立的弹层 | `dismiss(animated:completion:)` 后展示下一层；同 Scene 也会自动串行排队 |

```swift
let handle = XDBottomSheet.show(
    on: self,
    contentViewController: optionsViewController,
    configuration: .init(height: .content)
)
```

可传任意 `UIView` 或普通 `UIViewController`；不需要也不能继承组件库的 Controller。`UIViewController` 适合复杂页面、输入和 Sheet 内的一级/二级页面切换，`UIView` 适合简单内容。

```swift
XDBottomSheet.show(
    on: self,
    contentView: contentView,
    configuration: .init(
        height: .content(maximum: 520),
        width: .fullWidth,
        allowsBackgroundDismissal: true,
        allowsSwipeDismissal: true
    ),
    events: .init(
        onDidDismiss: { reason in
            // reason: .backgroundTap / .swipe / .programmatic / ...
        }
    )
)
```

### 高度、宽度与内容约束

| 需求 | API | 内容要求 |
| --- | --- | --- |
| 跟随内容高度 | `.content` | 根 View 必须有完整的纵向 Auto Layout 约束或有效 intrinsic size |
| 跟随内容但不超过上限 | `.content(maximum: 520)` | 超出后由业务内容自身滚动 |
| 固定面板高度 | `.fixed(360)` | 内容过高时业务自行提供滚动区 |
| 屏幕可用高度比例 | `.fraction(0.65)` | 内容过高时业务自行提供滚动区 |
| 贴满窗口宽度 | `.fullWidth` | 默认；Surface 覆盖横屏安全区背景 |
| 两侧留白 | `.horizontalInsets(20)` | 留白从横向安全区域继续计算 |
| 居中并限制最大宽度 | `.centered(maximumWidth: 560)` | 宽度在横向安全区域内解析 |

高度最终都受当前安全区和键盘剩余空间限制。宽度默认 `.fullWidth`，iPhone 横屏和 iPad 下都覆盖整个窗口宽度，不因横向安全区自动留白；业务控件仍应使用自身 View 的 `safeAreaLayoutGuide` 避让刘海、灵动岛等区域。

例如，业务根内容应填充容器，内部控件在横向使用安全区：

```swift
view.addSubview(stack)
stack.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    stack.topAnchor.constraint(equalTo: view.topAnchor),
    stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
    stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    stack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
])
```

`.content` 不会自动把超高内容包进 `UIScrollView`。列表、表单或长文本应由业务内容自行管理滚动。

内容超过可用高度时，业务内容自行使用 `UIScrollView`、`UITableView` 或 `UICollectionView`。组件会自动识别唯一、可见且可纵向滚动的 Scroll View；多个纵向滚动区域同时可见时不会猜测优先级，必须明确指定参与下拉仲裁的主滚动区：

```swift
handle.setPrimaryScrollView(tableView)
```

内容 Controller 的 `preferredContentSize` 变化会自动重算高度，默认带标准动效；需要立即更新时，在 Configuration 中传 `animatesContentSizeChanges: false`。内容增删、`preferredContentSize` 以外的约束变化，或 Sheet 内页面完成切换后调用 `handle.invalidateLayout()`。同一业务流程的“挖空 → AI 快速挖空 → 返回”应在一个业务内容 Controller 内自行切换页面，不要叠加多个 Sheet。

```swift
// 业务内容完成页面切换、添加列表项或改动约束后
handle.invalidateLayout()
```

需要从 Sheet 临时进入全屏业务页，并在退出后恢复同一个 Sheet 实例时，使用 `presentOverlay`。组件会从内部完整 Sheet 容器展示页面并强制使用 `.overFullScreen`，因此原 Sheet 的内容、分页缓存和选择状态不会销毁。业务页按普通方式调用 `dismiss(animated:)` 返回；不要先关闭 Sheet，也不要从业务内容子 Controller 自行 `present`。

```swift
let detail = DetailViewController()
let navigation = UINavigationController(rootViewController: detail)

guard handle.presentOverlay(navigation) else { return }

// DetailViewController 内
navigationController?.dismiss(animated: true)
```

同一时间只允许一个覆盖页。可通过 `handle.isPresentingOverlay` 判断状态；Sheet 尚未完成展示、正在关闭、已有覆盖页，或目标 Controller 已属于其他层级时，`presentOverlay` 返回 `false`。覆盖页不是新的 Sheet，不参与 Sheet 展示队列，也不会触发 Sheet 的 `onWillDismiss/onDidDismiss`。

### 关闭、事件与展示状态

`handle.dismiss(animated:completion:)` 主动关闭；`presentOverlay` 从内部完整容器展示临时全屏业务页；`isInteractiveDismissalEnabled` 可运行时同时开关遮罩点击、下拉和无障碍 Escape，不影响代码主动关闭；`cancelPendingPresentation()` 只取消尚未展示的排队请求。`onWillDismiss` / `onDidDismiss` 每次展示最多各触发一次，外部或系统关闭使用 `.system`。展示必须从已进入当前 `UIWindowScene` 的 Controller 发起；失败可读取 `presentationFailure`。

```swift
handle.isInteractiveDismissalEnabled = false // 提交中，锁定交互关闭
handle.dismiss(animated: true) {
    // 关闭完成后的业务收尾
}

if handle.presentationFailure != nil {
    // .presenterNotAttachedToScene / .presenterUnavailable / .presentationRejected
    // 业务自行记录失败或恢复入口状态
}
```

仅在 `isPending == true` 且尚未展示时使用 `cancelPendingPresentation()`；不要用它关闭已经可见的 Sheet。`isPresented`、`isPending` 和 `presentationFailure` 都只读。

底部 Surface 默认只提供 Theme 的背景和顶部圆角，系统底部安全区由容器计入。底部停靠键盘出现后 Surface 停靠在键盘顶部；iPad 浮动键盘不会整体顶起 Surface。业务内容不要重复加设备底部安全区常量。视觉通过 `XDBottomSheetTheme`（`XDThemeComponents.bottomSheet`）统一配置，不在单次调用中传颜色、圆角或动画参数。

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
