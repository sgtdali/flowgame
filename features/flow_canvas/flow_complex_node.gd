class_name FlowComplexNode
extends GraphNode

signal open_requested(complex_id: int)

var complex_id: int = -1
var _title: Label
var _summary: Label


func setup(p_complex_id: int, display_name: String, machine_count: int) -> void:
	complex_id = p_complex_id
	name = "complex_%d" % complex_id
	_title = Label.new()
	_title.text = display_name
	_title.add_theme_font_size_override(&"font_size", 16)
	add_child(_title)
	_summary = Label.new()
	_summary.add_theme_color_override(&"font_color", Color(0.75, 0.63, 0.42))
	add_child(_summary)
	var open := Button.new()
	open.text = "Open Complex"
	open.pressed.connect(func() -> void: open_requested.emit(complex_id))
	add_child(open)
	refresh(machine_count, "Running")


func refresh(machine_count: int, status: String) -> void:
	if _summary != null:
		_summary.text = "Industrial Complex  •  %d machines  •  %s" % [machine_count, status]
