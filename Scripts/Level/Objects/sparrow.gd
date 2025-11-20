extends CharacterBody2D
class_name Sparrow

@onready var sprite: Sprite2D = %Sparrow
@onready var detect_area: Area2D = %DetectArea
@onready var visible_on_screen : VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var anim_player: AnimationPlayer = %AnimationPlayer

var is_on_screen: bool = true

# Movement properties
@export var jump_force: float = -80.0
@export var move_speed: float = 30.0
@export var max_wander_distance: float = 100.0
@export var min_jump_interval: float = 1.
@export var max_jump_interval: float = 2.5
@export var fly_speed: float = 250.0
@export var fly_move_speed: float = 100.0
@export var gravity: float = 980.0

var original_position: Vector2
var jump_timer: float = 0.0
var is_flying_away: bool = false
var fly_direction: int = 1

func _ready():
    add_to_group("sparrow")
    original_position = global_position
    reset_jump_timer()
    
    visible_on_screen.screen_entered.connect(func(): is_on_screen = true)
    visible_on_screen.screen_exited.connect(func(): is_on_screen = false)
    detect_area.body_entered.connect(_on_detect_area_body_entered)
    is_on_screen = visible_on_screen.is_on_screen()

func _physics_process(delta):
    if is_flying_away:
        _handle_fly_away_movement(delta)
    else:
        _handle_idle_movement(delta)
    move_and_slide()

func _handle_idle_movement(delta):
    # Apply gravity
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed * delta * 4)
             
        jump_timer -= delta
        if jump_timer <= 0:
            pick_next_action()

func pick_next_action():
    reset_jump_timer()
    
    # Randomly pick between idle (stay) and jump
    if randf() < 0.3:
        await perform_jump()
    else:
        await perform_idle_action()

func perform_idle_action():
    sprite.flip_h = (randf() >= 0.5)
    await play_random_idle_animation()

func _handle_fly_away_movement(_delta):
    anim_player.play("FlyAway")
    velocity.y = -fly_speed + randf_range(-40, 40)
    velocity.x = fly_direction * (fly_move_speed + randf_range(-20, 20))
    
    if not is_on_screen:
        queue_free()

func perform_jump():
    var direction = 0
    var distance_from_center = global_position.x - original_position.x
    
    # Check if too far from original position
    if abs(distance_from_center) > max_wander_distance:
        # Jump back towards center
        direction = -sign(distance_from_center)
    else:
        # Random direction (-1 or 1)
        direction = [-1, 1].pick_random()
    
    velocity.y = jump_force
    velocity.x = direction * move_speed
    
    # Flip sprite based on direction
    sprite.flip_h = (direction > 0)
    await get_tree().create_timer(0.3).timeout

func reset_jump_timer():
    jump_timer = randf_range(min_jump_interval, max_jump_interval)

func play_random_idle_animation():
    # Check if animations exist to avoid errors, but user code had this list.
    if anim_player.has_animation("Idle1"):
        var random_animation = ["Idle1", "Idle2", "Idle3", "Idle4"][randi() % 4]
        # Verify animation exists before playing to be safe
        if anim_player.has_animation(random_animation):
            anim_player.play(random_animation)
            await anim_player.animation_finished

func _on_detect_area_body_entered(body: Node):
    if body is Player:
        # Trigger all sparrows to fly away
        if body.global_position.x > global_position.x:
            fly_direction = -1
        else:
            fly_direction = 1
        get_tree().call_group("sparrow", "fly_away", fly_direction)
      

func fly_away(direction: int):
    if is_flying_away:
        return
        
    is_flying_away = true
    collision_mask = 0
    # Play fly animation
    anim_player.play("FlyAway")
    
    # Initial boost
    fly_direction = direction
    sprite.flip_h = (direction < 0)
