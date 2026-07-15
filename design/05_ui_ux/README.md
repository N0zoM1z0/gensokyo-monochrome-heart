# UI / UX Package v2

这里是新版 1-bit UI 的权威入口。旧版不是被删除：原有 controls、dialogue、flow、localization 和 accessibility 文档继续保留；v2 在其上固定了可直接实现的 token、组件、页面、Godot scene path、样例和验收。

## 先读

1. `ui_system_v2.md` — 总体规则与落地方式；
2. `ui_tokens_v2.json` — 320×180、网格、字体、边框、时序、profile 与可访问性 token；
3. `component_catalog.md` / `.json` — 30 个共享组件；
4. `screen_inventory.md` / `.json` / `.csv` — 40 个完整页面合同；
5. `navigation_state_ownership.md` — UI stack、focus、GameState 边界；
6. `godot_scene_map.json` — scene、autoload 与组件路径；
7. `ui_implementation_backlog.md` — Codex 实现顺序；
8. `ui_acceptance_matrix.md` — 每页阻断验收；
9. `samples/complete_ui_sample_atlas_2x.png` — 24 个关键页面的实际像素样例。

## 权威优先级

发生冲突时按以下顺序处理：

1. `ui_tokens_v2.json` 与 `screen_inventory.json` 的机器可读尺寸／状态；
2. `ui_system_v2.md`、`component_catalog.md`、`navigation_state_ownership.md`；
3. 旧版专项文档；
4. `ascii_wireframes.md` 只作历史结构参考，不再代表美术目标。

## 样例说明

`samples/raw_320x180/` 是实现基准，不能在 4× 图上继续编辑；`preview_4x/` 只供审阅。所有样例是代码生成的精确黑白像素图，生成器位于 `06_art/tools/generate_complete_ui_samples.js`。
