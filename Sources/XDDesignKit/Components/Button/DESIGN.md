# XDButton 设计与版本记录

本文是 `XDButton` 的长期设计记忆，记录当前有效的组件边界、架构决策、实施计划和版本变更。

- 当前状态：`XDButton 0.3.2` 已实现并通过验证
- 当前库版本：`0.4.0`
- 最低系统：iOS 14
- 更新时间：2026-07-19

## 设计目标

`XDButton` 是通用 UIKit 操作按钮，不对应某一个业务页面。它需要覆盖项目中高频的按钮形态，同时保持默认调用简单、旧代码可渐进迁移、特殊业务可组合扩展。

主要目标：

- 支持纯文字、纯图标以及图文组合。
- 支持图标位于标题的 leading、trailing、top、bottom。
- 支持填充、描边、透明文字和渐变背景。
- 支持 normal、highlighted、selected、disabled 和 loading 行为。
- 支持主题切换、按 Style 决定是否响应 Dark Mode、高对比度、Dynamic Type、VoiceOver 和 RTL。
- 视觉尺寸和可点击区域分离，小按钮仍保证最小点击区域。
- 尽量兼容 `UIButton` 的标题、状态和事件 API，不引入全局副作用。
- 公共 API 保持精简，内部能力按职责拆分并可单独测试。

## 实际场景归类

从现有业务截图归纳出以下类型：

| 类型 | 归属 |
|---|---|
| 纯文字、填充、描边按钮 | `XDButton` 核心能力 |
| 文字 + leading/trailing 图标 | `XDButton` 核心能力 |
| 纯图标按钮 | `XDButton`，视觉尺寸与点击区域分离 |
| 上图下文、上文下图 | `XDButton` 内容布局能力 |
| 渐变背景按钮 | `XDButton` Appearance + 独立背景 Renderer |
| 图标上的数字或圆点 | 独立 `XDBadgeView`，后续与按钮组合 |
| 勾选框、复选项 | 后续独立 `XDCheckbox`，不作为按钮样式 |
| 多个按钮组成的工具栏 | 页面或独立容器组合，不由单个按钮管理 |

## 组件边界

按钮能力拆成五个相互独立的维度：

```text
XDButton
├── Style       视觉风格
├── Size        尺寸规格
├── Content     标题、图标和排列
├── State       交互状态
└── Background  透明、纯色或渐变背景
```

### Style

Style 只定义视觉表现，不决定内容排列和外部宽度。

内置 Style：

- `primary`：项目高频深色实心按钮，固定 `#222222` 背景和白色前景。
- `outline`：项目高频白底描边按钮，固定白色背景、`#222222` 前景和固定 `1 pt` 边框。
- `outlineTransparent`：透明底描边按钮，固定 `#222222` 前景和固定 `1 pt` 边框；按下时使用浅灰反馈。
- `brand`：跟随主题品牌色的实心按钮，保留原 `primary` 的换肤能力。
- `secondary`：跟随主题的次级按钮。
- `text`：透明背景的品牌文字按钮。
- `gradient`：跟随主题品牌色的渐变按钮。

`primary` 与 `outline` 是产品视觉规范，不随系统 Light/Dark Mode 自动反转；其他使用语义主题 Token 的 Style 仍按主题定义解析。固定色只注册在 Button Theme 的局部颜色表中，不污染 Foundation Color Token，也不改变全局 Theme 的暗黑能力。

业务可继续通过 `XDButtonStyle(rawValue:)` 和主题 Appearance 增加自定义样式，不需要修改组件源码。

### Size

Size 负责组件专属 Metric：

- 最小视觉高度
- 水平、垂直内容边距
- 字体 Token
- 圆角 Token
- 图标尺寸
- 图文间距
- 上下图文布局专属的顶部、底部留白

这些值属于 Button Theme，不作为组件实现中的魔法数字。Dynamic Type 可能使按钮高度超过最小视觉高度。

### Content

首轮支持一个主图标，位置为：

- leading
- trailing
- top
- bottom
- icon only

leading/trailing 是语义方向，RTL 下自动交换；top/bottom 不随 RTL 改变。

当前真实场景没有证明同一个按钮必须同时显示 leading 和 trailing 两个图标。内部布局应保留增加 accessory icon 的空间，但首轮不提前公开双图标 API。后续增加第二图标属于兼容性扩展。

### State

视觉状态优先级延续当前规则：

```text
disabled > highlighted > selected > normal
```

Loading 是交互与内容展示模式，不加入 `XDComponentState` 的颜色状态表：

- Loading 时阻止重复触发。
- 不覆盖调用方设置的 `isEnabled`。
- 有标题时保留标题，以 loading indicator 替换或补充主图标。
- 纯图标按钮用 loading indicator 替换图标。
- Loading 结束后恢复原内容。
- Indicator 使用当前 Appearance 的内容颜色。
- VoiceOver 能识别当前处于加载状态。

### Background

Appearance 不直接绑定某一种渲染实现，而是描述背景：

```text
clear
solid(color token)
gradient(gradient token)
```

背景 Renderer 负责 `UIColor` 和 `CAGradientLayer` 的创建、更新与清理。按钮状态或主题改变时只提交新的背景描述，避免渐变逻辑散落在 `XDButton` 中。

渐变如果会被其他组件复用，应建设为 Foundation Gradient Token；在只有 Button 使用时，先保持 Button Theme 范围，确认复用后再上移，避免过早污染通用 Token。

## 公共 API 原则

以下为设计方向，不代表实现前已经冻结的最终签名：

```swift
let button = XDButton(style: .primary, size: .large)
button.setTitle("选择段落", for: .normal)
button.setIcon(.arrowForward, placement: .trailing)
button.isLoading = true
```

API 需要遵循：

- 继续兼容 `setTitle(_:for:)`、`setAttributedTitle(_:for:)`、`addTarget`、`isEnabled` 和 `isSelected`。
- 图标位置使用 leading/trailing，不使用 left/right。
- 推荐使用 `XDIconToken` 和 typed Icon Provider。
- 保留明确的 `UIImage` 逃生入口，支持旧业务渐进迁移和临时图片。
- 调用原生 `setImage(_:for:)` 时，该图片接管对应状态并清除该状态已有的语义 Icon 定义。
- 新初始化参数必须提供默认值，现有初始化调用不受影响。
- 可扩展公共标识使用 `RawRepresentable struct + static let`，不使用可被穷举的 public enum。
- 不公开仅为内部布局服务的视图和约束。
- 自定义 Size 未在主题中配置 Metric 时安全回退到 large，不能递归或崩溃。
- 上下布局默认留白由 Size Metric 统一管理，单个按钮可通过 `stackedContentPaddingOverride` 临时覆盖。

## Icon Provider

Icon Provider 负责把语义 Token 解析成可显示图标，并携带必要元信息：

- 图片来源：Asset Catalog、Bundle 或 SF Symbol。
- 是否使用模板渲染。
- 是否为方向性图标并在 RTL 下镜像。
- Trait 改变后是否需要重新解析。

约束：

- Provider 是可选依赖，不使用全局可变注册表。
- Provider 不放入不可变的 `XDTheme` 快照。
- `XDButton` 提供默认 Provider，业务可通过初始化注入自定义 Provider。
- UIKit 图片解析和按钮更新保持在主线程。

## 内部实现建议

当前文件结构：

```text
Components/Button/
├── XDButton.swift
├── XDButtonStyle.swift
├── XDButtonTheme.swift
├── XDButtonIcon.swift
├── XDButtonLayout.swift
├── XDButtonBackground.swift
└── DESIGN.md
```

职责：

- `XDButton`：公共 API、状态协调、主题刷新和事件控制。
- `XDButtonTheme`：Button Appearance 与 Metric。
- `XDButtonIcon`：Token、Provider、图标元信息和 UIImage 逃生入口。
- `XDButtonLayout`：纯布局输入与输出，不持有 UIView。
- `XDButtonBackground`：透明、纯色、渐变描述和背景 Renderer。

Loading 逻辑当前保留在 `XDButton`。只有职责明显膨胀时才提取 Presenter，避免为了拆分而拆分。

## 布局策略

优先复用 `UIButton` 原生的 `titleLabel`、`imageView`、状态标题和状态图片。组件通过 `titleRect(forContentRect:)` 和 `imageRect(forContentRect:)` 提供布局结果，不在 `layoutSubviews` 后直接争抢原生子视图 frame。

布局计算器接收：

- 可用 bounds
- content insets
- title size
- icon size
- content spacing
- icon placement
- layout direction
- loading 状态

输出：

- title frame
- icon frame
- loading indicator frame
- intrinsic content size

布局计算与 UIView 更新分开后，可以用 XCTest 直接验证 LTR、RTL、上下排列、长文本和边界尺寸。

## 无侵入性约束

- 不 swizzle UIKit 方法。
- 不设置全局 `UIButton.appearance()`。
- 不依赖业务 ViewController、页面基类或特殊容器。
- 不要求一次性替换现有 `UIButton`。
- 不使用全局可变 Icon 注册表。
- 不改变现有 Theme Context 的职责。
- 不在按钮内部写死业务图片、文案、颜色或尺寸。
- 不用修改 `isEnabled` 的方式实现 loading。
- 不让 Badge、Checkbox 等独立语义污染 Button 核心状态。

## 实施顺序

1. 扩展 Button Theme Metric 和 Appearance，并保证旧初始化兼容。
2. 实现纯布局计算器及其单元测试。
3. 实现纯文字、纯图标和 leading/trailing/top/bottom 图文布局。
4. 完成 RTL、Dynamic Type、长文本和 intrinsic size。
5. 实现 loading 行为与无障碍状态。
6. 实现透明、纯色、描边和渐变背景 Renderer。
7. 完善 Demo 的 style、size、state、内容排列和主题矩阵。
8. 执行 `bash Scripts/verify.sh`，修复所有测试、并发和警告问题。
9. 验证完成后更新版本号、README、PROJECT_NOTES 和本文版本记录。
10. 后续独立实现 `XDBadgeView`，再提供与 Button 的组合入口。

## 验收清单

- 所有内置 style × size 可正常展示。
- normal、highlighted、selected、disabled 状态优先级正确。
- 纯文字、纯图标及四方向图文布局正确。
- leading/trailing 在 RTL 下交换，方向性图片正确镜像。
- 图标和标题颜色随状态更新；主题型 Style 响应主题、Dark Mode 和高对比度，固定产品 Style 保持指定颜色。
- Dynamic Type 下按钮可以增高，标题不会被错误裁切。
- 小尺寸按钮仍满足主题定义的最小点击区域。
- Loading 阻止重复操作，结束后恢复内容和原有 enabled 语义。
- 渐变层不会重复叠加，布局和主题变化时正确刷新。
- VoiceOver 标签、值和 traits 合理。
- 自定义 Theme Metric、Appearance 和 Icon Provider 可生效。
- 原生 UIImage 与语义 Icon 的状态所有权明确，主题刷新不会恢复已被替换的旧图标。
- XCTest、严格并发、警告即错误和 Demo 构建全部通过。

## 架构决策记录

### 2026-07-19：从真实业务按钮反推能力

- 决定支持纯文字、纯图标、横向图文和纵向图文。
- 决定 Style、Size、Content、State、Background 分离。
- 决定优先保持 UIButton 原生 API 和行为。
- 决定 loading 不作为新的颜色状态。
- 决定 Icon 使用 typed Provider，同时保留 UIImage 逃生入口。
- 决定渐变由独立背景 Renderer 实现。
- 决定 Badge 和 Checkbox 不进入 Button 核心职责。
- 决定首轮仅公开一个主图标，双图标在真实需求出现后兼容扩展。

### 2026-07-19：高频黑白按钮作为 Style，而不是全局 Theme

- 决定将深色实心按钮定义为 `primary`，将白底描边按钮定义为 `outline`，让最高频调用保持简洁。
- 决定新增 `brand` 承接原 `primary` 的主题品牌色能力，避免丢失换肤场景。
- 决定固定黑白色仅属于 Button Appearance，不加入全局颜色 Token，不影响其他组件。
- 当前项目未启用暗黑模式自动反转，因此 `primary` 与 `outline` 在 Light/Dark Mode 下保持相同产品色。
- 边框宽度进入每个状态的 Appearance；`outline` 使用 `regular` Token，固定为 `1 pt`，不随屏幕倍率变化。

## 版本记录

记录规则：

- 每次发布直接在对应版本下记录有效变化。
- 分类使用“新增、修改、修复、移除”。没有内容的分类不保留。
- 同步更新 `Sources/XDDesignKit/XDDesignKit.swift` 中的版本号。
- 版本发布前必须通过 `bash Scripts/verify.sh`。
- 本节记录组件变化；项目整体状态仍同步维护在根目录 `PROJECT_NOTES.md`。

### 0.3.2

#### 修改

- 图文布局改为通过 UIButton 官方 `titleRect(forContentRect:)` 与 `imageRect(forContentRect:)` 扩展点接管，继续复用原生标题、图片和状态 API。
- Auto Layout 回归测试扩展为连续切换 leading、trailing、top、bottom、icon-only、LTR/RTL 及上下留白覆盖值。

#### 修复

- 修复交互过程中连续切换图标位置、RTL 和上下留白后，UIKit 后续布局覆盖自定义 frame，造成图标下沉、贴顶、未居中或与标题重叠的问题。

### 0.3.1

#### 修复

- 修复图文组合布局分别取整导致的 1pt 间距损失；leading、trailing、top、bottom 现在保留 Theme Metric 声明的完整间距。
- 新增图文组合在直接布局和 `UIStackView` Auto Layout 环境下的回归测试，确保标题与图标整体居中、对齐且不越出按钮边界。

### 0.3.0

#### 新增

- 新增 `brand` Style，保留原有随主题切换的品牌色实心按钮。
- 新增 `bodyLarge` 字体 Token，默认规格为 Regular 16pt、24pt 行高。
- 新增 `thin` 边框 Token，默认宽度为 0.5pt。
- `XDButtonStateAppearance` 新增可选 `borderWidthToken`，允许每个状态声明自己的边框宽度。
- `XDButtonTheme` 新增组件局部颜色表，允许 Button 使用固定产品色而不污染 Foundation Color Token。

#### 修改

- `primary` 调整为固定 `#222222` 背景、白色前景的项目高频按钮。
- `outline` 调整为固定白色背景、`#222222` 前景及边框的项目高频按钮。
- large Size 调整为 Regular 16pt，并继续保持 48pt 高度和 8pt 圆角。
- 独立体验页和样式矩阵增加 `brand`，可直接比较固定产品色与主题品牌色。

#### 修复

- `primary` 与 `outline` 不再因系统切换 Dark Mode 而自动反转颜色，符合当前项目视觉规范。
- 描边按钮边框从 1pt 修正为设计稿要求的 0.5pt。

### 0.2.2

#### 新增

- `XDButtonMetric` 新增 `stackedContentPadding`，独立控制 top/bottom 图文排列时的顶部和底部留白。
- `XDButton` 新增 `stackedContentPaddingOverride`，允许单个按钮覆盖主题默认值，设为 `nil` 恢复 Theme Metric。
- 独立体验页新增“紧凑 / 默认 / 宽松”上下布局留白切换。

#### 修改

- large、medium、small 上下布局的默认垂直留白分别调整为 12、10、8pt，不改变普通横向按钮的高度和留白。

#### 修复

- 修复 top/bottom 图文排列时内容接近按钮上下边缘、视觉过于拥挤的问题。

### 0.2.1

#### 新增

- 新增独立 `XDButtonDemoViewController`，支持交互切换样式、状态、图标位置、LTR/RTL、主题与明暗模式。
- 新增自定义 Size 兜底、组合状态优先级、自定义 Icon Provider、Dynamic Type、原生 UIImage 接管、Loading 恢复和 fill 对齐测试。

#### 修改

- 原生 `setImage(_:for:)` 调用现在会接管对应状态，并清除该状态的语义 Icon 定义。
- 布局计算器完整处理水平和垂直 `.fill` 对齐，并规范极小 bounds 下的可用区域。
- Loading 无障碍状态只移除组件自己添加的 trait，并始终恢复进入 Loading 前的 value。

#### 修复

- 修复自定义 Button Size 未配置 Metric 时递归查找导致的栈溢出风险，统一回退到 large Metric。
- 修复 Loading 期间清空加载文案时可能残留旧 accessibilityValue 的问题。
- 修复主题刷新可能覆盖业务通过原生 `setImage` 设置图片的问题。

### 0.2.0

#### 新增

- 新增 `XDIconToken`、`XDIconProviding`、默认 SF Symbols Provider 和 UIImage 逃生入口。
- 新增 leading、trailing、top、bottom、icon-only 图文布局。
- 新增纯布局计算器，支持 LTR、RTL、内容对齐和受限宽度。
- 新增 `isLoading`、loading indicator、重复操作拦截和无障碍加载状态。
- 新增 Button Background 描述、渐变 Renderer 和内置 `gradient` style。
- 新增图标尺寸、图文间距和独立图标颜色 Theme Metric。
- 新增完整 Demo 状态矩阵和可执行的 Demo XCTest Target。

#### 修改

- `XDButtonStateAppearance` 从单一背景颜色扩展为透明、纯色或渐变背景描述，并保留 `backgroundToken` 兼容读取。
- `XDButton` 在保持 `UIButton` 标题、图片、状态和事件 API 的基础上接管内容布局。
- 统一验证脚本改用共享 Demo Scheme 执行 UIKit XCTest。

#### 修复

- 修复受限宽度下长标题可能超出内容边距的问题。
- 修复渐变状态切换可能累积图层或产生隐式动画的问题。
- 保证 loading 不覆盖调用方的 `isEnabled` 状态。
- 保证 icon-only 不让隐藏标题参与 intrinsic size 和布局。

### 0.1.0

#### 新增

- 建立 `XDButton` 的 primary、secondary、outline、text 样式。
- 建立 large、medium、small 尺寸和组件专属 Theme Metric。
- 支持 normal、highlighted、selected、disabled Appearance 状态表。
- 支持主题切换、Dynamic Type 增高和最小点击区域。
- 支持按钮重新绑定 scene/window 对应的 `XDThemeContext`。

#### 修复

- 避免 primary 和 text 的 disabled 状态出现意外边框。
- 保证 intrinsic width 只计算一次水平内容边距。
