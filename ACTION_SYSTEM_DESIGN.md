# 動作系統設計

## 架構概述

新的動作系統包含三層架構：

### 繼承關係圖
```
Action (抽象基類)
├── ContinuousAction (持續動作)
└── ConditionalAction (條件動作)
    ├── TimedAction (時間動作)
    └── JumpAction (跳躍動作)
```

### 1. 基礎抽象類別
- **Action** (`action.gd`): 所有動作的抽象基類
  - 提供基本的 `start()` 和 `update()` 方法
  - 不包含具體的停止邏輯

### 2. 三種動作基類
- **ContinuousAction** (`continuous_action.gd`): 持續動作
  - 繼承自 `Action`
  - 永遠不會自動結束
  - 需要外部條件來停止
  - 適用於：移動、衝刺等持續動作

- **ConditionalAction** (`conditional_action.gd`): 條件動作
  - 繼承自 `Action`
  - 基於特定條件結束
  - 子類需要重寫 `should_stop()` 方法
  - 適用於：跳躍（觸地停止）、移動到牆壁等基於遊戲狀態的動作

- **TimedAction** (`timed_action.gd`): 時間動作
  - 繼承自 `ConditionalAction`
  - 包含 `duration` 屬性
  - 時間也是一種條件，所以繼承自條件動作
  - 自動在時間到期時停止
  - 適用於：無敵狀態、技能冷卻等有明確時間限制的動作

### 3. 具體動作實現
- **MoveAction** (`basic_move.gd`): 移動動作
  - 繼承自 `ContinuousAction`
  - 設定玩家速度
  - 不會自動停止，需要外部條件（如停止輸入）來結束

- **JumpAction** (`jump_action.gd`): 跳躍動作
  - 繼承自 `ConditionalAction`
  - 設定跳躍速度
  - 在觸地時立即停止

- **SwitchAnimalAction** (`switch_animal.gd`): 切換動物動作
  - 繼承自 `TimedAction`
  - 立即生效（duration = 0.0）

## 使用方式

### 創建持續動作（移動）
```gdscript
var move_action = MoveAction.new(Vector2(100, 0), "Move Right")
```

### 創建時間動作（無敵狀態）
```gdscript
var invincible_action = InvincibleAction.new(2.0, "Invincible")
```

### 創建條件動作（跳躍）
```gdscript
var jump_action = JumpAction.new(Vector2(0, -300), "Jump")
```

### 動作執行
```gdscript
# 開始動作
action.start(player)

# 更新動作（在遊戲循環中調用）
var is_finished = action.update(player, delta)
if is_finished:
    # 動作結束，可以執行下一個動作
    pass
```

## 三種類型的特點

### 1. 持續動作 (ContinuousAction)
- **特點**: 永遠不會自動結束
- **適用場景**: 移動、衝刺、持續效果
- **停止方式**: 需要外部條件（如停止輸入）

### 2. 條件動作 (ConditionalAction)
- **特點**: 基於遊戲狀態條件結束
- **適用場景**: 跳躍（觸地停止）、移動到牆壁、達到目標
- **停止方式**: 滿足特定條件時停止

### 3. 時間動作 (TimedAction)
- **特點**: 基於時間條件結束（繼承自條件動作）
- **適用場景**: 無敵狀態、技能冷卻、定時效果
- **停止方式**: 時間到期自動停止
- **優勢**: 可以結合時間條件和其他條件（如觸地時提前停止）

## 動物系統

### AnimalResource
存儲動物的基本屬性：
- `name`: 動物名稱
- `move_speed`: 移動速度
- `jump_velocity`: 跳躍速度
- `texture`: 動物貼圖
- `color`: 動物顏色

### Animal 類別
每個動物都會自動創建：
- `move_action`: 移動動作（基於 move_speed）
- `jump_action`: 跳躍動作（基於 jump_velocity）

### 使用方式
```gdscript
# 創建動物
var wolf = Wolf.new()
var rabbit = Rabbit.new()

# 獲取動作
var move_action = wolf.get_move_action()
var jump_action = rabbit.get_jump_action()

# 執行動作
move_action.start(player)
var is_finished = move_action.update(player, delta)
```

## Card Deck 系統

### CardDeck 類別
- 總是包含四種卡片：左移、右移、左跳、右跳
- 基於當前動物資源動態創建卡片
- 當切換動物時自動更新卡片

### 使用方式
```gdscript
# 創建 card deck
var card_deck = CardDeck.new()

# 設置當前動物
card_deck.set_current_animal(wolf)

# 獲取特定卡片
var move_left_card = card_deck.get_move_left_card()
var jump_right_card = card_deck.get_jump_right_card()

# 連接到卡片選擇事件
card_deck.card_selected.connect(_on_card_selected)
```

### 卡片創建邏輯
1. **移動卡片**: 基於動物的 `move_speed` 創建左右移動動作
2. **跳躍卡片**: 基於動物的 `jump_velocity` 創建左右跳躍動作
3. **動態更新**: 切換動物時重新創建所有卡片

## 優點

1. **清晰的責任分離**: 三種類型有明確的區分和用途
2. **靈活的擴展性**: 可以輕鬆創建新的動作類型
3. **統一的接口**: 所有動作都使用相同的 `start()` 和 `update()` 方法
4. **智能停止**: 條件動作可以根據遊戲狀態智能停止
5. **類型安全**: 每種類型都有明確的停止機制
6. **數據驅動**: 動物屬性通過 Resource 存儲，易於配置和修改
7. **自動化動作創建**: 每個動物自動擁有基本的移動和跳躍動作
8. **動態卡片系統**: 卡片基於當前動物動態生成，確保一致性
9. **簡化 UI**: 總是四種卡片，簡化用戶界面和邏輯
