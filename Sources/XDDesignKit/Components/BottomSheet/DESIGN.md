# XDBottomSheet 设计

本文是 `XDBottomSheet` 的实现前设计基线，记录已经确认的组件边界、公共 API 草案、内部架构、交互契约和验收范围。

- 当前状态：1.0 基础能力已收口；支持临时全屏覆盖页；多档 Detent 不在 1.0 范围内
- 最低系统：iOS 14
- 更新时间：2026-07-29

## 设计目标

`XDBottomSheet` 是 UIKit 的通用底部弹层容器。它统一承载、展示、关闭、高度、安全区、键盘、手势和生命周期，但不提供任何业务内容样式。

主要目标：

- 同时承载任意 `UIView` 和普通 `UIViewController`。
- 业务方无需继承组件库基类。
- 内容 UI、内容导航和业务状态完全由调用方管理。
- 自适应内容高度，并支持固定高度、屏幕比例高度和动态更新。
- 正确协调下拉关闭与内部纵向滚动。
- 统一处理底部安全区、键盘避让、旋转和窗口尺寸变化。
- 显式绑定当前 `UIWindowScene`，不查找全局 Window。
- 提供可观察、可取消、不会重复回调的展示与关闭生命周期。
- 复用 XDDesignKit 的 Theme、Motion、Strict Concurrency 和 Overlay 架构规则。
- 保持第一版能力克制，为后续兼容扩展保留内部边界。

## 非目标

第一版明确不负责：

- 标题、关闭按钮、拖拽指示条、列表、卡片、输入框和操作按钮。
- 内容内部间距和业务视觉规范。
- 居中 Alert、顶部面板、侧边抽屉、气泡菜单和锚点菜单。
- 多档 Detent、向上拖动扩展和多位置吸附。
- Sheet 内置导航栏、导航栈或固定页面转场。
- 自动把超高业务内容包装进 `UIScrollView`。
- 自动查找 Key Window、最上层 Controller 或其他全局展示宿主。
- 暴露内部容器 Controller 给业务方继承或直接操作。

居中标准弹窗继续使用 `XDAlert`。未来其他方向的 Overlay 可以复用内部 Scene 协调能力，但应设计为独立组件。

## 组件边界

```text
业务内容
├── UIView
└── UIViewController
        ↓
内部 Content Adapter
        ↓
Bottom Sheet Container
├── Child Controller containment
├── Surface 与遮罩
├── 高度与宽度布局
├── Safe Area 与 Keyboard
├── Pan 与 Scroll 协调
├── Theme 与 Motion
└── Accessibility
        ↓
Scene-owned Overlay Coordinator
├── 展示归属
├── Sheet 串行队列
├── 取消和失败恢复
└── 与其他 UIKit Overlay 的层级协调
```

### 容器负责

- 遮罩层和底部 Surface。
- Surface 顶部圆角、背景和裁剪。
- 展示、关闭、交互下拉和取消回弹动画。
- 当前宽度下的内容高度测量。
- 屏幕安全区域内的最大可用高度。
- 底部安全区和键盘避让。
- 内部 Scroll View 与 Sheet Pan Gesture 的仲裁。
- 子 Controller 的 UIKit containment 和生命周期。
- 展示排队、取消、失败和关闭回调去重。
- Theme、Dark Mode、高对比度、Reduce Motion 和无障碍模态语义。

### 内容负责

- 所有标题、按钮、拖拽指示条、列表和卡片 UI。
- 内容内边距和业务配色。
- 输入、加载、错误、禁用和异步提交状态。
- 内容内部的滚动视图。
- 同一 Sheet 内的一级、二级页面导航。
- 页面切换动画、返回逻辑、状态保留和业务埋点。

## Surface 契约

默认 Surface 只包含：

- Theme 定义的背景。
- Theme 定义的顶部圆角。
- 系统底部安全区。
- 用于裁剪内容的边界。

容器不内置拖拽指示条、标题栏、关闭按钮和内容间距。内容根 View 填充 Surface 的内容区域；业务约束使用容器提供的安全区域，不自行叠加设备底部高度。

Surface 延伸到窗口底部。无键盘时，容器把系统底部安全区计入 Sheet 总高度；键盘出现后，Surface 停靠在键盘顶部，不重复保留设备底部安全区。

## 公共 API 草案

以下签名用于验证职责和调用成本，不代表实现前已经冻结到逐字符兼容。实现阶段可以在不改变已确认语义的前提下调整标签和组织方式。

### 展示入口

```swift
@MainActor
public enum XDBottomSheet {
    @discardableResult
    public static func show(
        on presenter: UIViewController,
        contentView: UIView,
        configuration: XDBottomSheetConfiguration = .init(),
        events: XDBottomSheetEvents = .init(),
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDBottomSheetHandle

    @discardableResult
    public static func show(
        on presenter: UIViewController,
        contentViewController: UIViewController,
        configuration: XDBottomSheetConfiguration = .init(),
        events: XDBottomSheetEvents = .init(),
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDBottomSheetHandle
}
```

`UIViewController` 是内部规范承载形式。`UIView` 入口由内部 Adapter 包装成 Child Controller，两个入口最终走同一套布局、生命周期和展示实现。

### Configuration

```swift
@MainActor
public struct XDBottomSheetConfiguration {
    public let height: XDBottomSheetHeight
    public let width: XDBottomSheetWidth
    public let animatesContentSizeChanges: Bool
    public let allowsBackgroundDismissal: Bool
    public let allowsSwipeDismissal: Bool

    public init(
        height: XDBottomSheetHeight = .content,
        width: XDBottomSheetWidth = .fullWidth,
        animatesContentSizeChanges: Bool = true,
        allowsBackgroundDismissal: Bool = true,
        allowsSwipeDismissal: Bool = true
    )
}
```

Configuration 只表达调用级布局和行为，不接收标题、按钮、颜色、圆角、动画时长或手势阈值。

### 高度策略

高度策略需要覆盖：

```swift
.content
.content(maximum: ...)
.fixed(...)
.fraction(...)
```

`XDBottomSheetHeight` 及其上限类型应使用带私有存储的公共 `struct` 和静态工厂，避免 public enum 被业务穷举后阻塞兼容扩展。

参数约束：

- 固定高度必须为有限正数。
- 屏幕比例必须处于有效范围。
- 最终高度始终受当前安全区域和键盘剩余空间限制。
- 非法配置不能在 Debug 与 Release 下产生不同布局结果。
- 具体采用 precondition、可失败工厂还是安全归一化，在实现前结合 XDDesignKit 现有验证风格统一确定。

`.content` 是默认值。它根据当前可用宽度测量内容；内容可能超高时，业务方必须提供自己的 `UIScrollView`、`UITableView` 或 `UICollectionView`。

### 宽度策略

宽度策略需要覆盖：

```swift
.fullWidth
.horizontalInsets(...)
.centered(maximumWidth: ...)
```

默认在 iPhone、iPad、横屏和分屏下均为 `.fullWidth`，Surface 背景覆盖完整窗口宽度，不因横向 Safe Area 自动缩窄。业务内容使用自身 `safeAreaLayoutGuide` 避让刘海、灵动岛等区域。调用方可以按单个 Sheet 选择左右留白或底部居中的最大宽度布局；这些非全宽策略在横向安全区域内解析。

`XDBottomSheetWidth` 使用带私有存储的公共 `struct` 和静态工厂。所有数值必须有限且合法；窗口尺寸变化后重新解析实际宽度。

### Events

```swift
@MainActor
public struct XDBottomSheetEvents {
    public let onDidPresent: (() -> Void)?
    public let onWillDismiss: ((XDBottomSheetDismissalReason) -> Void)?
    public let onDidDismiss: ((XDBottomSheetDismissalReason) -> Void)?

    public init(
        onDidPresent: (() -> Void)? = nil,
        onWillDismiss: ((XDBottomSheetDismissalReason) -> Void)? = nil,
        onDidDismiss: ((XDBottomSheetDismissalReason) -> Void)? = nil
    )
}
```

事件闭包运行在 Main Actor。展示失败不伪装成关闭事件，通过 Handle 的失败状态返回。

### Handle

```swift
@MainActor
public final class XDBottomSheetHandle {
    public var isPresented: Bool { get }
    public var isPending: Bool { get }
    public var isPresentingOverlay: Bool { get }
    public var presentationFailure: XDBottomSheetPresentationFailure? { get }
    public var isInteractiveDismissalEnabled: Bool { get set }

    public func dismiss(
        animated: Bool = true,
        completion: (() -> Void)? = nil
    )

    public func cancelPendingPresentation()
    public func invalidateLayout(animated: Bool = true)
    public func setPrimaryScrollView(_ scrollView: UIScrollView?)

    @discardableResult
    public func presentOverlay(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) -> Bool
}
```

Handle 是轻量控制接口，不暴露容器 Controller。

- `dismiss` 对已展示或正在展示的 Sheet 生效，并保证 completion 只调用一次。
- `cancelPendingPresentation` 只取消尚未展示的排队请求。
- `invalidateLayout` 重新测量当前页面，用于内容增删或 Sheet 内页面切换。
- `isInteractiveDismissalEnabled` 动态控制遮罩、下拉和无障碍 Escape 等交互关闭，不影响代码主动关闭。
- 简单内容由组件自动协调滚动；多个滚动区域并存时，调用方通过 `setPrimaryScrollView` 明确主纵向滚动区域。
- `presentOverlay` 从内部完整 Sheet 容器以 `.overFullScreen` 展示任意业务 Controller；退出覆盖页后恢复同一 Sheet 实例，不重新进入 Scene 队列，也不触发 Sheet 关闭事件。覆盖页的导航结构和转场仍由业务方负责。

实现阶段需要进一步判断是否把 pending/presented 状态收敛为只读状态值，避免多个 Bool 出现瞬时歧义。

### 关闭原因

`XDBottomSheetDismissalReason` 使用 `RawRepresentable struct + static let`，初始语义至少包含：

- 遮罩点击。
- 下拉手势。
- 代码主动关闭。
- 无障碍 Escape。
- 展示宿主失效或系统中断。

关闭生命周期必须去重：

- `onWillDismiss` 最多一次。
- `onDidDismiss` 最多一次。
- 主动 `dismiss` 的 completion 最多一次。
- 手势关闭进行中再次调用 `dismiss` 不创建第二条关闭流程。

展示失败类型沿用 `XDAlertPresentationFailure` 的设计风格，但保持组件语义独立；至少区分 Presenter 未附着 Scene、Presenter 失效和 UIKit 拒绝展示。

## 内容尺寸契约

### UIView

测量步骤：

1. 根据宽度策略解析 Surface 实际宽度。
2. 得到内容可用宽度。
3. 使用 Auto Layout 在固定宽度下执行 `systemLayoutSizeFitting`。
4. 加入容器负责的底部安全区。
5. 应用高度策略和当前最大可用高度。

`.content` 要求根 View 在垂直方向具有完整约束或有效 intrinsic content size。约束不完整时不能猜测业务期望高度；实现应提供明确的诊断或稳定失败行为。

### UIViewController

内部必须正确调用：

- `addChild(_:)`
- 添加并约束 Child View
- `didMove(toParent:)`
- 移除时对应调用 `willMove(toParent:)` 和 `removeFromParent()`

高度优先级设计为：

1. 调用方显式选择的固定或比例策略。
2. `.content` 下有效的 `preferredContentSize.height`。
3. 当前宽度下对 Child 根 View 进行 Auto Layout fitting。

内容 Controller 修改 `preferredContentSize` 时，容器应自动响应 UIKit 的 Child Content Container 通知；由 `animatesContentSizeChanges` 决定该次高度更新是否动画，默认开启。其他约束变化由业务调用 `invalidateLayout(animated:)`。

### 动态高度

- 内容高度改变时只更新 Surface 高度，不重新执行完整展示动画。
- Sheet 内一级、二级页面高度不同，切换完成后可以动画更新。
- 内容高度超过可用空间时只限制 Surface，不自动增加 Scroll View。
- Dynamic Type、旋转、分屏和 Theme Metric 改变时自动重新测量。

## 同一 Sheet 内的页面导航

业务上下级页面属于内容职责：

```text
一个 XDBottomSheet
└── 业务内容 Controller
    ├── 一级页面：挖空方式
    └── 二级页面：AI 快速挖空配置
```

进入二级页面时：

- 业务内容自己执行 Child Controller 或内部导航切换。
- Surface、遮罩和展示生命周期保持不变。
- 页面完成布局后调用 `invalidateLayout(animated:)`。
- 返回时恢复一级页面和对应高度。
- 下拉关闭会关闭整个业务流程。

第一版不公开 `push`、`pop`、`replaceContent` 或内置导航栏。多个业务证明存在一致的 Sheet 内导航模式后，再独立评估 `XDBottomSheetNavigationController`。

## 安全区与键盘

固定规则：

- 无键盘时，容器处理设备底部安全区，业务不叠加 `Screen.bottomSafeAreaHeight` 一类常量。
- 键盘出现时，Surface 底部跟随键盘顶部。
- 最大可用高度随键盘剩余空间变化。
- 键盘动画使用系统通知中的时间和曲线。
- 内容负责内部输入控件和滚动到当前光标。
- 容器负责整体 Sheet 的位置和最大高度，避免业务与容器双重顶起。
- 关闭 Sheet 前结束编辑并收起键盘。
- 键盘显示期间的遮罩与下拉关闭仍服从 Configuration 和 Handle 当前状态。

iOS 14 使用键盘 Frame 通知实现；不得依赖仅在更高系统可用的 Keyboard Layout Guide。只有与当前内容输入焦点关联的底部停靠键盘会整体顶起 Surface；iPad 浮动键盘不改变 Surface 的底部停靠位置。

## 下拉与内部滚动协调

默认可以从 Surface 内容区域任意位置开始向下拖动，不要求存在拖拽指示条。

仲裁规则：

- 主 Scroll View 未到顶部时，纵向手势只滚动内容。
- 主 Scroll View 到达顶部并继续向下拖时，Sheet 接管向下位移。
- 向上滑动优先交给内容滚动。
- 横向轮播、分页和其他正交手势不应被 Sheet Pan Gesture 阻断。
- 未达到关闭条件时，Sheet 平滑回弹。
- 达到关闭条件后进入唯一的交互关闭流程。
- 交互关闭被禁用时，内容滚动和控件点击保持正常。

简单内容可以自动发现唯一、可见、纵向滚动的 Scroll View。多个候选同时存在时，不猜测业务优先级；业务通过 Handle 指定主 Scroll View。

关闭阈值、速度阈值、阻尼和橡皮筋系数属于组件内部交互 Metric。先通过原型和真机手感校准，再进入 `XDBottomSheetTheme` 或内部策略，不作为调用级参数。

## 展示与队列

- 每次展示必须传入已经进入 `UIWindowScene` 的 UIViewController。
- 同一个 Scene 同一时间只允许一个 Bottom Sheet 处于活动展示流程。
- 当前 Sheet 未关闭时，新请求进入该 Scene 的 Sheet 队列，不覆盖和叠加。
- 排队请求持有弱 Presenter；轮到展示时再次验证 Presenter 和 Scene。
- 排队请求可以通过 Handle 取消。
- 不同 Scene 拥有独立队列和活动 Sheet。
- 业务上连续的独立 Sheet 仍优先使用 `dismiss(completion:)` 明确表达流程。
- 普通 `XDAlert` 可以展示在活动 Sheet 上方，关闭后回到原 Sheet。

队列只服务相互独立的 Sheet，不用于同一个 Sheet 内的上下级内容页面。

## Overlay 架构

`XDAlert` 已有 scene-owned Coordinator。Bottom Sheet 实现前应提取或扩展内部通用能力，但不能为了复用破坏已验证的 Alert 行为。

建议内部结构：

```text
XDSceneOverlayCoordinator
├── Alert Channel
│   ├── active alert
│   └── alert queue
└── Bottom Sheet Channel
    ├── active sheet
    └── sheet queue
```

需要共享：

- Scene 级关联对象和生命周期。
- 弱 Presenter 的 Pending Presentation。
- 合法展示宿主解析。
- UIKit 展示拒绝后的失败恢复。
- 取消排队项。
- 关闭后推进队列。

需要独立：

- Alert 与 Sheet 的队列。
- 各自的 Controller 类型、Handle 和失败语义。
- Sheet 的交互关闭状态机。

实现前先为现有 Alert Coordinator 补足回归测试，再进行内部提取。若通用化会扩大首轮风险，可以先让两个 Coordinator 共享小型内部 Host Resolver 和 Scene Owner，不强制一次完成大重构。

## 内部状态机

建议使用单一状态机，不使用多个互相推断的 Bool：

```text
idle
  ↓
queued
  ↓
presenting
  ↓
presented
  ↔ interactivelyDragging
  ↓
dismissing
  ↓
dismissed

queued / presenting → failed
queued → cancelled
```

状态机负责：

- 拒绝重复展示和重复关闭。
- 拖拽过程中接收代码关闭。
- 正在回弹时再次开始手势。
- 排队时取消。
- Presenter 或 Scene 中途失效。
- UIKit presentation 被拒绝。
- 生命周期和 completion 去重。

## 转场

- 展示：Surface 从底部进入，遮罩渐入。
- 关闭：Surface 向底部退出，遮罩渐隐。
- 交互下拉：Surface 跟随手指，遮罩按进度变化。
- 取消关闭：Surface 从当前位置回弹。
- 内容高度变化：只更新高度约束。
- Sheet 内页面左右切换：由业务内容负责。
- 动画使用 `XDMotion` 解析结果并遵守 Reduce Motion。

动画时间、曲线和变换参数不作为每次展示的公开配置。

## Theme

新增 `XDBottomSheetTheme` 并挂载到 `XDThemeComponents.bottomSheet`。组件专属 Theme 至少承载：

- 遮罩颜色 Token。
- 遮罩透明度 Token。
- Surface 背景色 Token。
- 顶部圆角 Token。
- 最大可用高度相关 Metric。
- 组件内部交互与转场 Metric，前提是经过原型校准。

宽度策略属于每次展示的布局需求，不由设备类型自动决定；`.fullWidth` 是默认值。

标题、正文、关闭按钮、指示条、卡片、列表和业务内容间距不进入 Bottom Sheet Theme。

默认 Theme 的精确颜色、透明度、圆角和 Motion 必须结合已选 Figma 设计及现有业务弹层验证后确定，不在设计阶段自行发明数值。

## Accessibility

- Surface 标记为无障碍模态区域。
- 展示完成后把焦点移动到内容指定的首要元素；未指定时使用稳定的默认顺序。
- 允许交互关闭时响应 VoiceOver Escape，并返回对应关闭原因。
- 禁止交互关闭时，Escape 不关闭 Sheet。
- 动效遵守 Reduce Motion。
- Dynamic Type 增长触发重新测量。
- 横向语义使用 leading/trailing。
- 内容本身的 Label、Button、Image 和输入控件无障碍语义由业务负责。

## 内存与并发

- 所有 UIKit API、事件回调、Theme 刷新和状态转换保持 `@MainActor`。
- Pending Presentation 弱持有 Presenter。
- Coordinator 持有排队请求和活动容器，关闭后及时释放。
- Handle 不应形成对业务内容的永久强引用。
- 内容闭包应按业务生命周期使用弱引用，组件不替业务修复循环引用。
- 不使用未经审计的 `@unchecked Sendable`。

## 预计文件结构

```text
Components/BottomSheet/
├── XDBottomSheet.swift
├── XDBottomSheetConfiguration.swift
├── XDBottomSheetContext.swift
├── XDBottomSheetTheme.swift
├── XDBottomSheetContainerViewController.swift
├── XDBottomSheetContentAdapter.swift
├── XDBottomSheetLayout.swift
├── XDBottomSheetInteractionController.swift
├── XDBottomSheetOverlayCoordinator.swift
└── DESIGN.md
```

具体拆分以实现后的职责为准，不为了文件数量机械拆分。纯布局解析、状态转换和关闭决策应尽量从 UIKit View 更新中分离，便于 XCTest 覆盖。

## 实施顺序

1. 用最小原型验证 Auto Layout 高度、底部安全区和键盘规则。
2. 用 `UITableView` 原型验证 Scroll View 顶部与下拉手势仲裁。
3. 为现有 Alert Coordinator 补充即将被复用路径的回归测试。
4. 实现高度、宽度、关闭原因、失败类型和状态机等纯模型。
5. 实现 UIView / UIViewController Adapter 和 Child containment。
6. 实现 Surface、遮罩、布局和 Theme。
7. 实现展示、关闭、交互下拉和 Scene 队列。
8. 实现键盘、旋转、分屏、Dynamic Type 和 Accessibility。
9. 建设简单菜单、长列表、输入弹层、异步锁定和同 Sheet 二级页面 Demo。
10. 同步更新 `XDThemeComponents`、`AGENT_API_GUIDE.md`、README 和 `PROJECT_NOTES.md`。
11. 执行 `bash Scripts/verify.sh`，通过测试、严格并发、警告即错误和 Demo 构建。

## 测试矩阵

### 模型与状态

- 高度和宽度合法值、边界值及非法值。
- 状态机所有合法转换和重复调用。
- 生命周期、关闭原因和 completion 只触发一次。
- 排队取消、Presenter 失效和 presentation rejection。

### 内容与布局

- UIView intrinsic height 和完整 Auto Layout height。
- UIViewController preferredContentSize 和 Auto Layout fallback。
- 固定高度、比例高度、内容上限和屏幕最大高度。
- full width、左右留白、居中最大宽度。
- 内容动态增减和页面切换后的高度动画。
- 底部安全区、横屏、iPad 分屏和窗口尺寸变化。
- Dynamic Type、Dark Mode、高对比度和 Theme 动态切换。

### 交互

- 遮罩、下拉、代码和 VoiceOver Escape 关闭。
- 动态禁止与恢复交互关闭。
- Scroll View 未到顶部、到顶部、overscroll 和横向手势。
- 拖拽取消、速度关闭、距离关闭和动画中重复操作。
- Reduce Motion。

### 键盘

- 键盘显示、Frame 改变和关闭。
- 中文等输入法 marked text。
- 内容高度超过键盘剩余空间。
- 关闭前结束编辑。
- 业务未重复监听键盘时布局正确。

### Overlay 与生命周期

- Presenter 未附着 Scene。
- 同 Scene 连续 Sheet 串行。
- 不同 Scene 独立展示。
- 活动 Sheet 上展示并关闭 XDAlert。
- Child Controller appearance 和 containment 生命周期。
- Handle、内容 Controller 和 Coordinator 无泄漏。

## Demo 场景

首轮 Demo 至少包括：

1. 简单操作菜单：UIView、自适应高度、遮罩和下拉关闭。
2. 长列表：UITableView、最大高度和滚动手势仲裁。
3. 输入弹层：键盘、动态内容和异步期间禁止交互关闭。
4. 同 Sheet 二级页面：一级进入配置页、返回并动画更新高度。
5. 连续独立弹层：关闭 completion 和 Scene 队列。
6. 宽度策略：iPad 全宽、左右留白和居中最大宽度。
7. Dark Mode、业务 Theme、Dynamic Type 和 Reduce Motion。

## 验收清单

- 业务无需继承组件库 Controller。
- UIView 和 UIViewController 入口行为一致。
- 容器不包含业务标题栏、按钮或内容间距。
- 所有高度和宽度策略在旋转及分屏后正确。
- Safe Area 和键盘没有重复留白或双重顶起。
- 长列表滚动与下拉关闭自然且无抢手势。
- 交互关闭可以动态锁定。
- 同一 Sheet 内页面切换不产生第二层遮罩或第二次展示动画。
- 独立 Sheet 串行且可以取消排队。
- Alert 可以安全展示在 Sheet 上方。
- 生命周期、关闭原因和失败结果准确且只返回一次。
- VoiceOver、Dynamic Type、RTL、Dark Mode、高对比度和 Reduce Motion 可用。
- 不存在全局 Window 查找、业务基类依赖或视觉魔法数字。
- XCTest、严格并发、警告即错误和 Demo 构建全部通过。

## 已确认的架构决策

### 2026-07-29：组件定位和职责

- 只封装 Bottom Sheet 基础框架，不封装固定业务样式。
- 容器只提供遮罩、Surface、顶部圆角和底部安全区。
- 标题、关闭按钮、拖拽指示条和内容间距由业务负责。
- 不扩展为通用方向 Overlay。

### 2026-07-29：内容与导航

- 同时支持 UIView 和普通 UIViewController。
- 内部统一使用 Child Controller 承载，不要求业务继承基类。
- 同一 Sheet 内的上下级页面由业务内容导航。
- 第一版不提供内置 push/pop 和多档 Detent。

### 2026-07-29：布局和交互

- 默认内容自适应高度，支持固定、比例和动态更新。
- 超高内容由业务提供 Scroll View，容器不自动包装。
- 默认所有设备全屏宽，同时支持其他宽度策略。
- 默认允许遮罩和下拉关闭，并允许异步期间动态锁定。
- 下拉区域覆盖 Surface，内部纵向滚动按顶部状态进行仲裁。
- 容器统一处理安全区和键盘。

### 2026-07-29：展示和扩展

- 每次展示显式传入 UIViewController，并绑定当前 UIWindowScene。
- 独立 Sheet 在同一 Scene 串行；业务连续流程优先使用关闭 completion。
- 使用 Handle 和事件闭包，不公开 Controller 或 Delegate。
- 基础视觉由 XDBottomSheetTheme 管理，调用方不逐次覆盖颜色、圆角和动画参数。
- 公共命名统一使用 `XDBottomSheet` 前缀。
