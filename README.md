# Bunkertopia

**Bunkertopia** 是一个 Godot 4.x 2D 斜俯视像素风末日生存管理 Demo。当前版本面向 Steam Demo Candidate：玩家从正式主菜单进入，完成开局事件和教程，在白天搜刮城市与坠机点，回基地维护农田、畜舍、防线、电力和研究，夜晚抵御尸潮并查看黎明战报。

## 运行方式

1. 使用 Godot `4.6.1` 或兼容 Godot 4.x 打开 `project.godot`
2. 主场景为 `res://scenes/main/Main.tscn`
3. 点击运行进入正式主菜单

## 控制方式

- `WASD` / 方向键：移动
- `E`：交互、搜刮、开门、使用设施
- `Space` / 鼠标左键：近战或夜间应急射击
- `R`：打开研究 UI
- `B`：打开建造模式
- `Esc`：关闭面板或打开暂停菜单

## Demo 目标

- 胜利目标：完成第一阶段解药研究线，或撑过第 3 夜。
- 失败条件：基地核心被毁、感染失控、身体状态崩溃、关键资源耗尽。
- 推荐流程：城市搜刮与坠机残骸 -> 回基地维护农田/畜舍/发电机/炮塔 -> 夜晚防守 -> 黎明战报 -> 推进研究。

## 已实现内容

- 正式主菜单、继续游戏、设置、暂停、保存、退出、失败界面和 Demo 结束界面
- 单槽 JSON 存档，夜晚中保存会回到基地，避免损坏战斗状态
- 玩家移动、碰撞、交互范围提示、交互冷却和反馈
- 基地、城市、坠机点、农田、畜舍、围墙、门、炮塔、发电机、实验室、容器
- 白天搜刮、资源变化、身体状态变化、低资源警告
- 研究 UI、基地管理 UI、开局教程、事件弹窗、黎明战报
- 夜晚尸潮、防线阻挡、墙体受损、地堡受损、炮塔自动攻击、玩家应急攻击
- 开放式基地防守：白天可在网格上自由放置墙、门、电铁丝、尖刺陷阱、火焰陷阱、炮塔、发电机、电池、输电杆和生产设施
- 建造模式：显示格子、绿色/红色放置预览、占格检测、路径封死检测、维修、拆除、电网覆盖和威胁覆盖
- 动态夜晚防守：僵尸从多个方向来袭，路径由当前建筑布局动态计算；路径被封死时会攻击最近障碍
- 新防御数据：木栅栏、废铁墙、门、电铁丝、尖刺陷阱、火焰陷阱、基础炮塔、霰弹炮塔、探照灯、发电机、电池、输电杆
- 扩展僵尸：walker、runner、brute、crusher、crawler/swarm、fire weak infected、armored，并包含建筑伤害、护甲、火焰/穿刺克制和权重
- 电力管理：城市电网逐日衰减，发电、耗电、电池、过载和断电影响会显示在 HUD/建造 UI 中
- 物品与制作：搜刮原料，使用工作台/熔炉/实验台/农田/畜舍加工铁块、螺丝、电路板、电池芯、肥料和饲料
- 技能成长：工程学、农学、畜牧学、生物学影响制作成功率、耗时和产量，可通过制作和书本提升
- 参考根目录预览图右侧实机目标的 AI source sheet 美术：角色/僵尸瓦片动画图集、基地/城市/防御/生产建筑透明 PNG、资源/UI 图标、主菜单背景和 Steam store 源图
- 程序化 WAV 音效，运行时接入 `UI`、`SFX`、`Ambience` 音频总线
- Windows Demo 导出预设

## 项目结构

```text
assets/art/          游戏内像素美术、角色瓦片动画图集、物件、地面、UI 图标和 source sheet
assets/audio/        UI、SFX、夜晚环境音
assets/steam_store/  Steam capsule/header/library/source artwork
data/gameplay.json   研究、基地操作、搜刮容器、僵尸和事件数据
scenes/              Godot 入口、基地、城市、防守和 UI 场景
scripts/             core、base、city、defense、entities、ui 模块
scripts/systems/     网格建造、路径、电力、制作、技能、威胁和波次模块
tools/               可重复生成/抠图/切图/校验像素美术、Steam 图和 WAV 音效的脚本
```

## 重新生成资产

```bash
python3 tools/generate_pixel_assets.py
python3 tools/art_pipeline/extract_ai_target_sheet.py
python3 tools/art_pipeline/validate_art_assets.py
godot --headless --path . --import
```

## 目标风格美术管线

- 当前可玩资产优先使用 `assets/art/source/generated_raw/ai_target_sprite_sheet.png`，它是参考根目录预览图右侧实机目标生成的脏污低饱和像素 source sheet。
- `tools/art_pipeline/extract_ai_target_sheet.py` 会从 source sheet 抠绿底、去绿边、切出建筑透明 PNG，并把玩家/僵尸重新装配成固定 `64x64` 瓦片动画图集。
- `data/art_asset_manifest.json` 是运行时美术清单；`ArtRegistry` 通过它把角色、建筑、地面和 UI 图标映射到 Godot。
- 可选 ComfyUI 桥接：`python3 tools/art_pipeline/comfy_client.py --server http://192.168.50.143:8000 health`。没有 workflow 时不会阻塞本地管线。

## 导出 Windows Demo

```bash
mkdir -p build/windows
godot --headless --path . --export-release "Windows Demo" build/windows/BunkertopiaDemo.exe
```

## 已知限制

- Demo 使用固定小地图和开放式基地防守地块，不是开放世界。
- 存档是单槽试玩存档，不提供多存档管理。
- 游戏内核心美术已切换为参考目标预览图生成的 AI source sheet 资产；正式上架前仍建议逐帧人工修像素边缘和补齐更多方向帧。
- Steam store 图已经按尺寸生成，但正式上架前仍建议人工审视可读性、PG-13 适配和截图质量。
