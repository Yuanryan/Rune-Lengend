# Turret.gd
# 砲塔類別，會發射包含傷害區域的子彈
@icon("res://Assets/icons/diagram-next-solid-full.svg")
extends StaticBody2D
class_name Turret

# 砲塔屬性
@export var fire_rate: float = 1.0  ## 每秒發射次數
@export var bullet_speed: float = 500.0 
@export var bullet_scene: PackedScene = preload("uid://2eslwfy76gub")

# 節點引用
@onready var fire_point: Marker2D = $FirePoint
@onready var base_sprite: ColorRect = $BaseSprite
@onready var fire_timer: Timer = %FireTimer
@onready var visible_on_screen : VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

var is_on_screen: bool = true

# 內部變數
var _fire_direction: Vector2 = Vector2.RIGHT  # 計算出的射擊方向
var can_fire: bool = false

# 信號
signal bullet_fired(bullet: RigidBody2D)

func _ready() -> void:
    
    # 根據發射點相對於BaseSprite中心的位置計算射擊方向
    _calculate_fire_direction()
    
    # 設置Timer
    if fire_timer:
        fire_timer.timeout.connect(_fire_bullet)
        fire_timer.wait_time = 1.0 / fire_rate
        fire_timer.one_shot = false
    
    # 連接 GameManager 的狀態變化信號
    GameManager.in_game_state_changed.connect(_on_in_game_state_changed)
    visible_on_screen.screen_entered.connect(func(): is_on_screen = true)
    visible_on_screen.screen_exited.connect(func(): is_on_screen = false)
    is_on_screen = visible_on_screen.is_on_screen()


func _fire_bullet() -> void:
    """發射子彈"""
    if not can_fire or not is_on_screen:
        return
        
    if not bullet_scene or not fire_point:
        return
    
    # 實例化子彈
    var bullet = bullet_scene.instantiate()
    if not bullet:
        print("砲塔：無法實例化子彈")
        return

    # 設置子彈位置和方向
    bullet.global_position = fire_point.global_position
    bullet.shoot(_fire_direction)

    # 將子彈添加到場景
    owner.add_child(bullet)
    
    # 將子彈添加到 bullets 群組以便管理
    bullet.add_to_group("bullets")
    
    # 發出射擊信號
    bullet_fired.emit(bullet)
    

func manual_fire() -> void:
    """手動射擊"""
    _fire_bullet()

func set_fire_rate(rate: float) -> void:
    """設置射擊頻率（每秒發射次數）"""
    fire_rate = max(0.1, rate)  # 最小每秒0.1次（即最大10秒間隔）
    
    # 更新Timer的等待時間
    if fire_timer:
        fire_timer.wait_time = 1.0 / fire_rate

func _calculate_fire_direction() -> void:
    """根據發射點相對於BaseSprite中心的位置計算射擊方向"""
    if fire_point and base_sprite:
        # 計算BaseSprite的中心點
        var base_center = Vector2(base_sprite.size.x / 2, base_sprite.size.y / 2)
        _fire_direction = ((fire_point.position - base_center) * Vector2(cos(global_rotation), sin(global_rotation))).normalized()

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    if new_state == GameManager.InGameState.PLANNING or new_state == GameManager.InGameState.EXECUTING:
        can_fire = true
        if fire_timer.is_stopped():
            _fire_bullet()
            fire_timer.start()
    elif new_state != GameManager.InGameState.COMPLETED and new_state != GameManager.InGameState.FAILED:
        can_fire = false
        if fire_timer.is_stopped() == false:
            fire_timer.stop()        
