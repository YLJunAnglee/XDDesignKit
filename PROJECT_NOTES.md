# XDDesignKit 项目说明

更新时间：2026-07-22

## 项目定位

XDDesignKit 是面向 UIKit、最低支持 iOS 14 的 Swift Package 组件库。目前暂不接入主项目，先通过独立 Demo 和测试稳定 API。

当前阶段：**内核稳定 Alpha，`XDButton` 已完成首轮通用化；`XDAlert 0.5.0` 已完成首轮标准能力、Figma 样式校准、组件资源、Theme、Scene 协调器、长内容和键盘适配，并通过专项测试与 Demo 构建。组件库尚未达到 1.0 发布标准。**

## 架构结论

```text
Foundation Tokens
    ↓
XDTheme（完整、不可变的主题快照）
    ↓
XDThemeContext（全局或 scene/window 作用域）
    ↓
XDThemeResolver（主题 + 当前 Trait）
    ↓
XDThemeable UIKit Component
```

整体判断：

| 维度 | 成熟度 | 结论 |
|---|---:|---|
| 基础架构 | 85% | 分层和扩展边界已稳定 |
| Design Token | 90% | 基础视觉规格已覆盖，字体分层已收敛 |
| 主题系统 | 90% | 支持继承、校验、Dark Mode、高对比度和多 Scene |
| Swift 6 并发 | 90% | 严格并发检查已通过 |
| API 演进能力 | 80% | 已建立规则，仍需真实业务验证 |
| 测试与工程化 | 75% | 有测试、Demo、脚本和 CI，缺视觉回归测试 |
| 组件完整度 | 35% | Button 已形成可复用基线，Alert 0.5.0 首轮能力已完成，其他基础组件尚待建设 |
| 整体组件库 | 50% | 内核稳定，Button 完成通用化，Alert 已完成首轮实现和专项验收 |

结论：大方向可以冻结。接下来应使用不同类型的组件验证内核，不再无目标地继续堆基础设施。

## 当前架构评价

评价口径需要分开：**“设计和实现质量”不等于“组件库完成度”**。当前内核和已实现组件的质量较高，但整体完成度仍为 50%，不应因局部高分误判为已达 1.0。

| 评价项 | 当前评分 | 结论 |
|---|---:|---|
| 整体架构质量 | 9.0/10 | Token 到 Component 的分层、主题作用域和扩展边界清晰 |
| 字体架构 | 9.2/10 | 语义 Token 为主、固定字号为显式逃生口，具备安全回退和主题能力 |
| `XDButton` | 9.3/10 | 视觉、状态、布局、RTL、无障碍和回归测试已形成较完整基线 |
| `XDAlert` | 8.8/10 | 标准能力、Figma 样式、资源、交互和公开对齐 API 已完成专项验收 |
| API 与扩展性 | 8.8/10 | 公共边界可扩展且保持克制，仍需真实业务验证命名和调用成本 |
| 测试与工程质量 | 9.0/10 | Package 行为测试和 Demo 构建已覆盖 Alert 新增能力，仍缺 Snapshot 回归 |
| 生产成熟度 | 7.8/10 | 缺少多类型组件、Snapshot 和真实页面接入验证 |

### 已验收的实现结果

- 基础分层、主题继承、多 Scene Context、Trait 解析和严格并发边界已通过构建与行为测试。
- `XDButton 0.3.2` 的主要功能和连续交互布局问题已验收，当前无已知功能故障。
- `0.4.0` 字体基础已实现 PingFang SC 三字重、系统回退、fixed/dynamic、自定义 Token、非法配置校验和未知 Token 安全回退。
- `0.5.0` 新增 `XDAlert`、`XDAlertTextAlignment`、组件内复选框资源及独立 Demo；新增 API 保持默认参数兼容，已覆盖自适应/强制对齐、Figma 尺寸、资源读取和点击热区测试。
- 当前完整验证基线为 56 tests、0 failures；严格并发检查、警告即错误构建和 Demo 构建均已通过。

### XDAlert 当前停点

- 已实现统一 `XDAlert.show` API，业务方无需为每个弹窗创建 `UIViewController`。
- 已覆盖单/双按钮、文字操作、复选框、输入框、插画、关闭按钮和蒙层关闭。
- 已实现 Theme 实时刷新、长内容滚动、键盘避让、Dynamic Type、Reduce Motion 和基础 VoiceOver。
- 已实现 scene-owned Overlay Coordinator，支持排队、取消、关闭后续播和 UIKit 展示失败恢复。
- 无 Scene、Presenter 失效和展示被拒绝时，通过 `XDAlertHandle.presentationFailure` 返回失败原因。
- Demo 已增加独立 `XDAlert 体验` 页面；Alert 专项设计与验收清单见 `Sources/XDDesignKit/Components/Alert/DESIGN.md`。
- 默认标题和正文使用自适应对齐，业务可分别指定 `.adaptive`、`.leading` 或 `.center`。
- 复选框图片由组件资源包提供，视觉行高与至少 44pt 的点击热区解耦；图标、文字和行内空白均可点击。

### 待验证问题清单

以下是下一阶段的验证项，**不是当前已确认缺陷**：

| 优先级 | 待验证项 | 处理阶段 |
|---|---|---|
| P1 | Theme/Trait 变化后 Label 的字体、行高、字间距和 Attributed Text 如何统一刷新 | `XDLabel` |
| P1 | Alert 长公告/横屏/超大字体、键盘、中文输入、VoiceOver、Theme 切换和连续弹窗完整人工矩阵 | 0.5.x 持续验收 |
| P1 | 超大 Dynamic Type 下的比例行高、多行、截断和布局表现 | `XDLabel` Demo 与测试 |
| P1 | 缺少 Snapshot 视觉回归，行为测试无法覆盖像素级差异 | Snapshot 阶段 |
| P2 | API 在真实业务页面中的调用成本、主题隔离和迁移体验 | 低风险页面接入 |

### 需持续守住的边界

- `XDFont.fixed` 是迁移和特殊规范的逃生口，不能变成组件和稳定业务 UI 的默认写法。
- 无 Theme 参数的全局字体快捷 API 不得用于需要多 Scene 隔离的组件内部。
- 当前只实现 Regular、Medium、Semibold；Light/Bold 等字重只在真实需求出现后扩展。
- 当前不继续重构 Token、Theme、Font 或 Button 内核；只有新组件或真实页面暴露具体问题时才重新打开相应设计。

## 已完成的内核能力

- Swift Package Manager，iOS 14+。
- 独立 UIKit Demo：`Examples/XDDesignKitDemo`。
- 可扩展语义 Token：颜色、字体、间距、圆角、边框、透明度、阴影、动效和层级。
- 字体支持 PingFang SC 默认字体族、安全系统回退、Dynamic Type/固定缩放策略、行高、字间距、自定义字体和最大缩放值。
- 字体使用“语义 `XDFontToken` 为主，`XDFont.fixed` 为迁移/一次性 UI 逃生口”的分层，不建立 Regular10–30 数字 Token 表。
- 主题支持显式 `basedOn:` 合成、完整性校验、Dark Mode 和高对比度颜色。
- `XDThemeContext` 支持全局主题和 scene/window 独立主题。
- `XDThemeResolver` 保证组件在同一上下文解析所有视觉值。
- `XDThemeable` 自动管理主题观察生命周期。
- UIKit API 和主题写入采用 `@MainActor`；不可变 Token/Metric 采用 `Sendable`。
- 组件专属规格集中在 `XDThemeComponents`，不污染通用 Token。
- `XDButton` 已具备 Appearance 状态表、固定黑白产品 Style、品牌主题 Style、selected/disabled/loading、四方向图文布局、typed Icon Provider、RTL、渐变背景、Dynamic Type 增高和最小点击区域。
- API 稳定性规则、严格验证脚本和 CI 配置。

## 强制架构规则

### Token 与视觉值

- 组件实现中禁止直接写颜色、字号、间距、圆角、边框、阴影、透明度、动画时长和层级数值。
- 通用视觉值放 Foundation Token；仅属于某个组件的值放该组件的 Theme/Metric/Appearance。
- 组件专属颜色不得加入全局 `XDColorToken`。
- 新增 Token 前必须先确认语义和复用范围。
- 组件和稳定业务 UI 使用语义 `XDFontToken`；`XDFont.fixed` 只用于旧代码迁移、少量一次性 UI 或明确要求固定字号的特殊规范。
- 同一固定字体规格在多个稳定界面重复时，必须提升为语义 Token，不继续复制魔法字号。

### 主题

- 自定义主题必须显式声明 `basedOn:`；只有完整根主题可以传 `nil`。
- 主题切换使用 `try XDThemeContext.apply(_:)` 或 `try XDThemeManager.shared.apply(_:)`。
- 组件内部只能通过自身 `XDThemeContext` 对应的 `XDThemeResolver` 获取视觉值。
- 全局快捷 Token API 只允许用于明确采用全局主题的应用层代码。
- `layer.borderColor`、`shadowColor` 和约束常量必须在 `xdApplyTheme()` 中重新应用。
- Storyboard/Nib 创建的组件在 scene 确定后必须重新绑定局部 context；Button 使用 `bindThemeContext(_:)`。

### API 与并发

- 默认使用 `internal`，只有业务调用能力才公开。
- UIKit 组件默认 `final`；确有继承需求时才设计 `open` 扩展点。
- 可扩展公共标识使用 `RawRepresentable struct + static let`，避免 public enum 新增 case 破坏穷举 switch。
- UIKit 组件、主题刷新和主题写入必须保持 `@MainActor`。
- 不得用未经审计的 `@unchecked Sendable` 消除警告。
- 详细 API 版本规则见 `API_STABILITY.md`。

### 无障碍与适配

- 新组件必须检查 Dynamic Type、VoiceOver、长文本、RTL、Dark Mode 和高对比度。
- 小型控件必须保证可点击区域，不以视觉高度代替点击区域。
- 动效通过 `XDMotionToken`，并遵守 Reduce Motion。
- `XDLayerLevel` 只负责同一容器内层级；Overlay 必须由当前 `UIWindowScene` 持有。
- 图标使用模板渲染和主题 Tint；有语义方向的图片支持 RTL 镜像；有信息含义的图片必须有无障碍描述。

## 合入门禁

每个新增组件或公共 API 必须同时具备：

- XCTest：正常、边界和失败路径。
- Demo：全部 size、style、state、长文本、Dark Mode 和业务主题。
- 不包含视觉魔法数字。
- 通过严格并发和无警告构建。
- 同步修改现有文档，不追加重复历史记录。

统一验证命令：

```sh
bash Scripts/verify.sh
```

2026-07-29 完整验证：组件库与 Demo 的严格并发、警告即错误构建均通过；83 个测试全部通过。Demo Test Target 已改为由 Demo App 承载，UIKit 控件事件测试可在有效的 `UIApplication` 生命周期中执行。Bottom Sheet 宽度回归覆盖横屏窗口变化以及横向 Safe Area 下的全宽、留边和居中策略。

## 下一阶段方向

下次继续时按以下顺序推进：

1. 完成 `XDAlert 0.5.x` 剩余的 VoiceOver、键盘、横屏和连续弹窗人工矩阵，并将问题回写 Alert `DESIGN.md`。
2. 实现 `XDLabel`，验证字体、行高、Attributed Text 和超大 Dynamic Type。
3. 使用真实业务页面验证 `XDAlert` 和 `XDButton` 的调用成本及主题隔离。
4. 实现 `XDTag` 和 `XDTextField`，继续验证小尺寸点击区域及状态优先级。
5. 引入 Snapshot 视觉回归，并接入一个低风险真实页面后再收敛 1.0 API。

两个按需建设的架构入口：

- 数字角标进入多个组件前，实现独立 `XDBadgeView` 和通用挂载边界。
- Toast 开始前，复用或扩展现有 scene-owned Alert Overlay Coordinator。
- `XDBottomSheet` 1.0 已收口：任意 `UIView` / `UIViewController` 内容承载、内容/固定/比例高度、宽度策略、键盘与安全区、遮罩和下拉关闭、唯一滚动区自动仲裁、多滚动区显式指定、Scene 串行队列、Theme 与 Handle 生命周期；Demo 已覆盖高度、宽度、滚动、键盘、交互锁定和同 Sheet 二级页面返回。后续真实业务接入属于消费侧验证，不在没有新通用需求时继续扩张 1.0 API。

## 下次继续前先读

新窗口中先读本文，即可获得当前结论、已实现结果、待验证问题和下一阶段顺序；再按当前任务读对应专项文档和源码。

- `PROJECT_NOTES.md`：结论、规则和下一步。
- `README.md`：接入与基础用法。
- `API_STABILITY.md`：公共 API 规则。
- `Sources/XDDesignKit/Theme/TYPOGRAPHY.md`：字体分层、使用边界、迁移规则和版本记忆。
- `Sources/XDDesignKit/Theme/XDTypography.swift`。
- `Sources/XDDesignKit/Theme/XDThemeResolver.swift`。
- `Sources/XDDesignKit/Components/Button/XDButton.swift`。
- `Sources/XDDesignKit/Components/Button/XDButtonTheme.swift`。
- `Sources/XDDesignKit/Components/Alert/DESIGN.md`。
- `Sources/XDDesignKit/Components/Alert/XDAlert.swift`。
- `Sources/XDDesignKit/Components/Alert/XDAlertOverlayCoordinator.swift`。
- `Sources/XDDesignKit/Components/BottomSheet/DESIGN.md`。
- `Examples/XDDesignKitDemo/XDDesignKitDemo/DemoViewController.swift`。

当前 Bottom Sheet 状态：**1.0 公共签名和基础行为已收口。下一步可在业务项目接入“挖空 → AI 快速挖空 → 返回”进行消费侧验证；多档 Detent、内置导航和其他新能力只有出现多个一致业务需求后才另行设计。**

## 文档维护规则

- 本文只记录当前有效结论，不保存开发流水账、已解决故障或过期方案。
- 状态发生变化时直接修改原章节，不在末尾重复追加新结论。
- README 只放使用方法；本文件只放架构状态和方向；API 兼容规则只放 `API_STABILITY.md`。
- 完成一项后更新成熟度、验证基线和下一阶段列表，并删除已失效内容。
