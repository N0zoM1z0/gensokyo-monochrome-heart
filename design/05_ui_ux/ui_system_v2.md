# 完整 UI 系统 v2：Codex 实现总规

## 1. 设计结论

游戏只有一套逻辑 UI 骨架，四种 `PresentationProfile` 负责表现，不复制剧情、输入、焦点或存档：

| Profile | 名称 | 核心用途 | 黑色面积 | 结构 |
|---|---|---|---:|---|
| A | Pocket Shrine | 默认、探索、系统页 | 25–35% | 2 px 开角纸框、大留白 |
| B | PC-98 Dither | 密集室内、调查、Journal | 40–50% | 1 px 双框、角块、固定网点 |
| C | Woodblock Adventure | 章节、记忆、关系阈值、结局 | 按构图 | 纸条、印章、折角、最多 8 px 破框 |
| D | Midnight LCD | 夜、地下、梦境、弹幕 | 70–85% | 黑底白线、无弹幕后网点 |

强制 A 是功能 fallback：每个页面、事件和玩法都必须在强制 A 下完整可用。profile 不属于 GameState 的剧情变量，不得影响选项、route、判定或存档 schema。

## 2. 固定技术规格

- 内部 canvas 320×180；只允许 2×／3×／4×／5×／6×整数放大；
- nearest-neighbor；禁止运行时平滑、mipmap、fractional Control scale；
- 可见颜色只允许 `#000000` 与 `#ffffff`；
- 4 px UI grid、2 px micro grid、16×16 世界 tile；
- 英文 Kiri8：6×8 cell；日文 DotGothic16 subset：8×8 cell；
- 正文 8 px，章节标题 16 px；
- 字体不做抗锯齿，不用缩小字号挽救溢出；
- 网点只有固定 4×4 Bayer 的 25／50／75%，不得动画抖动；
- 文字、选择、bullet field、focus reticle 后面禁止网点。

精确值以 `ui_tokens_v2.json` 为准。

## 3. 页面覆盖

`screen_inventory.json` 已覆盖 40 页：

- System 11：Boot、语言、内容提示、Title、profile、新游戏、存读档、Options、Accessibility、Pause、Credits；
- Narrative 11：章节卡、世界地图、目的地、旅行确认、探索 HUD、spot 卡、对话、选择、backlog、路线阈值、结局卡；
- Journal 7：摘要、人物、地点、传闻、memory thread、keepsakes、人物 profile；
- Combat 6：弹幕 HUD、符卡开场、弹幕结果、格斗 HUD、格斗结果、训练暂停；
- Activity 5：小游戏壳、相机、交易、诊疗、活动结果。

每页都已经写明：scene path、默认 profile、精确构图、组件、状态、输入、本地化容量、依赖资产和阻断验收。实现时不得只凭 PNG 猜交互。

## 4. 组件原则

30 个组件由 `component_catalog.json` 定义。页面只能组合共享组件；需要新增时先更新 catalog，再创建组件，禁止在页面内复制一份“差不多”的框／按钮。

组件收到 `PresentationProfile` 后可以改变：边框、黑白极性、印章、允许网点、立绘裁剪和短动画。它不可以改变：focus order、语义 state、文字、输入 action、hit target、发出的 command 或存档内容。

最关键组件：

- `frame`：四 profile 的 9-slice；
- `dialogue_panel` + `nameplate` + `portrait_window`；
- `choice_card` + `stance_stamp`，不显示数值好感；
- `map_node`／`region_stamp`；
- `thread_node`，用形状和线型表示 observed／contradicted／changed／resolved；
- `meter`／`pip_row`／`reticle`／`spell_banner`；
- `save_slot`，包含 64×32 地区缩略图；
- `relation_seal`，显示 quiet／open／strained／threshold／complete 等定性状态。

## 5. 输入与 focus

所有设备先映射到 semantic action。页面发出 `ui_confirm(action_id,payload)`、`ui_cancel`、`ui_navigate`、`ui_adjust`、`ui_help` 或 `ui_pause_requested`；raw key/button 不逃出 UI 层。

- focus 必须有 2 px 框 + `>`／角缺口，不能只靠反相；
- modal 打开时保存 prior focus ID，关闭后恢复；
- toast 不拿 focus；world prompt 只有 confirm 后进入交互；
- 打开页面的同一次 held input 不能确认不可逆操作；
- controller、keyboard 与 remap 必须覆盖全部流程；pointer 可选；
- disabled 必须有文字原因／notch，不用灰色低对比度。

## 6. 日英布局

对话标准区域 312×64：英文最多 3×48 cell，日文最多 4×22 glyph。名字独立于 portrait，日文 9 glyph、英文 18 cell 内直接适配；超出时扩 nameplate 或使用经批准短名，不缩字体。

每个 screen row 已给 EN／JA budget。QA 同时跑：

1. 正常英语；
2. 英文 +35% pseudo-localization；
3. 代表性全角日文；
4. 双语实时切换，不重载 scene；
5. backlog 保存当时显示的精确 localized string key + resolved text。

## 7. Godot 结构

建议 autoload：`UiThemeRegistry`、`InputGlyphService`、`FocusRouter`、`LocalizationMeasure`、`AccessibilityState`、`ToastQueue`。它们的职责必须窄，不能决定剧情。

```text
Main
├─ WorldViewport 320x180
├─ ModeHost
├─ PersistentUI
│  ├─ RootScreenHost
│  ├─ ModalHost
│  ├─ ToastHost
│  └─ InputHintHost
└─ TransitionRoot
```

根页面只消费 read-only view model，并发 semantic command 给 Application／GameKernel。具体 path 见 `godot_scene_map.json`。所有页面都要能用 fixture 单独启动和截图，不加载完整世界。

## 8. 动画

- focus visual move 4 帧，但逻辑 focus 立即改变；
- panel open/profile switch 最多 6 帧；
- page turn 8 帧；
- confirm/cancel feedback 3 帧；
- reduced motion 把 wipe、shake、fold、shutter 替换成 3 帧 border tick；
- 禁止全屏黑白连续闪烁；命中反相最多局部 32×32、1 帧；
- saving mark 必须持续到 fs flush 完成，不能以固定 timer 假装完成。

## 9. 战斗 UI

弹幕默认 D：224×152 主活动区 + 88 px status rail。bullet／hazard 中心必须 100% 对比，focus 模式隐藏装饰与 reflection。符卡 banner 收起后不遮 playfield；结果页明确 capture／fail 原因和继续政策。

格斗默认 A，可按舞台切 D：双方 semantic 镜像、timer 中央、生命变化有 delayed notch。hurtbox／hitbox 绝不从角色外形推断。pause 恢复前有 3 帧倒计时，低运动模式也保留文字／边框 cue。

## 10. 实现次序

1. token、字体导入、profile theme、1-bit validator；
2. frame/list/action hint/focus/modal；
3. Title → Save/Load → Map → Exploration → Pause；
4. Dialogue → Choice → Backlog → Route threshold；
5. Journal 七页；
6. Danmaku／Fighter 六页；
7. 五个 Activity 页面；
8. EN/JA、强制 A、低运动、safe flash 和 controller 全量 QA。

更细任务在 `ui_implementation_backlog.md`。

## 11. 样例与 source of truth

- `samples/raw_320x180/`：24 张精确 1× 样例；
- `samples/preview_4x/`：审阅版；
- `samples/complete_ui_sample_atlas_2x.png`：总览；
- `06_art/mockups/`：替换旧材料后的 7 张主展示图；
- `06_art/visual_system_v2/`：A/B/C/D 概念、组件 skin、字体、tile 和角色动画实际 demo。

PNG 负责回答“看起来怎样”；JSON/MD 负责回答“状态、输入和尺寸怎样工作”。冲突时，机器可读 token／screen inventory 优先，再修正 PNG fixture。

## 12. Definition of Done

- [ ] 页面使用 catalog component，没有本地复制组件；
- [ ] 每个 declared state 都有 fixture 和 screenshot；
- [ ] focus graph 全遍历，无 trap／不可达 enabled target；
- [ ] EN、EN+35%、JA 均无 crop／overlap；
- [ ] native profile 与强制 A 的 action／outcome 相同；
- [ ] 1×／2×／4× crisp，无非整数位置；
- [ ] reduced-motion／photosensitivity 通过；
- [ ] 所有可见 RGB 为黑或白；
- [ ] UI 不保存剧情／relationship 状态；
- [ ] screenshot 和 JSON fixture 可在 headless CI 重建。
