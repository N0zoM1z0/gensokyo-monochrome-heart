# v2 变更与原文保护审计

## 结论

**PASS：除新版 UI／美术范围、两份新增 Codex 任务入口和包级 metadata 外，原包文件逐字节保持不变。**

审计使用 SHA-256 对原始解包目录与 `gensokyo_monochrome_heart_design-2` 对照。以下 191 个原文件类别全部 hash 相同：

- `00_project/**`
- `01_game_design/**`
- `02_narrative/**`
- `03_locations/**`
- `04_characters/**`
- `07_audio/**`
- `08_technical/**`
- `09_data/**`
- 原有 `10_codex/**`（v2 只新增两份文件）
- `11_research/**`
- `12_production/**`
- 原根目录 README／QUICKSTART／DELIVERABLE_INDEX／tools 等非 metadata 文件

## 允许且实际发生的替换

原文件中只有下列 UI／美术文件被替换：

- `05_ui_ux/README.md`
- `06_art/README.md`
- `06_art/mockups/01_world_map.png`
- `06_art/mockups/02_exploration_spot.png`
- `06_art/mockups/03_dialogue_choice.png`
- `06_art/mockups/04_danmaku.png`
- `06_art/mockups/05_fighter.png`
- `06_art/mockups/06_journal.png`
- `06_art/mockups/07_core_sprite_atlas.png`
- `06_art/mockups/manifest.json`

原有 `05_ui_ux`／`06_art` 的其他专项文档也保留；v2 通过新增文件扩充，不删除它们。

## 新增范围

- `05_ui_ux`：token、30 组件、40 页面、导航、验收、24 UI 样例与生成器；
- `06_art`：71 人 briefs/tokens、19 区 briefs/stamps、完整视觉 demo、生产合同与生成器；
- `10_codex`：UI／美术实现总任务书与启动 prompt；
- 根目录：`UI_ART_V2_HANDOFF.md` 与本审计；
- 包级 manifest／validation report 会按 v2 内容重新生成。

## 复核方法

构建时排除 `05_ui_ux/**`、`06_art/**`、两份新增 v2 Codex 文件、新增交付索引与 manifest/validation metadata，然后对双方相对路径的 SHA-256 排序比较，结果为空 diff。原始 ZIP 不会被覆盖；v2 生成独立 ZIP。
