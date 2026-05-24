# Godot 2D Zombie Survival Vertical Slice Plan

## Summary
当前仓库 `/Users/youclaw/Downloads/bunkertopia` 只有 `agent.md`，不是 git 仓库，没有 `project.godot`、场景、脚本或素材目录。已检测到本机 Godot 为 `4.6.1.stable`，符合 Godot 4.x 目标。仓库内没有生图脚本；当前 Codex 环境有内置 `image_gen` 生图能力，且本机 Python 有 `Pillow 12.1.1`，所以实施时优先用内置生图生成像素素材，失败则用 Python/Godot 程序生成 pixel placeholder。

目标版本做“可演示闭环”，不是开放世界：基地管理 -> 城市探索 -> 事件/研究/建造 -> 夜晚塔防 -> 黎明结算 -> 回到基地。

## Tech Stack And Structure
- Godot `4.6.1`，GDScript，2D oblique pixel-art。
- 使用 `Control` 做 HUD、研究界面、事件弹窗；使用 `Node2D`/`TileMapLayer` 做基地、城市和夜晚防守场景。
- 用 Autoload 单例管理跨场景状态：
  - `GameState.gd`：资源、天数、时间段、研究、防御设施、探索结果。
  - `EventBus.gd`：UI、资源变化、事件弹窗、战斗波次等信号。
  - `SceneRouter.gd`：基地、城市、夜晚防守、研究界面之间切换。
  - `DataRegistry.gd`：加载资源、建筑、研究、事件、僵尸波次定义。
- 建议目录：
  - `project.godot`
  - `scenes/main/`
  - `scenes/base/`
  - `scenes/city/`
  - `scenes/defense/`
  - `scenes/ui/`
  - `scripts/core/`
  - `scripts/base/`
  - `scripts/city/`
  - `scripts/defense/`
  - `scripts/ui/`
  - `data/`
  - `assets/art/`
  - `assets/audio/`
  - `tools/`
  - `README.md`

## Core Scenes
- `Main.tscn`：应用入口，加载当前玩法阶段，挂 HUD、弹窗层、转场层。
- `BaseHub.tscn`：像素风地堡内部/地表基地，玩家可移动，能与工作台、研究台、仓库、防线入口交互。
- `CityExplore.tscn`：小型废城探索地图，不做开放世界；包含 6-10 个搜索点、风险条、撤离按钮、随机事件。
- `NightDefense.tscn`：基地外墙塔防场景，僵尸从固定路线推进，炮塔/路障自动攻击或阻挡。
- `ResearchScreen.tscn`：研究树/项目列表，可消耗样本、零件、食物或电力解锁效果。
- `BuildDefensePanel.tscn`：建造/升级路障、机枪塔、探照灯、陷阱。
- `HUD.tscn`：显示天数、阶段、生命/基地耐久、食物、水、零件、电力、样本、弹药。
- `EventPopup.tscn`：随机事件、探索结果、夜晚结算、研究完成弹窗。

## Script Systems
- Game loop:
  - 阶段枚举：`BASE_DAY`、`CITY_EXPLORE`、`BASE_PREP`、`NIGHT_DEFENSE`、`DAWN_REPORT`。
  - 每天固定流程，不引入复杂日程模拟。
- Resource system:
  - 资源：食物、水、零件、电力、样本、弹药、基地耐久。
  - 所有消耗和奖励走 `GameState.apply_resource_delta()`，并通过 `EventBus` 通知 HUD。
- Player and interaction:
  - `PlayerController2D.gd` 支持 WASD/方向键移动。
  - `Interactable.gd` 基类支持进入范围、显示提示、按键交互。
- City exploration:
  - 搜索点有资源奖励、感染风险、事件概率。
  - 探索中可撤离；风险满则触发损失或强制返回。
- Defense:
  - `WaveDirector.gd` 按天数生成小波次。
  - `ZombieEnemy.gd` 沿路径移动，攻击路障或基地。
  - `DefenseStructure.gd` 基类；派生路障、炮塔、陷阱。
- Research:
  - 数据定义研究项目：成本、前置、效果。
  - v1 只做 5 个项目：基础农业、弹药回收、路障加固、样本分析、低温疫苗线索。
- Event system:
  - 数据驱动事件：标题、正文、选项、资源变化、后续效果。
  - v1 做 8-12 个事件，覆盖探索、基地故障、幸存者、感染样本、夜晚异动。
- Save/load:
  - 预览版可先不做完整存档；如时间允许，加单槽 JSON 存档。
  - 必须保留重开项目后可直接运行的默认初始状态。

## Art Assets
- 优先用当前 Codex 内置 `image_gen` 生成项目素材，再整理到 `assets/art/`。
- 如果生图不可用，使用 Python Pillow 或 Godot `Image` 生成一致的低分辨率 placeholder PNG。
- 必需素材清单：
  - 基地地砖、墙体、地堡门、工作台、研究台、仓库、电机、床铺。
  - 城市地砖、废车、瓦砾、破楼、搜索箱、路灯、感染痕迹。
  - 夜晚防守背景、外墙、路障、机枪塔、探照灯、陷阱。
  - 玩家科学家 4 向 idle/walk 占位动画。
  - 僵尸 2-3 种：普通、快速、重型。
  - UI 图标：食物、水、零件、电力、样本、弹药、基地耐久、研究。
- 统一规格：
  - Tile：`32x32` 或 `48x32` oblique readable tiles。
  - 小角色：`32x48` sprite sheet。
  - UI 图标：`32x32`。
  - 风格：低饱和、脏暗、强轮廓、可读优先。

## Development Order
1. Project bootstrap
   - 创建 Godot 4 项目、主场景、Autoload、输入映射、README 骨架。
   - 验证：Godot 打开项目无报错，运行进入空主场景，Esc/退出正常。

2. Core state and UI shell
   - 实现 `GameState`、`EventBus`、`SceneRouter`、HUD、事件弹窗。
   - 验证：资源变化会刷新 HUD；按钮可切换阶段；事件弹窗可显示和关闭。

3. Base hub vertical slice
   - 实现基地场景、玩家移动、交互点：研究台、建造台、城市出口、夜晚入口。
   - 验证：玩家能移动并触发交互，基地像素风环境可见。

4. City exploration
   - 实现小地图、搜索点、撤离、随机奖励/风险。
   - 验证：进入城市后能搜索资源，触发事件，撤离后资源写回基地。

5. Research and defense build panel
   - 实现研究项目和防御设施购买/升级。
   - 验证：资源足够时可解锁研究或建造设施；不足时 UI 明确反馈。

6. Night defense
   - 实现僵尸路径、波次、路障、炮塔、基地受损、夜晚结算。
   - 验证：进入夜晚后僵尸生成并推进；防御设施生效；胜负/结算弹窗出现。

7. Pixel art pass
   - 用内置生图或程序 placeholder 替换纯色块，统一像素风、图标、场景可读性。
   - 验证：基地、城市、夜晚防守、UI 都能一眼识别主题。

8. Demo polish
   - 加开始菜单、暂停、简单音效占位、黎明报告、README 控制说明和限制说明。
   - 验证：从启动到完成至少 1 个完整白天-夜晚循环，无阻塞错误。

## Test And Verification
- Godot editor verification:
  - `godot --editor --path /Users/youclaw/Downloads/bunkertopia` 能打开。
  - Main Scene 已设置，点击 Run 能进入游戏。
- Runtime smoke test:
  - 启动主场景。
  - 玩家移动。
  - 打开研究界面。
  - 打开建造界面。
  - 进入城市，搜索一次，撤离。
  - 进入夜晚防守，完成或失败一波。
  - 返回黎明结算。
- Data checks:
  - 每个研究项目都有成本、名称、描述、效果。
  - 每个事件都有至少一个选项。
  - 每个防御设施都有成本、耐久或攻击参数。
- Asset checks:
  - 所有场景引用的纹理存在于 `assets/art/`。
  - 缺失最终美术时，必须有 placeholder，不允许运行时报红缺资源。
- Acceptance:
  - 预览版必须能完整跑一个演示循环。
  - 代码分散在核心、基地、城市、防守、UI 模块中，不出现巨型 `Main.gd` 承担全部逻辑。

## Risks And Alternatives
- 风险：当前仓库完全空，没有现有 Godot 项目。
  - 替代：从最小 `project.godot` 和 `Main.tscn` 开始，先保证每日闭环，再补美术。
- 风险：像素风 AI 生图不稳定，透明背景/切图可能耗时。
  - 替代：先用 Pillow/Godot 程序生成统一 placeholder；AI 图只作为 polish 阶段增强。
- 风险：塔防、探索、研究三套玩法同时做容易膨胀。
  - 替代：每套只做 1 个核心交互：搜索点、研究按钮、自动炮塔波次。
- 风险：Godot 4.6 与教程/插件版本差异。
  - 替代：不依赖第三方插件；只用 Godot 内置 Node2D、Control、Resource、signals。
- 风险：斜俯视 TileMap 美术和碰撞复杂。
  - 替代：v1 使用 oblique-looking 2D sprites 和简单矩形碰撞，不做真实等距寻路。
- 风险：保存系统会拖慢 vertical slice。
  - 替代：v1 不要求持久存档，只保证一次运行内闭环；README 写明限制。
- 风险：资源数值平衡不足。
  - 替代：硬编码一套演示友好的默认数值，优先保证可完成一晚防守。
