# Turret.gd
# 砲塔類別，會發射包含傷害區域的子彈
extends StaticBody2D
class_name Turret

# 砲塔屬性
@export var fire_rate: float = 1.0  ## 每秒發射次數
@export var bullet_speed: float = 500.0
@export var will_fire: bool = true
@export var bullet_scene: PackedScene = preload("uid://2eslwfy76gub")

# 節點引用
@onready var fire_point: Marker2D = $FirePoint
@onready var base_sprite: ColorRect = $BaseSprite

# 內部變數
var _fire_timer: float = 0.0
var _fire_direction: Vector2 = Vector2.RIGHT  # 計算出的射擊方向

# 信號
signal bullet_fired(bullet: RigidBody2D)

func _ready() -> void:
    # 如果沒有設置發射點，創建一個
    if not fire_point:
        fire_point = Marker2D.new()
        fire_point.name = "FirePoint"
        fire_point.position = Vector2(30, 0)  # 預設在右側
        add_child(fire_point)
    
    # 根據發射點相對於BaseSprite中心的位置計算射擊方向
    _calculate_fire_direction()
    
    # 連接 GameManager 的狀態變化信號
    GameManager.in_game_state_changed.connect(_on_in_game_state_changed)


func _physics_process(delta: float) -> void:
    if will_fire:
    # 如果自動射擊，更新射擊計時器
        _update_fire_timer(delta)
    else:
        _fire_timer = 0.0

func _update_fire_timer(delta: float) -> void:
    """更新射擊計時器"""
    _fire_timer += delta
    
    # 檢查是否可以射擊
    if _fire_timer >= 1.0 / fire_rate:
        _fire_bullet()
        _fire_timer = 0.0

func _fire_bullet() -> void:
    """發射子彈"""
    if not bullet_scene or not fire_point:
        print("砲塔：缺少子彈場景或發射點")
        return
    
    # 實例化子彈
    var bullet = bullet_scene.instantiate()
    if not bullet:
        print("砲塔：無法實例化子彈")
        return
    
    # 將子彈添加到場景
    get_tree().current_scene.add_child(bullet)
    
    # 設置子彈位置和方向
    bullet.global_position = fire_point.global_position
    bullet.shoot(_fire_direction)
    
    # 發出射擊信號
    bullet_fired.emit(bullet)
    

func manual_fire() -> void:
    """手動射擊"""
    _fire_bullet()

func set_fire_rate(rate: float) -> void:
    """設置射擊頻率"""
    fire_rate = max(0.1, rate)  # 最小0.1秒間隔

func _calculate_fire_direction() -> void:
    """根據發射點相對於BaseSprite中心的位置計算射擊方向"""
    if fire_point and base_sprite:
        # 計算BaseSprite的中心點
        var base_center = Vector2(base_sprite.size.x / 2, base_sprite.size.y / 2)
        
        # 計算從BaseSprite中心到發射點的方向向量
        var direction_vector = base_center - fire_point.position
        
        # 正規化方向向量
        if direction_vector.length() > 0:
            _fire_direction = direction_vector.normalized()
        else:
            _fire_direction = Vector2.RIGHT  # 預設向右

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    if new_state == GameManager.InGameState.EXECUTING:
        will_fire = true
    else:
        will_fire = false

