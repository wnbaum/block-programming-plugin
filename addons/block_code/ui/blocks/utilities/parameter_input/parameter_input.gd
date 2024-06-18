@tool
class_name ParameterInput
extends MarginContainer

signal modified

@export var placeholder: String = "Parameter":
	set = _set_placeholder

@export var block_path: NodePath

@export var variant_type: Variant.Type = TYPE_STRING
@export var block_type: Types.BlockType = Types.BlockType.VALUE

var block: Block

@onready var _panel := %Panel
@onready var _line_edit := %LineEdit
@onready var snap_point := %SnapPoint
@onready var _input_switcher := %InputSwitcher
# Inputs
@onready var _text_input := %TextInput
@onready var _color_input := %ColorInput
@onready var _option_input := %OptionInput


func set_raw_input(raw_input):
	match variant_type:
		TYPE_COLOR:
			_color_input.color = raw_input
			_update_panel_bg_color(raw_input)

		#Types.BlockType.OPTION:
		#_panel.visible = false
		#_option_input.clear()
		#var option_data: Types.OptionData = raw_input as Types.OptionData
		#for item in option_data.items:
		#_option_input.add_item(item)
		#_option_input.select(option_data.selected)

		_:
			_line_edit.text = raw_input


func get_raw_input():
	match variant_type:
		TYPE_COLOR:
			return _color_input.color

		#Types.BlockType.OPTION:
		#var options: Array = []
		#for i in _option_input.item_count:
		#options.append(_option_input.get_item_text(i))
		#return Types.OptionData.new(options, _option_input.selected)

		_:
			return _line_edit.text


func _set_placeholder(new_placeholder: String) -> void:
	placeholder = new_placeholder

	if not is_node_ready():
		return

	_line_edit.placeholder_text = placeholder


func _ready():
	var stylebox = _panel.get_theme_stylebox("panel")
	stylebox.bg_color = Color.WHITE

	_set_placeholder(placeholder)

	if block == null:
		block = get_node_or_null(block_path)
	snap_point.block = block
	snap_point.block_type = block_type
	snap_point.variant_type = variant_type

	match variant_type:
		TYPE_COLOR:
			switch_input(_color_input)
		#Types.BlockType.OPTION:
		#switch_input(_option_input)
		_:
			switch_input(_text_input)

	# Do something with block_type to restrict input


func get_snapped_block() -> Block:
	return snap_point.get_snapped_block()


func get_string() -> String:
	var snapped_block: ParameterBlock = get_snapped_block() as ParameterBlock
	if snapped_block:
		var generated_string = snapped_block.get_parameter_string()
		if Types.can_cast(snapped_block.variant_type, variant_type):
			return Types.cast(generated_string, snapped_block.variant_type, variant_type)
		else:
			push_warning("No cast from %s to %s; using '%s' verbatim" % [snapped_block, variant_type, generated_string])
			return generated_string

	var input = get_raw_input()

	match variant_type:
		TYPE_STRING:
			return "'%s'" % input.replace("\\", "\\\\").replace("'", "\\'")
		TYPE_VECTOR2:
			return "Vector2(%s)" % input
		TYPE_COLOR:
			return "Color%s" % str(input)
		#Types.BlockType.OPTION:
		#return _option_input.get_item_text(_option_input.selected)
		_:
			return "%s" % input


func _on_line_edit_text_changed(new_text):
	modified.emit()


func switch_input(node: Node):
	for c in _input_switcher.get_children():
		c.visible = false

	node.visible = true


func _on_color_input_color_changed(color):
	_update_panel_bg_color(color)

	modified.emit()


func _update_panel_bg_color(new_color):
	var stylebox = _panel.get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = new_color
	_panel.add_theme_stylebox_override("panel", stylebox)


func _on_option_input_item_selected(index):
	modified.emit()
