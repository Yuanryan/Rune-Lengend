# 條件動作基類 - 基於特定條件結束
@abstract
class_name ConditionalAction
extends Action

# 子類需要重寫這個方法來定義停止條件
func should_stop(_player: Player, delta: float) -> bool:
    return false

# 回傳 true 表示動作結束
func update(_player: Player, delta: float) -> bool:
    return should_stop(_player, delta)
