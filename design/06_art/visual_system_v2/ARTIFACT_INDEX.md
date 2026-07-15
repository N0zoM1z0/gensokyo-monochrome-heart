# Artifact Index

## 可直接看的 Demo

| 文件 | 内容 |
|---|---|
| `demo/index.html` | 可交互 320×180 demo：皮肤、地点、角色、动画、语言与锚点切换 |
| `preview/demo_A.png` | A 默认探索／对话画面 |
| `preview/demo_B.png` | B 高密度红魔馆画面 |
| `preview/demo_C.png` | C 木版剧情选择画面 |
| `preview/demo_D.png` | D 反相夜战画面 |
| `preview/trio_idle.gif` | Reimu／Marisa／Sakuya 的 4 帧 idle 对照 |
| `preview/trio_walk.gif` | 三人的 8 帧 walk 对照 |
| `preview/trio_talk.gif` | 三人的 4 帧 talk 对照 |

## 角色建模与动画

| 文件 | 内容 |
|---|---|
| `preview/character_model_lock.png` | 三名角色的 S／M／L 比例与关键动作 |
| `preview/animation_overview.png` | 4 idle＋8 walk＋4 talk 的完整帧横表 |
| `assets/sprites/*_m_sheet.png` | Model M 原始 24×32 精灵表，16 帧横排 |
| `assets/sprites/*_m_sheet_inverted.png` | D 模式反相精灵表 |
| `assets/sprites/*_sml.png` | 单角色 S／M／L 比例表 |
| `assets/sprites/animation_manifest.json` | 帧顺序、时长、锚点与用途 |
| `preview/{角色}_{动作}.gif` | 每名角色每个动作的独立动画预览，共 9 个 |

## Tile 与场景

| 文件 | 内容 |
|---|---|
| `preview/tile_atlas_overview.png` | 博丽神社／红魔馆／永远亭三套基础 tile 总览 |
| `assets/tiles/shrine_tiles_16.png` | 神社 8×4 atlas，单 tile 16×16 |
| `assets/tiles/mansion_tiles_16.png` | 红魔馆 8×4 atlas |
| `assets/tiles/eientei_tiles_16.png` | 永远亭 8×4 atlas |
| `assets/tiles/tiles_manifest.json` | atlas 行语义与交互形状语言 |
| `preview/background_*.png` | 三处地点的 320×180 组合测试场景 |

## UI 与字体

| 文件 | 内容 |
|---|---|
| `preview/ui_components_4skins.png` | 同一 UI 组件骨架的 A／B／C／D 四皮肤对照 |
| `assets/ui/ui_components_4skins_raw.png` | 原始像素尺寸组件表 |
| `assets/ui/ui_tokens.json` | 尺寸 token、组件最小值和各皮肤规则 |
| `preview/font_specimen.png` | 日英文字体与反相样张 |
| `assets/fonts/kiri8_latin_raw.png` | Kiri-8 拉丁原型字形表 |
| `assets/fonts/DotGothic16-*.woff2` | 日英网页 demo 字体 |

## 四张美术方向图

| 文件 | 内容 |
|---|---|
| `assets/concepts/A_pocket_shrine.png` | Pocket Shrine 概念图 |
| `assets/concepts/B_pc98_dither.png` | PC-98 Dither 概念图 |
| `assets/concepts/C_woodblock_adventure.png` | Woodblock Adventure 概念图 |
| `assets/concepts/D_midnight_lcd.png` | Midnight LCD 概念图 |

## 设计与生产文档

- `docs/00_visual_system_v2.md`：总体结构、四模式分工与切换规则；
- `docs/01_character_model_and_animation.md`：比例、锚点、三名角色逐帧说明；
- `docs/02_tiles_and_regions.md`：三组基础 tile 与地图生产规则；
- `docs/03_pixel_font_and_localization.md`：日英字体、排版和二值化；
- `docs/04_ui_components_and_skins.md`：组件尺寸与四皮肤；
- `docs/05_production_pipeline.md`：命名、Godot 导入、QA 与扩展顺序；
- `docs/06_demo_review_checklist.md`：本轮评审时该看什么。

## 生成与验证源码

- `source/pixel_core.js`：像素画布、Bayer 网点和 Kiri-8 字形；
- `source/characters.js`：三名角色的尺寸与动画绘制；
- `source/generate_assets.js`：精灵、tile、UI、预览与 manifest 生成；
- `source/build_gifs.js`：使用附带的 MIT `gifenc` 顺序编码动画 GIF；
- `source/validate_assets.js`：尺寸、调色板和帧表验证；
- `manifest.json`：包内文件清单。
