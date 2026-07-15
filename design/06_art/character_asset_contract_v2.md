# 角色建模完整生产合同 v2

这份文件定义“可以直接开工”的角色资产边界。71 名角色的个别设计不在这里重复；它们位于 `06_art/characters/briefs/<character_id>.md`，可机器读取的总表位于 `06_art/characters/character_model_catalog.json`。

## 1. 完整的含义

本包已经完成：角色比例、锚点、生产层级、每人剪影关键词、独立道具、child/FX 层、idle/talk 习惯、肖像情绪重点、事件服装、profile 适配、命名、预算和验收。Reimu／Marisa／Sakuya 另有真正可播放的 idle／walk／talk sheet 和 GIF。

本包没有把 71 人的数千张发布级最终帧伪装成“已经画完”。`silhouette_tokens/` 是 16×24 识别 blockout，只能用于名单、地图或早期灰盒；最终精灵必须按个人 brief 原创重画。这样 Codex 能立即搭建导入、动画、状态机和批量校验，美术仍有明确而诚实的制作清单。

## 2. 共用模型

| 模型 | 帧画布 | 逻辑用途 | 禁止 |
|---|---:|---|---|
| S | 16×24 | 地图、群众、远景、日志小人、客串 | 把 M 直接缩小 |
| M | 24×32 | 横向探索、小游戏、普通事件 | 让帽子／翅膀改变碰撞框 |
| L | 32×48 | 格斗、符卡起手、戏剧动作 | 把 M 无细节放大 |
| Portrait | 80×104；C 可用 88×120 | 对话、人物日志、路线卡 | 从普通精灵放大或平滑缩放 |

所有模型共享语义动作名与身份，但每个尺寸独立删减／重构像素。只允许整数坐标、nearest、黑白两种可见 RGB；透明只作为合成层。

## 3. Model M 锚点合同

| 锚点 | 默认坐标 | 用途 | 允许例外 |
|---|---:|---|---|
| `feet_anchor` | 12,31 | 排序、地面、脚步、循环 | 浮空角色记录 `hover_offset`，逻辑脚点不漂 |
| `focus_anchor` | 12,22 | 弹幕中心、镜头、锁定 | 身体非人形时逐角色覆盖 |
| `hand_primary` | 19,16 | 主武器／主手道具 | 左利手可镜像 metadata，不镜像文字／不对称服装 |
| `hand_secondary` | 5,16 | 副手、杯、书、手势 | 双持角色独立记录两点 |
| `head_top` | 12,0 | 帽、感叹、命中特效 | 帽檐可越界，节点 origin 不变 |
| `companion_anchor` | 12,18 default | 半灵、玩偶、第三眼、相机等 | 必须在个人 brief 中覆盖 |
| `portrait_eye_line` | 12,10 | 立绘 UI 对齐 | 肖像文件另存精确眼线 |

每个动作首尾必须回到同一逻辑锚点。可见脚像素可移动，Node2D 原点不能随帧跳动。

## 4. 共用 sheet 与动作

Model M 基础 sheet 固定 384×32、16 帧、无间隔：

| 帧 | 动作 | 建议时长 | 内容 |
|---:|---|---:|---|
| 0–3 | `idle` | 160 ms | 中立 → 微动作 → 身体／附件错拍 → settle |
| 4–11 | `walk` | 90 ms | 左右 contact/down/passing/up |
| 12–15 | `talk` | 140 ms | 中立 → 起手 → 强调 → 回稳 |

个人 context 动作存在独立 sheet：`interact_<verb>`、`reaction_<state>`。不要通过在基础 sheet 内复制帧来延长动作，时长写进 SpriteFrames／数据。

## 5. 生产层级

层级控制发布资产量，不表示角色的重要性，也不向玩家显示。

### Tier A — 深路线／首发主战角色

- S：2 idle、4 walk、2 interact；
- M：4 idle、8 walk、4 talk、6 个情境动作、4 个反应；
- Portrait：9 个基础状态，再按路线增加 1–3 个私密状态；
- L：如果在 `fighter_system.md` 的首发名单，完成 5 normals、2 command normals、4 specials、2 spells、guard／dash／jump／hit／down／win／surrender 的动作集；如果不是 fighter，则制作 8–16 个符卡／剧情关键姿势；
- 黑底反相 override：必做；
- 三组事件服装：至少做一组完整 M 替换，其余可以是经审核的 overlay。

### Tier B — 地区主要角色／fighter expansion

- S：2 idle、4 walk；
- M：4 idle、4 walk、4 talk、2 reaction、2 地区情境动作；
- Portrait：6 个；
- L：fighter expansion 为完整 fighter set；其他角色为 4–8 个剧情／boss 姿势；
- 黑底测试必做，只有合并失败时制作 override；
- 事件服装优先一个剪影变化最大的版本。

### Tier C — 支援／客串

- S：2 idle；
- M：2 idle、4 walk、2 talk／个人手势；
- Portrait：3 个（工作中立、正向但非恋爱、压力／事件）；
- L：首发不要求，作为 boss／特殊事件时做 4 个关键剪影；
- 原型阶段可用 blockout token，但进入内容锁前必须原创重画。

## 6. 肖像包

Tier A 的九个基础键：

1. `work_neutral`
2. `social_neutral`
3. `amused`
4. `irritated`
5. `focused`
6. `startled`
7. `tired_private`
8. `sincere_restrained`
9. `route_vulnerable`

不要使用一张通用“害羞脸”覆盖所有角色。眼线、肩线、手势、道具距离、是否直视和个人动作习惯比腮红更重要。profile 不是四套表情：基础 portrait 复用，B 可加细部网点，C 可越框 8 px，D 必须有反相／负形验证。

## 7. child／FX 分层

以下对象不得烘焙进所有身体帧：

- 半灵、上海／蓬莱人偶、第三眼与 cords、九尾、Unzan；
- 扫帚、gohei、怀表、刀扇、相机、书、药箱等会切换的主道具；
- 光球、符卡 glyph、火焰、梦泡、天气、边界／门；
- 为 profile D 单独调整的白色轮廓。

每个 child 层记录：`anchor_id`、`z_policy`、`inherits_facing`、`inversion_mode`、`collision_policy=none|authored`。默认无碰撞，不能从可见边界自动生成 hitbox。

## 8. Fighter 动画合同

fighter 逻辑固定 60 Hz，动画文件只表达画面，不拥有伤害数据。每个 move 的 `.tres`／数据另写：startup、active、recovery、root motion、hurtbox、hitbox、cancel tags、FX cue。帽、丝带、翅膀与巨大武器默认不扩大 hurtbox。

建议先交关键 pose，再补 in-between：

1. silhouette key pose；
2. startup／active／recovery 三段判读；
3. hurtbox/hitbox fixture；
4. 白底与黑底战斗测试；
5. reduced-flash 命中版本；
6. 最后才补 smear、碎片与衣摆。

## 9. 文件与 metadata

```text
art/characters/<id>/
  s/chr_<id>_s_<action>_<frame>.png
  m/chr_<id>_m_<action>_<frame>.png
  l/chr_<id>_l_<action>_<frame>.png
  portrait/portrait_<id>_<state>_<variant>.png
  fx/fx_<id>_<effect>_<frame>.png
  <id>_anchors.json
  <id>_animations.json
```

禁止在基础资产名中加入 profile，除非图像确实专属。D 优先走 palette swap／inversion override；A/B/C 由 UI 与材质组合。

## 10. 核心三人实际样例

`06_art/visual_system_v2/assets/sprites/` 包含：

- `reimu_m_sheet.png`、`marisa_m_sheet.png`、`sakuya_m_sheet.png`；
- 对应 inverted sheet；
- 三人的 S/M/L 比例图；
- `animation_manifest.json` 的锚点与帧顺序。

`06_art/visual_system_v2/preview/` 包含三人的 idle／walk／talk GIF 和总览。它们是模型、帧序和导入测试基准；完整 fighter 动作仍按上面的合同生产。

## 11. 全角色资料的使用顺序

对任何角色开工时，Codex／美术按此顺序读取：

1. `04_characters/<id>/skills.md`：性格、语气、能力与关系；
2. `06_art/characters/briefs/<id>.md`：个人剪影与动作锁；
3. `06_art/character_asset_contract_v2.md`：尺寸、层级、输出与验收；
4. `06_art/characters/silhouette_tokens/<id>_s_token.png`：只做灰盒识别参考；
5. `06_art/visual_system_v2/`：核心质量和技术参考。

## 12. 阻断验收

- [ ] 填黑脸后仍能从剪影区分同场角色；
- [ ] 1×、2×、4×均无平滑、孤立半像素或线宽漂移；
- [ ] 白底、黑底、目标 profile 与强制 A 均通过；
- [ ] visible RGB 只有 0／255，alpha 只有 0／255；
- [ ] idle 首尾锚点一致、walk 不滑脚、talk 可无缝回 idle；
- [ ] 道具／child 层与身体不粘成不可读黑团；
- [ ] JA/EN 名牌与 UI 不压住主要手势；
- [ ] fighter hitbox 来自数据而不是 sprite bounds；
- [ ] 没有临摹／提取官方或同人 sprite 几何；
- [ ] 个人 brief 的动作气质在至少一个 idle 和一个 talk 中明确可见。
