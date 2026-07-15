# Gensokyo: Monochrome Heart — 新版 1-bit 视觉系统 Demo

这是一套可以继续生产的 UI／角色建模原型，不是单纯的气氛图。它把此前的四个方向整合为一套共享骨架：同一内部画布、同一角色尺寸、同一动画帧、同一 UI 状态，只切换不同的像素表现皮肤。

## 先看什么

1. 打开 `demo/index.html`：切换 A／B／C／D、三处地点、三名角色与 idle／walk／talk。
2. 打开 `preview/`：查看无需浏览器的静态 PNG 与动画 GIF。
3. 阅读 `ARTIFACT_INDEX.md`：按主题找到全部素材。
4. 阅读 `docs/00_visual_system_v2.md`：了解四种风格如何共存。

## 四种表现模式

| 模式 | 主用途 | 视觉角色 |
|---|---|---|
| A — Pocket Shrine | 默认探索、日常对话、普通菜单 | 最清晰、最省成本、最像真实黑白掌机 |
| B — PC-98 Dither | 红魔馆等密集室内、关键立绘、复杂机关 | 网点与细节更密，古早电脑感最强 |
| C — Woodblock Adventure | 章节卡、亲密剧情、回忆、安静余韵 | 木版墨块、纸条、破框立绘，叙事感最强 |
| D — Midnight LCD | 夜战、弹幕、梦境、地下与异常空间 | 黑底白像素、极简 HUD，战斗冲击最强 |

四种模式不同时混在一帧中。切换只发生在清晰的场景边界或演出节点，避免画面杂乱，也避免技术与美术成本变成四倍。

## 已固定的核心规格

- 内部画布：`320 × 180`；仅整数倍放大；nearest-neighbor；
- 可见颜色：纯黑 `#000000` 与纯白 `#FFFFFF`；灰度只由规则网点产生；
- UI 网格：`4 px`；场景 tile：`16 × 16 px`；
- Model S：`16 × 24`；Model M：`24 × 32`；Model L：`32 × 48`；
- Model M 动画：idle 4 帧、walk 8 帧、talk 4 帧；
- 对话与剧情逻辑不依赖皮肤；四种皮肤共享组件矩形和输入区域；
- 英文原型使用 Kiri-8 的 `5 × 7` 字形／`8 px` 单元；日文原型使用 DotGothic16 的 `12 px` 单元并二值化；
- 所有精灵拥有 `feet_anchor`、`focus_anchor`、双手锚点与 `head_top`。

## 原型边界

- Model M 的 idle／walk／talk 是可以运行的动画规格样例；角色全量细修仍需要逐帧美术通过。
- Model S 是手工简化标记；Model L 当前用于比例和剪影确认，不代表完整格斗动作集。
- 三套 tile 是基础语法和首批可用原型，不是每个地区的完整量产 atlas。
- DotGothic16 是 OFL 授权的可缩放字体，本 demo 把它阈值化来验证日文布局；正式项目可继续使用，或替换为获得许可的原生位图 JIS 字体。
- `assets/concepts/` 中的四张概念图是美术目标参考，不作为最终游戏内像素资产直接导入。

## 重新生成

生成脚本位于 `source/`。运行环境需要 Node.js、`pngjs` 与 ImageMagick；脚本不会修改剧情或原设计包。

```bash
NODE_PATH=/path/to/node_modules node source/generate_assets.js
NODE_PATH=/path/to/node_modules node source/build_gifs.js
```

字体样张的日文部分由已附带的 DotGothic16 WOFF2 渲染并二值化。字体许可证见 `assets/fonts/DotGothic16-LICENSE.txt`。
