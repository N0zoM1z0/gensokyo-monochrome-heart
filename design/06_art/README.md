# 1-Bit Art Package v2

这是新版 UI／建模与场景视觉的权威入口。原剧情、玩法、角色人格和技术架构没有在这里重写。

## 总规

- `one_bit_art_bible.md` — 黑白、网点、线、可读性；
- `character_asset_contract_v2.md` — 三种模型、层级、sheet、portrait、child/FX、fighter 与验收；
- `region_asset_contract_v2.md` — 19 区 tile、四层景深、五世界状态、spot 与验收；
- `asset_naming_matrix.md` — 命名与导出；
- `vfx_guide.md` — bullet、spell、memory FX。

## 71 名角色

- `characters/character_model_catalog.md|json|csv` — 总矩阵；
- `characters/briefs/` — 71 份个人 modeling brief；
- `characters/production_queue.md` — 先 Reimu／Marisa／Sakuya，再 Tier A/B/C；
- `characters/silhouette_tokens/` — 16×24 灰盒识别 token，不是最终 sprite；
- `characters/silhouette_token_board_2x.png` — 71 人总览。

## 19 个地区

- `regions/location_visual_catalog.md|json|csv` — 总矩阵；
- `regions/briefs/` — 19 份地区生产 brief；
- `regions/production_queue.md` — stamp → 地标 → signature tiles → 四层 → 五状态；
- `regions/stamps/` — 19 个 12×12 stamp；
- `regions/region_stamp_board_2x.png` — stamp 总览。

## 可运行／可重建 Demo

`visual_system_v2/` 包含四张概念方向、准确黑白资产、神社／红魔馆／永远亭 tile、像素字体、四 profile UI skin、Reimu／Marisa／Sakuya 的 S/M/L 与 idle／walk／talk sheet/GIF、交互 HTML 和完整 source／validator。

`mockups/` 的 7 张旧线框展示已替换成新版 1-bit 4× 图；更多 24 张 UI 样例在 `05_ui_ux/samples/`。

## 再生成

```bash
node 06_art/tools/build_full_visual_catalog.js
node 06_art/tools/build_location_visual_catalog.js
node 05_ui_ux/tools/build_ui_catalog.js
node 06_art/tools/generate_complete_ui_samples.js
node 06_art/tools/generate_visual_tokens.js
node 06_art/visual_system_v2/source/validate_assets.js
```

概念图不进入游戏 import；raw 1× 是实现基准，4×／2× 只供评审。
