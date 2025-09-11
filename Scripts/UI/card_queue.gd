# UI/QueuePanel.gd
extends HBoxContainer
class_name QueuePanel

var planned_actions: Array[Action] = []

func can_drop_data(at_position, data):
    return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "card"

func drop_data(at_position, data):
    var card: Card = data["card"]
    if card and card.action:
        planned_actions.append(card.action.duplicate())  # 佇列用副本
        _add_row(card.get_label())

func _add_row(text: String):
    var h = HBoxContainer.new()
    var lbl = Label.new()
    lbl.text = text
    h.add_child(lbl)
    var del_btn = Button.new()
    del_btn.text = "X"
    del_btn.pressed.connect(func():
        var idx = get_children().find(h)
        if idx >= 0:
            planned_actions.remove_at(idx)
            h.queue_free()
    )
    h.add_child(del_btn)
    add_child(h)

func clear_queue():
    planned_actions.clear()
    for c in get_children():
        c.queue_free()
