# DamageArea 使用說明

## 概述
`DamageArea` 是一個基礎類別，當玩家觸碰到該區域時會導致玩家死亡並從最後的檢查點重新開始。

## 功能特點
- 當玩家觸碰時立即死亡
- 自動從最後檢查點重新載入關卡
- 停止玩家所有正在執行的動作
- 發出死亡信號供其他系統監聽

## 使用方法

### 1. 在關卡編輯器中添加傷害區域
1. 在場景中實例化 `damage_area.tscn`
2. 調整 `CollisionShape2D` 的大小和位置
3. 設置適當的碰撞層和遮罩

### 2. 自定義傷害區域
可以繼承 `DamageArea` 類別來創建特殊類型的傷害區域：

```gdscript
extends DamageArea

func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        # 自定義死亡邏輯
        print("特殊傷害區域觸發")
        super._on_body_entered(body)  # 調用父類方法
```

### 3. 監聽死亡事件
可以連接 `player_died` 信號來監聽玩家死亡事件：

```gdscript
func _ready():
    var damage_area = get_node("DamageArea")
    damage_area.player_died.connect(_on_player_died)

func _on_player_died(player: Player):
    print("玩家死亡事件觸發")
```

## 技術細節
- 使用 `Area2D` 節點檢測碰撞
- 碰撞層設置為第1層（玩家層）
- 自動調用 `LevelManager.reload_level_from_last_checkpoint()` 重新載入關卡
- 與現有的檢查點系統完全兼容

## 注意事項
- 確保關卡中有檢查點，否則會從起始點重新開始
- 傷害區域會立即觸發，沒有無敵時間
- 玩家死亡時會停止所有動作並重置速度
