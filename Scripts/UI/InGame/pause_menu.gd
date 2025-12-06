extends Control
class_name PauseMenu

signal pause_menu_shown
signal pause_menu_hidden

enum MenuState { GAME, PAUSED, OPTIONS } 
var menu_state := MenuState.GAME 

# Buttons
@onready var buttons : VBoxContainer = %Buttons
@onready var resume_button : Button = %Resume
@onready var options_button : Button = %Options
@onready var quit_button : Button = %Quit	

# Options Menu
@onready var options_menu : TabContainer = %OptionsMenu
@onready var video_back : Button = %VideoBack
@onready var screen_mode: OptionButton = %ScreenMode

func _ready() -> void:
    _connect_signals()
    hide_options_menu()
    visible = false 
    

func _connect_signals() -> void:
    
    # 連接信號
    if resume_button:
        resume_button.pressed.connect(hide_pause_menu)
        print("Resume button connected")
    if options_button:
        options_button.pressed.connect(show_options_menu)
        print("Options button connected")
    if quit_button:
        quit_button.pressed.connect(_on_quit_pressed)
        print("Quit button connected")
    
    if video_back:
        video_back.pressed.connect(hide_options_menu)
        print("Video back button connected")
    
    if screen_mode:
        screen_mode.item_selected.connect(_on_screen_mode_selected)
        print("Screen mode connected")
    
    if options_menu:
        options_menu.current_tab = 0

func _on_screen_mode_selected(index: int) -> void:
    print("Screen mode selected: ", index)
    match index:
        0:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        1:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        2:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_quit_pressed() -> void:
    GameManager.resume_game()
    LevelManager.unload_level()
    GameManager.set_game_state(GameManager.GameState.LEVEL_SELECT)

func show_pause_menu() -> void:
    if visible:
        return  # 已經顯示，不需要重複顯示
    
    # 先設置狀態，再顯示，避免 _input 衝突
    menu_state = MenuState.PAUSED
    show()
    await play_menu_animations(self, true, 0.05)
    GameManager.pause_game()
    pause_menu_shown.emit()
    
func hide_pause_menu() -> void:
    print("hide_pause_menu")
    GameManager.resume_game()
    await play_menu_animations(self, false, 0.1)
    hide()
    menu_state = MenuState.GAME
    pause_menu_hidden.emit()

func show_options_menu() -> void:
    print("show_options_menu")
    if buttons:
        buttons.hide()
    if options_menu:
        options_menu.show()
        await play_menu_animations(options_menu, true, 0.05)
    menu_state = MenuState.OPTIONS

func hide_options_menu() -> void:
    if options_menu:
        await play_menu_animations(options_menu, false, 0.05)
        options_menu.hide()
    if buttons:
        buttons.show()
    menu_state = MenuState.PAUSED

func _input(event: InputEvent) -> void:
    if not visible:
        return  # 只有在可見時才處理輸入
    if GameManager.current_state != GameManager.GameState.GAME_PLAY:
        return
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("Menu_Back"):
        get_viewport().set_input_as_handled()  # 標記輸入已處理，避免重複處理
        match menu_state:
            MenuState.PAUSED:
                await hide_pause_menu()
            MenuState.OPTIONS:
                await hide_options_menu()
            _:
                pass

func play_menu_animations(menu : Control, showing : bool, animation_time : float) -> void:
    if not menu:
        return
        
    var alpha : float = 1.0 if showing else 0.0
    var tween := create_tween()
    tween.tween_property(menu, "modulate:a", alpha, animation_time).set_ease(Tween.EASE_OUT)
    await tween.finished
