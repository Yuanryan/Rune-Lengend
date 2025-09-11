# 🎮 Complete UI Setup Guide

This guide shows you how to create a complete UI scene that integrates all the card components.

## 📋 **Step-by-Step Scene Creation**

### **Step 1: Create the Main UI Scene**

1. **Create a new scene** in Godot:
   - Right-click in FileSystem → "New Scene"
   - Choose "2D Scene"
   - Save as `Scenes/complete_ui.tscn`

2. **Set up the root node**:
   - Rename the root node to `CompleteUI`
   - Add a script: `Scripts/UI/example_usage.gd`
   - Set the node type to `CanvasLayer`

### **Step 2: Create the Scene Structure**

```
CompleteUI (CanvasLayer)
└── MainContainer (VBoxContainer)
    ├── TopPanel (PanelContainer) - Card Palette Area
    │   └── TopMargin (MarginContainer)
    │       └── TopContent (VBoxContainer)
    │           ├── TitleLabel (Label) - "Action Cards"
    │           └── CardPalette (HBoxContainer) - Your action cards
    └── BottomPanel (PanelContainer) - Action Queue Area
        └── BottomMargin (MarginContainer)
            └── BottomContent (VBoxContainer)
                ├── QueueLabel (Label) - "Action Queue"
                ├── ActionQueue (HBoxContainer) - Dragged cards
                ├── ControlButtons (HBoxContainer)
                │   ├── ExecuteButton (Button) - "Execute Sequence"
                │   └── ClearButton (Button) - "Clear Queue"
                └── InfoLabel (Label) - Instructions/status
```

### **Step 3: Configure Each Component**

#### **MainContainer (VBoxContainer)**
- **Anchors**: Full Rect (0,0,1,1)
- **Size Flags**: Both Expand Fill

#### **TopPanel (PanelContainer)**
- **Size Flags Vertical**: Expand Fill
- **Theme Override Styles → Panel**: Custom StyleBoxFlat
  - Background Color: `Color(0.2, 0.2, 0.3, 0.8)`
  - Corner Radius: 10

#### **CardPalette (HBoxContainer)**
- **Size Flags Vertical**: Expand Fill
- **Separation**: 15
- **Alignment**: Center
- **Script**: `Scripts/UI/card_palette.gd`

#### **BottomPanel (PanelContainer)**
- **Size Flags Vertical**: Shrink End
- **Theme Override Styles → Panel**: Custom StyleBoxFlat
  - Background Color: `Color(0.1, 0.1, 0.2, 0.9)`
  - Corner Radius: 10

#### **ActionQueue (HBoxContainer)**
- **Size Flags Vertical**: Expand Fill
- **Separation**: 10
- **Alignment**: Center
- **Script**: `Scripts/UI/card_queue.gd`

### **Step 4: Connect the Scripts**

1. **Attach the main script**:
   - Select `CompleteUI` node
   - In Inspector → Script → Load `Scripts/UI/example_usage.gd`

2. **Assign the @export variables**:
   - `card_palette`: Drag the CardPalette node
   - `action_queue`: Drag the ActionQueue node
   - `execute_button`: Drag the ExecuteButton node
   - `clear_button`: Drag the ClearButton node
   - `info_label`: Drag the InfoLabel node
   - `player`: Leave empty (will be set in main scene)

### **Step 5: Style the UI (Optional)**

#### **Add Custom Themes**:
```gdscript
# In your theme resource or in code
var button_style = StyleBoxFlat.new()
button_style.bg_color = Color(0.3, 0.5, 0.8, 1.0)
button_style.corner_radius_top_left = 5
button_style.corner_radius_top_right = 5
button_style.corner_radius_bottom_left = 5
button_style.corner_radius_bottom_right = 5

execute_button.add_theme_stylebox_override("normal", button_style)
clear_button.add_theme_stylebox_override("normal", button_style)
```

## 🔗 **Integration with Main Scene**

### **Step 6: Add to Main Scene**

1. **Open your main scene** (`Scenes/main.tscn`)

2. **Instance the UI scene**:
   - Drag `Scenes/complete_ui.tscn` into your main scene
   - Position it as a child of the root node

3. **Connect the player**:
   ```gdscript
   # In your main scene script
   func _ready():
       var ui = get_node("CompleteUI")
       var player = get_node("Player")
       ui.set_player(player)
   ```

## 🎯 **How It Works**

### **User Flow**:
1. **Cards appear** in the top panel (CardPalette)
2. **Player drags** cards from palette to queue
3. **Cards show** in the bottom panel (ActionQueue)
4. **Player clicks** "Execute Sequence" to run actions
5. **Player clicks** "Clear Queue" to reset

### **Visual Feedback**:
- **Empty queue**: "Drag cards from above to build your action sequence"
- **With actions**: "Ready to execute X actions"
- **Buttons disabled** when no actions in queue
- **Error messages** appear in red for 2 seconds

### **Automatic Features**:
- **Auto-loads** your existing `.tres` files
- **Auto-connects** all signals
- **Auto-updates** UI state
- **Auto-finds** components if not assigned

## 🚀 **Quick Start**

1. **Use the provided scene**: `Scenes/complete_ui.tscn`
2. **Add to main scene**: Instance the complete_ui scene
3. **Connect player**: Call `ui.set_player(your_player_node)`
4. **Done!** Your card system is ready to use

## 🎨 **Customization**

### **Change Colors**:
- Edit the StyleBoxFlat resources in the scene
- Or modify colors in the script

### **Add More Cards**:
- Add more `.tres` files to `Resources/Actions/`
- They'll automatically appear in the palette

### **Change Layout**:
- Modify the VBoxContainer/HBoxContainer settings
- Adjust margins and spacing as needed

The system is designed to be modular and easy to customize!
