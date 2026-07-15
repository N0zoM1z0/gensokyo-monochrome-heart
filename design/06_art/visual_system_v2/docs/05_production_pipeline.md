# 生产管线、Godot 导入与扩展顺序

## 1. 目录与命名

推荐游戏仓库结构：

```text
art/
  characters/<character>/<model>/<action>/
  portraits/<character>/<profile>/
  tiles/<region>/
  ui/components/
  ui/skins/a|b|c|d/
  fonts/
data/
  visual_profiles.json
  sprite_anchors.json
  tilesets/
```

命名使用小写 snake_case：

```text
chr_reimu_m_walk_00.png
chr_sakuya_m_sheet.png
portrait_marisa_c_sincere_00.png
tile_shrine_veranda_top_00.png
ui_paper_panel_b_focused.png
stamp_aya_camera_09.png
```

`profile` 不写进基础角色动作文件名，除非该素材确实为 profile 专属；正常情况由 shader／材质／反相 sheet 和 UI skin 处理。

## 2. 源文件与导出

- 源文件始终按目标像素尺寸绘制；
- 不在 4× 预览图上继续编辑；
- 原始 PNG 使用无损导出；
- 精灵允许 alpha，但可见 RGB 只能是 0／255；
- atlas 不嵌入缩放；
- 预览图用 nearest-neighbor 整数放大并与 raw 分开；
- 概念图不进入游戏 import 目录。

## 3. Godot 4 导入建议

### Project Settings

```text
Display > Window > Size > Viewport Width  = 320
Display > Window > Size > Viewport Height = 180
Display > Window > Stretch > Mode          = canvas_items
Display > Window > Stretch > Aspect        = keep
Rendering > Textures > Default Filters > Use Nearest Mipmap Filter = false
Rendering > 2D > Snap > Snap 2D Transforms to Pixel = true
Rendering > 2D > Snap > Snap 2D Vertices to Pixel = true
```

窗口缩放应由一个整数 scale controller 选择 2×／3×／4×。若显示尺寸不能整除，使用 letterbox，不用非整数拉伸填满。

### Texture Import

```text
Filter: Off
Mipmaps: Off
Repeat: Disabled（tile atlas 按需求）
Compression: Lossless
Fix Alpha Border: Off（检查黑白边缘后决定）
```

### AnimatedSprite2D

- raw sheet 直接按 24×32 切 16 帧；
- idle 0–3，walk 4–11，talk 12–15；
- 用动画资源保存时长，不在帧图里复制帧来“延长”；
- `feet_anchor` 对齐 Node2D 原点；
- 武器和 companion 可用子 sprite，但必须复用 anchor。

## 4. PresentationProfile 数据

建议结构：

```json
{
  "id": "D",
  "polarity": "inverted",
  "panel_skin": "midnight_lcd",
  "dither_budget": "combat_clear",
  "portrait_overflow_px": 0,
  "hud_layout": "combat_slim",
  "vfx_set": "lcd_afterimage",
  "fallback_profile": "A"
}
```

事件只请求 profile，不直接操作每个 UI 节点。可访问性强制 A 时，presentation service 返回 A，但事件状态不变。

## 5. Profile 变换

### 反相

D 可以使用：

- 预导出的 inverted sprite sheet；或
- 只交换 0／255 的调色板 shader。

若使用 shader，alpha 不反相；用于轮廓的黑与用于空洞的透明必须区分。弹幕、UI 和角色均需在白底／黑底测试。

### 网点

网点由固定 4×4 Bayer pattern 生成。相位应绑定世界坐标或对象局部坐标，避免镜头移动导致纹理游动。文字与 hitbox 周围建立 no-dither mask。

### C 的破框立绘

立绘仍受 PortraitStage 容器管理，只允许视觉超出最多 8 px；输入焦点、正文矩形与 safe frame 不改变。

## 6. 角色生产顺序

不要立刻扩展几十名角色。先完成三名角色的 vertical slice：

### Reimu

- M：idle／walk／talk／observe／cup／gohei interaction；
- S：地图标记、Journal stamp；
- L：中立、轻攻击、重攻击、符卡起手、受击、倒地；
- 立绘：工作中立、社交中立、恼火、好笑、疲惫、克制真诚。

### Marisa

- M：idle／walk／talk／broom mount／borrow interaction；
- S：地图、Journal；
- L：扫帚弧、炉火后坐、空中转向；
- 立绘：自信、被抓包、专注实验、私人安静。

### Sakuya

- M：idle／walk／talk／watch／knife／tea service；
- S：地图、Journal；
- L：精准步法、刀扇、时间停顿起手；
- 立绘：工作礼貌、冷幽默、警觉、疲惫、一分钟失控。

通过后再添加：Patchouli（验证 B）、Youmu（验证剑／companion anchor）、Yuyuko（验证 C）、Reisen（验证 D）。

## 7. Tile 生产顺序

每个地区先做一张可走的 `320×180` 房间，而不是先画完整 atlas：

1. 地面／碰撞／出口；
2. 一件可观察道具；
3. 一件关系道具；
4. 前中后景层级；
5. calm 与 incident 版本；
6. A／目标 profile 双测试；
7. 再拆成可复用 atlas。

神社先验证负空间；红魔馆验证密集纹理；永远亭验证反相与相似走廊。

## 8. UI 生产顺序

1. A 的 PaperPanel、CharacterTag、ToneChoice、ContextPrompt；
2. 日英换行、backlog、焦点记忆；
3. D 的战斗 HUD 和侧栏 banter；
4. B 的双框、角标与调查分栏；
5. C 的折角、破框立绘与章节卡；
6. Journal／Map／Pause 等 modal 逐一换肤。

逻辑通过后才加皮肤动画，避免美术掩盖导航错误。

## 9. 自动验证

`source/validate_assets.js` 应检查：

- raw PNG 尺寸；
- RGB 是否只含 0／255；
- alpha 是否只含 0／255；
- sprite sheet 是否 384×32；
- tile atlas 是否 128×64；
- UI raw sheet 是否 640×360；
- demo raw 是否 320×180；
- manifest 是否列出文件；
- GIF 是否存在且拥有正确帧数（外部 `identify` 可补充）。

## 10. 手工 QA

- 1× 看角色能否识别；
- 4× 检查孤立像素与锯齿节奏；
- 白底／黑底各看一次；
- 日英各跑一段三行对话；
- 60 秒 D 模式确认眼疲劳与弹幕清晰度；
- 禁用闪烁后仍有命中反馈；
- 整数／非整数窗口尺寸都不产生平滑；
- UI 焦点在 profile 切换前后保持；
- 修改一处 tile 不引发碰撞变化，除非 metadata 同步修改。

## 11. 本 demo 的再生成

```bash
NODE_PATH=/path/to/node_modules node source/generate_assets.js
```

脚本生成 raw PNG、放大预览、sprite manifest、tile manifest 与 UI token。GIF 使用 ImageMagick 从 `/tmp` 中的精确帧组成。概念图和字体文件不由脚本覆盖。

