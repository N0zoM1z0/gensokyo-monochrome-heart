# 可直接交给 Codex 的启动 Prompt

```text
你正在实现 Gensokyo Monochrome Heart 的新版 UI／角色建模／地区视觉系统。

先不要写代码。先完成以下只读检查并给出不超过 10 步的 VA00 计划：

1. 阅读 10_codex/UI_ART_IMPLEMENTATION_TASKBOOK_V2.md 的 0–2 节与 VA00；
2. 阅读 05_ui_ux/README.md、ui_system_v2.md、ui_tokens_v2.json；
3. 阅读 06_art/README.md、one_bit_art_bible.md、character_asset_contract_v2.md、region_asset_contract_v2.md；
4. 阅读 08_technical/godot_architecture.md、performance_budget.md、testing_strategy.md；
5. 检查当前 repo、Godot 版本、dirty worktree、已有 UI/art/import/test 结构；
6. 列出你计划新增／修改的文件，指出与现有架构的差异；
7. 只做 VA00。不要提前实现 VA01+。

硬约束：
- 不改 00_project、01_game_design、02_narrative、03_locations、04_characters 的现有内容；
- 不改剧情、玩法结果、角色关系逻辑；
- 320×180，整数放大，nearest；
- 可见 RGB 只有 #000/#fff，alpha 只有 0/255；
- EN/JA；keyboard/controller 同等；
- 每个功能在强制 Profile A、reduced motion、safe flash 下可用；
- 不导入 concept/preview/blockout 到 release；
- 不下载或提取官方／同人素材；
- 先写 validator/fixture/test，再完成实现；
- 不隐藏未运行的测试。

发生设计冲突时：机器可读 v2 JSON > v2 MD > 旧专项文档 > ascii_wireframes。PNG 是视觉参考；状态、尺寸、输入以 JSON 为准。

VA00 完成后停下，报告改动、测试、截图 fixture、人工 1×/EN/JA/forced-A 检查和 blocker，等待批准再进入 VA01。
```
