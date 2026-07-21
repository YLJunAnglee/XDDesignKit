# XDDesignKit 字体架构与版本记录

本文是字体系统的长期设计记忆，记录当前有效的分层、使用边界、迁移方式和版本变更。
项目整体评价、已验收结果和跨组件待验证清单统一维护在根目录 `PROJECT_NOTES.md`，本文不重复记录。

- 当前状态：`0.4.0` 已实现并通过验证
- 默认字体族：PingFang SC
- 最低系统：iOS 14
- 更新时间：2026-07-19

## 设计目标

字体系统需要同时解决两个问题：

- 稳定界面不应到处写 `16`、`18` 等无语义字号，否则规范调整时需全项目搜索修改。
- 迁移旧代码和极少数一次性界面仍需要指定精确字号，不应为 10–30pt 的每个组合制造 Token 爆炸。

因此采用“语义为主，固定字号为显式逃生口”的分层，而不是简单罗列 `regular10 ... semibold30`。

## 架构分层

```text
XDFontFamily
    字体文件 / UIFont.Weight 映射
        ↓
XDFontStyle
    字号 + 字重 + 行高 + 字间距 + 缩放策略
        ↓
XDFontToken
    业务语义，例如 title2、body、captionMedium
        ↓
XDThemeResolver / XDLabel / 其他组件
```

### XDFontFamily

`XDFontFamily` 只负责字体族和字重映射，不包含字号或界面语义。默认映射与主项目保持一致：

| UIFont.Weight | 字体名 |
|---|---|
| `.regular` | `PingFangSC-Regular` |
| `.medium` | `PingFangSC-Medium` |
| `.semibold` | `PingFangSC-Semibold` |

字体名不可用时自动回退到对应字重的系统字体，不使用强制解包。主题可通过 `XDThemeMetrics.fontFamily` 替换整套字体族。

### XDFontStyle

`XDFontStyle` 是可被主题覆盖的完整排版规格：

- `pointSize`：基础字号。
- `weight`：语义字重。
- `textStyle`：Dynamic Type 的缩放参考。
- `fontName`：单个 Style 的可选字体覆盖；不可用时回退到主题字体族。
- `lineHeight` / `letterSpacing`：Attributed Text 排版规格。
- `maximumPointSize`：Dynamic Type 的可选最大字号。
- `scaling`：`.dynamic` 或 `.fixed`。

`.dynamic` 是语义 Token 的默认值。`.fixed` 不参与 Dynamic Type，因此不允许同时声明 `maximumPointSize`。

### XDFontToken

Token 表达“这段文字是什么”，不表达“它现在是几号字”。内置 Token 为：

```text
title1 / title2 / title3
bodyLarge / body / bodyMedium
caption / captionMedium
```

稳定的业务规格使用自定义 Token，并在 Theme Metrics 中集中声明：

```swift
extension XDFontToken {
    static let navigationTitle = XDFontToken(rawValue: "application.navigation.title")
}

let metrics = XDThemeMetrics.default.merging(fonts: [
    .navigationTitle: XDFontStyle(
        pointSize: 18,
        weight: .semibold,
        textStyle: .headline,
        lineHeight: 26
    )
])
```

自定义 Token 可以通过 `fontStyleIfDefined(for:)` 检查是否已配置。未定义 Token 在安全解析时回退到 `.body`，不再递归查找。

## 使用规则

### 1. 组件和稳定业务界面：使用语义 Token

```swift
label.font = resolver.font(.body)
label.attributedText = NSAttributedString(
    string: text,
    attributes: resolver.textAttributes(font: .body, color: .textPrimary)
)
```

这是默认方式。调整 `.body` 的字号、行高或字体族时，所有消费者同步生效。

### 2. 迁移和少量一次性 UI：显式使用 fixed

```swift
label.font = XDFont.fixed.regular(16)
label.font = XDFont.fixed.medium(18)
label.font = XDFont.fixed.semibold(20)
```

`XDFont.fixed` 保留主项目 `_Fonts` 的便捷性，但名称明确提示它不随 Dynamic Type 缩放。它适用于：

- 渐进迁移旧代码。
- 未稳定、尚不值得提取语义 Token 的一次性 UI。
- 规范明确要求固定字号的特殊视觉。

如果同一固定字号出现在多个稳定界面，应提升为语义 Token，不继续复制数字。

### 3. 不建立 Regular10–30 这类 Token 表

“字重 + 数字”仍然是视觉值，不是语义。为所有组合建 Token 会扩大 API、增加选择成本，且无法解决统一调整问题。

## 主题和组件边界

- 字体族属于 Theme Metrics，不是全局单例常量。
- 组件只通过自身 `XDThemeResolver` 解析 Token，保证多 Scene 主题隔离。
- `XDFont.fixed.regular(16)` 无 theme 参数的快捷方法读取全局 Theme，只适合明确使用全局 Theme 的应用层。
- 组件内如确需固定字号，应使用它自身 Context 的 Theme，但首选仍是组件 Metric 中的字体 Token。
- 主题校验会拒绝空字体名、非法字号、非法行高、非法字间距，以及 `.fixed + maximumPointSize` 冲突。

## 迁移建议

主项目原有：

```swift
Fonts.regular(16)
Fonts.medium(18)
Fonts.semibold(20)
```

可先机械替换为：

```swift
XDFont.fixed.regular(16)
XDFont.fixed.medium(18)
XDFont.fixed.semibold(20)
```

再按页面识别稳定语义，逐步替换为 `.body`、`.title2` 或业务自定义 Token。这样可以先去掉强制解包和分散的字体文件名，再逐步治理魔法字号，不要求一次性重写。

## 与 XDLabel 的边界

字体架构只负责规格和解析，不承担 Label 行为。下一阶段 `XDLabel` 负责：

- 消费语义字体和颜色 Token。
- 应用行高、字间距和 Attributed Text。
- 在 Trait 或 Theme 变化时更新排版。
- 验证 Dynamic Type、长文本、截断、RTL 和无障碍。

## 版本记录

### 0.4.0

#### 新增

- 新增 `XDFontFamily`，默认映射 PingFang SC 的 Regular、Medium 和 Semibold，字体不可用时安全回退到系统字体。
- 新增 `XDFontScaling.fixed/dynamic`，使缩放策略成为显式规格。
- 新增 `XDFont.fixed.regular/medium/semibold(_:)` 迁移逃生口。
- 新增字体族、固定字号、Dynamic Type、自定义 Token、安全回退和非法配置测试。
- Demo 新增 PingFang SC 三种字重的固定字号样例。

#### 修改

- `XDFontStyle` 新增缩放策略，旧初始化调用默认保持 Dynamic Type 行为。
- `XDThemeMetrics` 集中持有字体族，Resolver 不再直接假设系统字体。

#### 修复

- 修复未知自定义字体 Token 递归回退的潜在风险，改为有界的 `.body` 回退。
