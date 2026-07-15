# UI／美术实现总任务书 v2

本任务书只实现新版 UI、角色建模导入、地区视觉与相关工具，不重写现有剧情、玩法规则、关系数值、事件结果、角色人格或音乐设计。Codex 每次只领取一个 batch；完成验收再继续。

## 0. 权威输入

| 领域 | Source of truth |
|---|---|
| Canvas／palette／字体／profile | `05_ui_ux/ui_tokens_v2.json` |
| 30 个 UI 组件 | `05_ui_ux/component_catalog.json` |
| 40 个 UI 页面 | `05_ui_ux/screen_inventory.json` |
| Godot 路径 | `05_ui_ux/godot_scene_map.json` |
| 页面验收 | `05_ui_ux/ui_acceptance_matrix.md` |
| 71 人设计 | `06_art/characters/character_model_catalog.json` + `briefs/` |
| 角色技术合同 | `06_art/character_asset_contract_v2.md` |
| 19 区设计 | `06_art/regions/location_visual_catalog.json` + `briefs/` |
| 地区技术合同 | `06_art/region_asset_contract_v2.md` |
| 真实基准资产 | `06_art/visual_system_v2/` |
| UI screenshot fixtures | `05_ui_ux/samples/raw_320x180/` |

若 PNG 与 JSON 在尺寸／状态上冲突，以 JSON 为准并同时修复 screenshot fixture。若 v2 与旧 `ascii_wireframes.md` 冲突，以 v2 为准。

## 1. 全局不可破坏项

- 不改 `00_project`、`01_game_design`、`02_narrative`、`03_locations`、`04_characters` 的现有内容，除非用户另行授权；
- UI 不拥有 GameState，不把关系数值直接显示给玩家；
- 不下载／提取／描摹官方或同人 sprite、音乐、字体、贴图；
- 不把 concept image 导入 release；
- 不把 4× preview 当 source；
- 不用 shader 灰色、alpha 灰、抗锯齿或随机噪点冒充 1-bit；
- 不为四 profile 复制四份剧情页面；
- 不以 sprite bounds 生成 collision／hurtbox；
- 不让 Story 路线因小游戏、弹幕或格斗失败永久卡住。

## 2. 每个 batch 的工作协议

开始前：

1. 读取本 batch 指定输入；
2. 检查现有 repo 与 dirty worktree；
3. 列出将新增／修改文件；
4. 先建 fixture 与失败的 validator／test；
5. 不重构无关系统。

完成时报告：

- 实际修改；
- 自动测试／headless import／screenshot 结果；
- 未运行项目及原因；
- 1×、EN/JA、强制 A、low motion 的人工检查；
- 未解决 blocker，不用“以后再优化”代替验收。

---

# VA00 — 美术与 UI 基础导入

## 目标

建立 320×180、严格 1-bit、可重复导入与截图的基础，尚不接剧情。

## 读取

- `05_ui_ux/ui_tokens_v2.json`
- `06_art/one_bit_art_bible.md`
- `06_art/visual_system_v2/docs/05_production_pipeline.md`
- `08_technical/godot_architecture.md`

## 任务

1. 设置 320×180 Viewport、整数 scale controller 与 letterbox；
2. 关闭 texture/font filtering、mipmap 与 transform interpolation；
3. 实现 `PresentationProfile` Resource A/B/C/D 和 fallback A；
4. 实现 1-bit PNG validator：visible RGB 只允许 0/255，alpha 只允许 0/255；
5. 实现 non-integer Control／Sprite position validator；
6. 导入 Kiri8 Latin 与 DotGothic16 EN/JA font；
7. 建立 screenshot fixture runner：可单独启动 scene，以 1× 输出 PNG；
8. 建立 raw/preview 分离规则，preview 不进入 release import；
9. 添加 profile 强制 A、reduced motion、safe flash 的 SettingsService 接口。

## 输出

```text
res://ui/theme/
res://ui/fonts/
res://src/presentation/profile/
res://src/tools/validate_one_bit.gd
res://src/tools/validate_pixel_alignment.gd
res://tests/ui/screenshot_runner.gd
```

## 验收

- 2×／3×／4× crisp，任意窗口 letterbox；
- 故意加入 `#808080` 像素时 validator 失败并报文件／坐标；
- 故意放置 x=10.5 Control 时 validator 失败；
- EN/JA specimen 不抗锯齿；
- profile 切换不改变 fixture 的 command/action 集。

---

# VA01 — 30 个共享 UI 组件

## 目标

实现 catalog 的共享组件和四 skin，不制作完整页面。

## 读取

- `05_ui_ux/component_catalog.json`
- `05_ui_ux/ui_system_v2.md`
- `06_art/visual_system_v2/assets/ui/`

## 任务

1. 实现 `UiThemeRegistry`、`FocusRouter`、`InputGlyphService`；
2. 按 `godot_scene_map.json` 创建 30 个 component scene；
3. 为每个组件实现全部 declared state fixture；
4. 完成 A/B/C/D frame skin，统一 content margins；
5. 实现 keyboard/controller/pointer focus visual；
6. 实现 modal prior-focus restore；
7. 实现 EN/JA measure 与 overflow diagnostic；
8. 输出组件 contact sheet，与 `ui_components_4skins_raw.png` 并排审阅。

## 验收

- 30/30 scene path 存在；
- 组件所有 enabled target 可从键盘与手柄访问；
- disabled／urgent／changed 不只靠极性；
- forced A 不改变状态、文字、focus order、target 或 signal；
- component screenshot 在 1× 通过 palette 和 alignment validator。

---

# VA02 — 核心三人角色导入

## 目标

把 Reimu、Marisa、Sakuya 的真实 sheet 导入游戏，证明共享动画与个人动作差异。

## 读取

- `06_art/character_asset_contract_v2.md`
- 三人的 `06_art/characters/briefs/*.md`
- `06_art/visual_system_v2/assets/sprites/animation_manifest.json`

## 任务

1. 导入三人的 S/M/L 基准与 M 16-frame sheet；
2. 建立 `CharacterVisualDefinition` typed Resource；
3. 导入 feet/focus/hand/head anchors；
4. 实现 idle/walk/talk 状态机和动作结束回 idle；
5. D profile 使用 inverted sheet／palette swap，alpha 不反相；
6. 建白底、黑底、1×、脚点、talk UI overlap fixture；
7. 不使用 token board 替代核心三人 sheet；
8. 把 GIF 时序与 Godot SpriteFrames 时序核对。

## 验收

- 三人 silhouette 在去掉脸部后仍可区分；
- 4 idle／8 walk／4 talk 顺序与 manifest 一致；
- 循环首尾 anchor 无漂移，walk 无滑脚；
- Reimu 的 sleeve/bow lag、Marisa 的 hat/broom lag、Sakuya 的 precise settle 可见；
- 白底／D 黑底均无黑团或透明边。

---

# VA03 — 三地区视觉基础

## 目标

先用神社、红魔馆、永远亭证明留白、密集室内和反相走廊三种场景问题。

## 读取

- 三份 `06_art/regions/briefs/*.md`
- `06_art/region_asset_contract_v2.md`
- `06_art/visual_system_v2/assets/tiles/`

## 任务

1. 导入三套 128×64 tile atlas；
2. 创建 metadata 与 collision fixture，不从像素推断碰撞；
3. 每区拼一张 320×180 exploration room；
4. 分 FAR/MID/PLAY/FRONT；
5. 实现 calm/incident 两状态，预留其余三 overlay；
6. 接 12×12 region stamp；
7. 放入核心 M sprite 与 ContextPrompt；
8. 测 dialogue-safe、combat focus、reduced motion。

## 验收

- 神社不是空白线框：大留白与实黑屋檐有层次；
- 红魔馆地面／书架网点不会穿过正文或弹幕；
- 永远亭黑底竹林中角色、出口和 bullet cue 保持 100% 对比；
- 关闭 FRONT 仍能完成导航；
- calm/incident 切换不意外改变 collision。

---

# VA04 — 核心系统与叙事页面

## 目标

完成可从 Title 进入世界、探索、对话、选择、backlog、pause 与存档的 UI 主循环。

## 页面

`boot`、`language_select`、`content_notice`、`title`、`new_game_setup`、`save_load`、`world_map`、`destination_detail`、`travel_confirm`、`exploration_hud`、`spot_card`、`dialogue`、`dialogue_choice`、`backlog`、`pause`。

## 任务

1. 严格按 screen inventory scene path 与 states 实现；
2. 用现有 Empty Cup/Cushion sample event 接真实 view model；
3. 不修改事件结果／choice 语义；
4. 保持 speaker、choice、system record 的 backlog 区分；
5. 实现三种 manual save + rolling autosave view；
6. 世界地图接 19 个 region stamp；
7. 输出 EN/JA、native profile、forced A fixture；
8. 用 raw sample 做 perceptual/reference review，不做像素级强制相同测试。

## 验收

- Title → New/Load → Map → Exploration → Dialogue/Choice → Backlog → Pause → Save 流程全手柄完成；
- 打开页面的 held confirm 不会连点不可逆 action；
- 对话 EN 3 行／JA 4 行无 orphan/crop；
- 选择只显示定性 intent 和剧情行为，不显示 affinity 数字；
- save flush 前不能退出，corrupt slot 不静默删除。

---

# VA05 — Journal、关系与系统页面

## 页面

`profile_select`、`options`、`accessibility`、`chapter_card`、`route_threshold`、`ending_card`、`journal_summary`、`journal_people`、`journal_places`、`journal_rumors`、`memory_thread`、`keepsakes`、`character_profile`、`credits`。

## 任务

1. Journal 从 discovered IDs 生成，只读，不在打开时改 flags；
2. memory thread 同时有 graph 和 linear list fallback；
3. relation seal 使用定性语义，不显示 raw facet；
4. route threshold 文案说明事件事实，不暗示隐藏分数；
5. 人物日志接 71 人 portrait placeholder/blockout，但标记未完成美术；
6. 地点页接 19 region stamp 与 state overlay；
7. Accessibility 每项有 live preview；
8. Credits 可暂停、加速、跳过确认，并能从 Title 重看。

## 验收

- 7 个 Journal 页面 focus graph 可全遍历；
- unknown slot 不泄露 secret 总数；
- rumor 状态用文字+形状；
- graph 所有节点在线性 fallback 可访问；
- forced A、low motion、EN/JA 均通过。

---

# VA06 — 弹幕与格斗 UI

## 页面

`danmaku_hud`、`spell_card_intro`、`danmaku_result`、`fighter_hud`、`fighter_result`、`training_pause`。

## 任务

1. 弹幕使用 224×152 playfield + 88 px rail fixture；
2. focus 显示 2–3 px hitbox，并抑制 decoration；
3. spell banner 第一次与重复时长不同；
4. safe flash 替换 shutter／命中全屏反相；
5. fighter 双方 semantic mirror，生命 loss notch 延迟显示；
6. training 列出全动作、input history、dummy/reset；
7. 三核心角色接 fighter key-pose placeholder，但 hitbox 数据独立；
8. 生成 2,500 bullet stress HUD fixture 与 64 projectiles/fighter fixture。

## 验收

- bullet/hazard 与背景在 focus／normal 都可分；
- décor、dither、reflection 不与 bullet shape 同频；
- Pause 恢复 3 帧倒计时；
- result 用文字说明 capture/fail/story continuation；
- safe flash 与 reduced motion 下仍有命中／spell cue。

---

# VA07 — 五个 Activity 页面

## 页面

`minigame_shell`、`photo_camera`、`trade_shop`、`clinic`、`activity_result`。

## 任务

1. 19 区小游戏统一进入 ActivityShellBase；
2. intro 明示 objective、control、assist、退出政策；
3. Camera safe shutter 用 border close；
4. Trade 显示 price/currency 与不可用原因；
5. Clinic 使用游戏世界虚构诊疗，不输出现实医疗建议；
6. partial success 成为明确 ModeResult；
7. Story assist／Resolve 确保路线可继续。

## 验收

- 任何 activity retry 不超过 2 actions；
- 失败不永久卡剧情；
- result 不显示隐藏 relationship 数字；
- 五页面 EN/JA、手柄、forced A、low motion 通过。

---

# VA08 — 19 区完整场景扩展

## 目标

按 `regions/production_queue.md` 扩完 19 区的视觉生产，不改各区原剧情／玩法文本。

## 每区循环

1. 审核 12×12 stamp；
2. 做 80×45 landmark silhouette；
3. 做个人 brief 的 8 signature tiles；
4. 做四层 320×180 proof room；
5. 做 CALM/INCIDENT/ROUTE/SEASON/AFTER；
6. 覆盖原 location bible 的所有 spots；
7. 接地区 minigame shell 与适用的 combat proof；
8. EN/JA 标牌、forced A、reduced motion、focus；
9. 完成 budget；
10. 逐区验收后再开下一区。

## 总预算参考

- 992 个 16×16 base tiles；
- 282 个 32×32 macro tiles；
- 183 个 animated props；
- 122 条 320×180 background strips；
- 88 个 foreground masks；
- 46 组 landmark；
- 95 个 state overlays。

这些是最大生产计划，不要求在代码 vertical slice 阶段一次性手画完成；Codex 应先搭数据、导入、fixture 和 placeholder gate，再按批准的美术批次替换。

---

# VA09 — 71 人扩展

## 目标

在核心三人通过后，按 `characters/production_queue.md` 扩展全 roster。

## 阶段

1. Tier A：12 人，完整路线／首发 fighter 或 danmaku set；
2. Tier B：22 人，地区主要／fighter expansion；
3. Tier C：37 人，支援／客串；
4. 每人先 silhouette approval，再 M/S/portrait；
5. 不允许 71 人同时进入“进行中”。每批最多 3 人，且必须跨同场角色做 silhouette collision review。

## 单人验收

- 个人 brief 全勾选；
- 1×／白底／黑底／强制 A；
- child/FX anchor；
- idle/talk 体现个人动作习惯；
- JA/EN 名牌和 dialogue overlap；
- 原创几何与出处记录；
- fixture、metadata、import、截图均进入 CI。

---

# VA10 — 最终整合门

1. 40/40 screen、30/30 component、71/71 character definition、19/19 region definition 可加载；
2. release 中没有 concept、preview、blockout token 或 `ph_` 占位；
3. 所有 raw texture 通过 palette／alpha／alignment；
4. 全 focus graph、EN+35%、JA、forced A、low motion、safe flash、controller 通过；
5. 1× 人工可读性审阅；
6. danmaku/fighter stress 性能门通过；
7. save/load/profile switch 不改变剧情 state；
8. 所有新资产 license/source ledger 完整；
9. clean clone headless import、validator、tests、fixture screenshots 全绿；
10. 没有对原剧情／玩法的未授权改动。
