# Bunkertopia

**Bunkertopia** 是一个 Godot 4.x 的 2D 斜俯视像素风僵尸末日硬核生存原型。当前仓库实现的是一个可运行的 vertical slice：白天在基地维护、防守与研究，外出到城市搜刮资源，夜晚回到基地抵御尸潮，黎明生成战报并继续推进研究。

## 当前定位

这个版本不是完整游戏，而是一个“能跑通闭环”的演示切片。重点已经落在以下几件事上：

- 基地日间管理
- 城市外出搜刮
- 夜晚尸潮防守
- 资源和身体状态的持续压力
- 研究线推进与事件弹窗反馈

## 运行方式

1. 用 **Godot 4.x** 打开仓库根目录下的 `project.godot`
2. 主场景已经设置为 `scenes/main/Main.tscn`
3. 直接点击 Godot 编辑器里的运行按钮即可进入游戏

## 控制方式

- `WASD` / 方向键：移动
- `E`：交互 / 搜刮 / 打开可交互点
- `R`：打开研究 UI
- `B`：打开基地面板
- `N`：直接切到夜晚防守，用于测试尸潮流程
- `Esc`：关闭弹窗或当前打开的 UI 面板

## 已实现内容

### 主场景

- `Main` 作为入口场景与路由层，负责装载基地、城市、夜晚防守与 UI
- 已接好 HUD、研究面板、基地面板和事件弹窗
- 运行时会自动触发开场事件

### 玩家移动与交互

- 玩家可在基地和城市场景中移动
- 靠近交互点后会显示提示
- `E` 可触发交互

### 基地内容

- 基地主场景
- 城市出口
- 坠机残骸
- 农田
- 畜舍
- 围墙
- 炮塔
- 发电机
- 实验室
- 基地维护与建造信息面板

### 城市内容

- 城市废墟探索场景
- 搜刮点
- 废弃药房
- 便利店货架
- 坠机货箱
- 警车后备箱
- 倒塌公寓
- 流动实验车
- 撤回地堡入口

### 资源与身体状态 UI

- 资源 UI：食物、水、电力、弹药、燃料、样本、零件、研究进度
- 身体状态 UI：卡路里、蛋白质、维生素、脂肪、睡眠、理智、感染风险
- 基地防线状态：围墙完整度、地堡结构完整度

### 搜刮

- 城市容器支持随机掉落
- 搜刮会带来感染风险与身体消耗
- 搜刮结果通过事件弹窗反馈

### 夜晚尸潮

- 夜晚防守场景已经可运行
- 僵尸波次会按天数推进
- 有普通、奔跑者、臃肿体等敌人类型
- 炮塔会自动攻击范围内目标
- 僵尸会攻击围墙或地堡
- 可记录击杀、围墙损伤、基地损伤与战斗消耗

### 设施受损与修复

- 夜晚会记录围墙受损与地堡受损
- 基地面板提供修补围墙、炮塔装填、维护发电机等操作
- 发电机和炮塔都已经和资源系统联动

### 战报

- 黎明后会生成战报弹窗
- 战报包含击杀数、基地损伤、围墙损伤、资源消耗、损失项以及防线完整度

### 研究 UI

- 研究面板已经实现
- 有研究进度条和研究项目列表
- 支持前置条件、资源消耗和身体状态消耗
- 已接入样本分析、低温血清、疫苗线索、基础农业、路障加固等项目

### 事件弹窗

- 已有开场事件
- 已有尸潮事件
- 已有基地受损提示
- 已有研究推进提示
- 弹窗支持选择项与自动返回基地

## 项目结构和主要文件

```text
project.godot
data/gameplay.json
scenes/
  main/Main.tscn
  base/BaseHub.tscn
  city/CityExplore.tscn
  defense/NightDefense.tscn
  ui/HUD.tscn
  ui/EventPopup.tscn
  ui/ResearchPanel.tscn
  ui/BasePanel.tscn
scripts/
  core/Main.gd
  core/SceneRouter.gd
  core/GameState.gd
  core/EventBus.gd
  core/DataRegistry.gd
  entities/PlayerController.gd
  base/BaseHub.gd
  base/InteractablePoint.gd
  city/CityExplore.gd
  city/SearchContainer.gd
  defense/NightDefense.gd
  defense/Turret.gd
  defense/ZombieEnemy.gd
  defense/WallSegment.gd
  ui/HUD.gd
  ui/EventPopup.gd
  ui/ResearchPanel.gd
  ui/BasePanel.gd
assets/art/
  characters/
  tiles/
  objects/
  ui/
```

### 说明

- `project.godot`：Godot 项目配置，主场景和 Autoload 都在这里
- `scripts/core/`：全局状态、事件总线、场景路由、入口逻辑
- `scripts/base/`：基地场景与交互点
- `scripts/city/`：城市搜刮与搜索容器
- `scripts/defense/`：夜晚尸潮、炮塔、僵尸和围墙
- `scripts/ui/`：HUD、研究面板、基地面板、事件弹窗
- `data/gameplay.json`：研究、建造、容器、僵尸与事件数据

## 已知限制

- 当前仍是 vertical slice，不是完整内容版
- 没有存档/读档系统
- 城市探索不是开放世界，只是一个小型搜刮地图
- 基地建造与研究主要通过面板驱动，尚未做完整自由摆放和深度升级树
- 夜晚防守是固定路线和固定逻辑的演示版本，还没有更复杂的 AI、路径或编队变化
- 美术以现阶段素材和占位图为主，仍会继续补强

## 下一步路线

- 补全更多研究分支，让基地经营更像长期生存系统
- 扩展城市事件与搜刮点类型
- 增加更丰富的防御设施和升级路径
- 做更完整的夜晚波次、敌人组合和关卡变化
- 加入存档/读档
- 继续统一像素美术和 UI 观感

