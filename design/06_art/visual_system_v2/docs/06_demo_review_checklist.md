# Demo 评审清单

这轮评审的目的不是决定“哪张图最漂亮”，而是确认这套视觉系统是否值得进入 vertical slice。

## 1. 先看四张屏幕

- `preview/demo_A.png`
- `preview/demo_B.png`
- `preview/demo_C.png`
- `preview/demo_D.png`

检查：

- A 是否已经摆脱空白线框感；
- B 是否足够丰富但没有压住角色；
- C 的非对称选择是否仍清晰；
- D 的活动区域是否没有网点干扰；
- 四张图是否仍像同一款游戏。

## 2. 再看动画

- `preview/trio_idle.gif`
- `preview/trio_walk.gif`
- `preview/trio_talk.gif`

检查：

- 三人的 idle 是否体现不同性格，而不是同一套上下弹跳；
- walk 首尾是否无脚底滑动；
- talk 是否依靠手、道具与附件，而不是只闪嘴；
- Reimu 的 gohei、Marisa 的扫帚、Sakuya 的怀表／刀是否一眼可读；
- 24×32 是否太小、刚好或还可再缩。

## 3. 看比例锁定

打开 `preview/character_model_lock.png`。

需要决定：

- Model M 保持 24×32，还是改为 28×40；
- Model S 是否只用于地图／印章；
- Model L 是否继续 32×48，或为格斗提高到 40×56；
- 对话是否更依赖独立立绘，而不是放大 L。

当前推荐：M 保持 24×32；L 在真正制作格斗 vertical slice 后再决定是否提高。

## 4. 看 Tile

打开 `preview/tile_atlas_overview.png` 和三张 `preview/background_*.png`。

检查：

- 神社是否有足够负空间；
- 红魔馆的重复是否有层次；
- 竹林在 D 下是否清楚；
- 地面顶边和装饰线是否会混淆；
- 观察／危险／记忆图标是否可区分。

## 5. 看字体

打开 `preview/font_specimen.png`。

检查：

- 英文 8 px 是否适合长对话；
- 日文 12 px 是否在 1× 下可读；
- 黑底白字是否需要更粗；
- 人名标签 72 px 最大宽度是否够用；
- 是否接受 DotGothic16 阈值化原型，或要寻找原生位图 JIS 字体。

## 6. 打开互动 Demo

打开 `demo/index.html`，逐项切换：

- A／B／C／D；
- 博丽神社／红魔馆／永远亭；
- Reimu／Marisa／Sakuya；
- idle／walk／talk；
- EN／日本語；
- 锚点显示。

检查 profile 切换是否改变了美术但没有改变 UI 功能位置和动画数据。

## 7. 本轮不需要决定

- 全角色最终造型；
- 完整格斗动作集；
- 所有地点 atlas；
- 最终字体授权方案；
- 背景音乐；
- 剧情与玩法内容。

## 8. 下一轮建议的明确输入

只需要给出以下几项意见即可：

1. M 的尺寸：`24×32 保持`／`改为 28×40`；
2. A 的黑色面积：`保持`／`再丰富`／`更清爽`；
3. C 是否允许作为完整对话模式，还是只做章节卡；
4. D 是否只用于战斗，还是夜间探索也使用；
5. 三名角色中哪一个先做精修到生产级。

这五项会直接决定下一轮应画什么，不需要重新讨论剧情和玩法。

