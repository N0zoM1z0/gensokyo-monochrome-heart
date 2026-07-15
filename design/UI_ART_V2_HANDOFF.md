# UI／建模新版交付索引

这个 v2 包完整保留原设计的剧情、玩法、角色、地区、音频、技术与生产材料；新版工作集中在 `05_ui_ux`、`06_art`，并新增两份 `10_codex` 实现入口。

## 已完成的设计覆盖

| 项目 | 数量 | 入口 |
|---|---:|---|
| UI 页面 | 40 | `05_ui_ux/screen_inventory.md/json/csv` |
| UI 共享组件 | 30 | `05_ui_ux/component_catalog.md/json` |
| 实际 UI 样例 | 24 | `05_ui_ux/samples/complete_ui_sample_atlas_2x.png` |
| 角色 modeling brief | 71 | `06_art/characters/briefs/` |
| 角色灰盒识别 token | 71 | `06_art/characters/silhouette_tokens/` |
| 地区视觉 brief | 19 | `06_art/regions/briefs/` |
| 地区 stamp | 19 | `06_art/regions/stamps/` |
| 核心完整动画样例 | 3 人 × idle/walk/talk | `06_art/visual_system_v2/` |
| 真实基础 tile | 3 地区 | `06_art/visual_system_v2/assets/tiles/` |
| 视觉 profile | A/B/C/D | `06_art/visual_system_v2/assets/concepts/` |

## 给 Codex

先把 `10_codex/CODEX_UI_ART_BOOTSTRAP_PROMPT_V2.md` 原样交给 Codex。总任务按 `UI_ART_IMPLEMENTATION_TASKBOOK_V2.md` 的 VA00 → VA10 分批执行，不应一次性让 agent“做完整游戏”。

## 重要边界

`silhouette_tokens` 是实现／地图灰盒，不是发布级角色精灵；concept 图是审美目标，不进入游戏；raw 1× 是像素实现基准，2×／4× 只供查看。
