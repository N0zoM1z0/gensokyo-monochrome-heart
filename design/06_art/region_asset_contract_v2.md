# 19 区域完整视觉生产合同 v2

19 个区域的逐区视觉词汇、四层景深、8 个标志 tile、地标、动画、转场、五种世界状态、战斗可读性和资产预算已写入 `06_art/regions/briefs/`；总表为 `location_visual_catalog.json`。本文件规定它们如何被真正做成可复用场景资产。

## 1. 共用画布与层级

- 内部画布：320×180；
- tile：16×16；macro tile：32×32；
- 图层：`FAR`、`MID`、`PLAY`、`FRONT` 四层独立；
- UI-safe：对话时 x=8–311、y=108–171 不放高频运动与角色脸；
- combat-safe：活动区内禁止 1 px 高频 checker、与弹形同频的粒子、不可关闭的前景 wipe；
- 所有视差按整数像素更新；低速视差用积累器计算、提交渲染时取整。

## 2. 每区必交资产

| 资产 | Tier A | Tier B | Tier C |
|---|---:|---:|---:|
| 16×16 base tiles | 64 | 48 | 36 |
| 32×32 macro tiles | 18 | 14 | 10 |
| animated props | 12 | 9 | 6 |
| 320×180 background strips | 8 | 6 | 4 |
| foreground masks | 6 | 4 | 3 |
| landmark sets | 3 | 2 | 2 |
| world-state overlays | 5 | 5 | 5 |
| region stamp | 12×12、16×16、32×32 | 同 | 同 |

五种 state 必须包含 `CALM`、`INCIDENT`、`ROUTE`、`SEASON`、`AFTER`。优先用 overlay 改视觉，不复制碰撞；只有剧情明确改变可走路径时才提供独立 collision map。

## 3. tile atlas 分区

每个 atlas 保持固定语义行：

1. 地形／碰撞边；
2. 建筑与大结构；
3. 可交互物与角色 affordance；
4. 气候、记忆、事件与地区签名。

tile metadata 至少含：`tile_id`、`region_id`、`collision_shape`、`occlusion_band`、`interaction_shape`、`material_sfx`、`profile_safe`、`state_tags`。视觉图块不能偷偷决定剧情或关系结果。

## 4. 地区 stamp

`06_art/regions/stamps/` 已有 19 个 12×12 原创 blockout，`region_stamp_board_2x.png` 是总览。stamp 同时用于地图节点、地区卡、Journal、存档缩略图和小游戏外壳。最终审核规则：

- 12×12 即可区分；
- 不用文字或颜色；
- 不与角色个人 stamp 重形；
- D 反相后内部负形仍保持；
- 16／32 版本必须重画细节，不允许平滑放大。

## 5. spot 的最小完成包

原 `03_locations/*.md` 中每个 spot 至少制作：

- 一张 320×180 establishing plate；
- 一张可走 exploration crop；
- CALM 与 INCIDENT 对照；
- 一个 mundane maintenance detail；
- 一个关系专属 prop socket；
- 一个事件 contradiction；
- 一个 AFTER 安静构图；
- 日英标牌 bounding box；
- dialogue、danmaku、fighter 三种可读性证明中适用的一项。

## 6. 三套真实基础 tile

`06_art/visual_system_v2/assets/tiles/` 已完成神社、红魔馆、永远亭的 16×16 基础 atlas；`preview/tile_atlas_overview.png` 是放大预览。这三套不是 19 区最终全集，而是三种生产问题的基准：

- 神社：用留白建立空间，不靠线框和噪点；
- 红魔馆：高密室内仍保留 UI／弹幕可读性；
- 永远亭：重复走廊、反相夜景和垂直节奏。

其他区域从相应 brief 开始，不应把这三套简单换装。

## 7. 交互形状语言

| 语义 | 图形 |
|---|---|
| Observe | 2×2 sparkle + 轮廓缺口 |
| Carry | 底部双把手 |
| Repair | 三段斜裂纹 |
| Danger | 交替粗边 + 文本提示 |
| Rumor | 折角纸 |
| Memory | 不完整矩形 |
| Companion | 角色独有 stamp + 动词 |

同一形状在 19 区保持语义，不因 profile 或美术方便而改变。

## 8. 动画与性能

- 环境循环只用 4／6／8／12 帧，默认 8 fps；
- 同一 spot 同时最多 3 个粒子／环境循环，其他以状态切换图块表达；
- foreground wipe、shutter、fog、petal 等均可独立关闭；
- 弹幕 focus 时自动隐藏非必要前景与 reflection；
- 远景动画可降低更新频率，交互 cue 必须保持 60 Hz 响应；
- 不允许动态随机网点，Bayer 相位固定在世界或对象局部坐标。

## 9. 逐区开工顺序

1. 按 `production_queue.md` 选择一个 Tier A 地区；
2. 先画 12×12 stamp 与 80×45 地标剪影；
3. 画个人 brief 的 8 个 signature tile；
4. 拼一张可走 320×180 场景；
5. 分拆 FAR/MID/PLAY/FRONT；
6. 做五状态 overlay；
7. 放入真实 M sprite 与 UI；
8. 做 target profile + 强制 A；
9. 做 reduced-motion/focus 模式；
10. 再扩完整 atlas 和该区其他 spot。

## 10. 阻断验收

- [ ] 从 12×12 stamp 和 80×45 地标都能认区；
- [ ] 四层可独立关闭，关闭 FRONT 不丢导航；
- [ ] 每个 authored spot 至少命中一个 signature tile／prop family；
- [ ] 五种 state 不用颜色也可区分；
- [ ] 对话正文、选择、弹幕、fighter hurtbox 无纹理竞争；
- [ ] 所有移动／视差提交到整数坐标；
- [ ] JA/EN 标牌不靠缩放字体解决；
- [ ] reduced-motion 移除 wipe／shake 后仍保留转场信息；
- [ ] collision 与视觉 metadata 分离并有 fixture；
- [ ] 没有使用官方或同人作品提取素材。
