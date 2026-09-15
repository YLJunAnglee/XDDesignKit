# XDSnackBar 设计

`XDSnackBar` 是依附于明确 `UIWindowScene` 的短暂反馈控件。它显示一个可选图标、单行状态文案和可选尾部标注文案，整个 Surface 共享同一个点击行为。

## 组件边界

- 整个 SnackBar 是一个按钮，不把尾部标注文案暴露为第二个操作。
- 不提供遮罩，不阻断 SnackBar 范围之外的页面交互。
- 同一 Scene 串行展示，避免多个 SnackBar 彼此覆盖。
- 默认自动消失；`duration: nil` 时由点击或 Handle 主动关闭。
- 仅支持单行正文并在空间不足时尾部截断；尾部标注保持完整。
- 使用 Theme 控制颜色、字体、尺寸、圆角、间距和动画。
- 展示入口必须提供已进入 `UIWindowScene` 的 Controller，不查找全局窗口。

## 默认视觉

- 高度至少 48 pt，横向屏幕留白 20 pt，最大宽度 560 pt。
- 内容水平留白 20 pt、垂直留白 12 pt、圆角 8 pt。
- 图标 24 pt，图标与正文间距 4 pt，正文与尾部标注间距 12 pt。
- 背景 `#484D54`，正文和图标为白色，尾部标注为 `#ABB2B6`。
- 正文与尾部标注均为 PingFang SC Regular 13 pt，并支持受限 Dynamic Type。

## 交互与无障碍

- 图标、正文和尾部标注均不单独接收事件；点击任意位置触发统一 `onTap`。
- VoiceOver 将正文和尾部标注合并为一个按钮名称。
- 展示时发送 announcement，不将整个页面标记为模态。
