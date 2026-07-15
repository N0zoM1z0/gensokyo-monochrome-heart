# UI 组件与四皮肤

## 1. 共享组件原则

UI 只观察 `PresentationState`，不直接改剧情 flag。组件尺寸、焦点矩形与命令信号跨 profile 一致；皮肤只能改变填充、边框、角标、网点、立绘裁剪和动画。

```gdscript
signal command_requested(command: UICommand)
func present(state: PresentationState) -> void
```

每个页面必须能通过 fixture state 独立测试，无需加载世界场景。

## 2. 尺寸 token

| Token | 值 | 用途 |
|---|---:|---|
| `safe_frame` | 4 px | 所有屏幕内容离边缘的最小距离 |
| `ui_grid` | 4 px | 面板与组件对齐 |
| `panel_padding` | 8 px | 标准正文内边距 |
| `panel_border` | 1／2 px | B／C 可 1 px；A／D 关键框 2 px |
| `small_target` | 12 px | 320×180 下最小可聚焦区域，输入碰撞可扩大 |
| `stamp_small` | 9×9 | HUD 小图标 |
| `stamp_large` | 13×13 | Journal、选择和重要反馈 |
| `choice_row` | 12 px | 最小选择行高 |
| `context_prompt` | 12 px | 探索底部提示 |

## 3. 核心组件

### PaperPanel

所有 modal 与对话的基础。状态：normal、focused、disabled、inverted、urgent。A 使用厚 2 px 框；B 使用双框／角标；C 使用折角与不规则一侧；D 使用白色 2 px 框。

### CharacterTag

显示名字、说话方向和可选情绪纹理；绝不显示数值好感。日文名字宽度可扩至 72 px。标签不得浮在无边界背景上。

### ToneChoice

四类稳定意图：Direct、Playful、Patient、Defiant。每个选项显示实际行动，不只显示抽象道德词。不可用选择必须给出剧情内理由。

### StampIcon

9×9 或 13×13。铃、钟、相机、月、花瓣、面具、药瓶等只能靠形状读懂。小图标不使用网点。

### TimeWeatherChip

高 12 px，默认左上；内容是地点／时间／天气的短组合。战斗时可隐藏，避免挤压 HUD。

### ObjectiveThread

高 12 px，默认右上；显示当前因果线，不显示完整任务列表。线可有结、断点与印章，但动画不应延迟输入。

### ContextPrompt

探索时靠底部，只有存在动作时出现。结构：按键图标＋动词＋对象，例：`Z OBSERVE CUP`。D 模式靠战斗底栏，不进入弹幕主区。

### ResonanceTell

用物体变化表达关系：杯子靠近、钟针恢复、照片显影、花瓣落下。显示 0.6–1.2 秒，Journal 记录观察，不弹出 `Trust +1`。

## 4. 探索布局

### A

- 左上：地点／时间；
- 右上：一行 thread；
- 底部：仅在需要时出现 context prompt；
- 对话进入全宽底部 PaperPanel；
- 黑色覆盖率保持 25–35%。

### B

- 顶部可拆成 2–3 个小窗口；
- 对话底框允许双边框、角色小立绘和调查信息；
- 网点只在背景，不铺到正文后；
- 复杂信息用横向分区，不用极小字体。

### C

- 一侧大纸条承载立绘／正文；
- 另一侧 2–4 张折角 choice slip；
- 立绘可越框 8 px；
- 仍保留 12 px 选择行与相同命令顺序；
- 无选择时恢复大留白，不强行填满。

### D

- 顶部 17–20 px HUD；
- 底部 17–20 px 指令栏；
- 对话插话使用侧栏，不覆盖主弹幕 lane；
- 黑底白字；重要选择可临时打开白纸条；
- 所有图标远离 hitbox 区域。

## 5. 对话布局

320×180 下：

- 立绘舞台 80–88 px；
- 正文面板宽 216–304 px；
- 英文 3 行或日文最多 4 行；
- speaker name 是连接在面板上的 tab；
- 双人重叠时一名立绘退为轮廓／网点，不以半透明灰色处理；
- 环境叙述可无立绘，保留 cue line；
- backlog 保存最近 200 条已确认文本和非语言 cue。

## 6. 弹幕布局

- 主活动区约 200×152 或按宽屏变体重新划定；
- life、bomb、Margin 和 phase pip 贴边；
- 符卡标题只在 phase 开始时出现，迅速收起；
- banter 进入侧栏或暂停点，不覆盖活动弹道；
- safe-lane assist 使用边线／缺口，不用灰色光带；
- D 的 50% 网点不得进入活动区。

## 7. 格斗布局

- 双方生命条镜像；
- Temperament 位于生命条下；
- 剧情模式回合计时可隐藏；
- 训练提示只在训练模式；
- L 模型不因帽子、丝带、翅膀自动扩大 hurtbox；
- 1 帧反相可表示命中，但必须有 no-flash 替代。

## 8. 焦点与输入

- Confirm 前进；Cancel 返回；
- 打开页面的同一次按键不能确认不可逆选择；
- 所有 modal 记忆上次焦点；
- 选择焦点使用 3 px 视觉重量；
- 闪烁不是唯一反馈；
- profile 切换不得重置当前焦点或选项序号；
- 控制器／键盘完整可用，鼠标可选。

## 9. 当前文件

- `assets/ui/ui_components_4skins_raw.png`
- `assets/ui/ui_tokens.json`
- `preview/ui_components_4skins.png`
- `preview/demo_A.png` 至 `preview/demo_D.png`

