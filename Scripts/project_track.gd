extends Control

signal assignment_requested(track_index)

@onready var label = $HBoxContainer/InfoPanel/StageNameLabel
@onready var assign_btn = $HBoxContainer/InfoPanel/AssignButton
@onready var visual_bar = $HBoxContainer/GanttArea/VisualBar
# Ссылка на нашу новую зеленую полоску (проверь имя узла!)
@onready var progress_bar = $HBoxContainer/GanttArea/VisualBar/ProgressBar

var stage_index: int = -1
var stage_data: Dictionary = {}

func setup(index: int, data: Dictionary):
	stage_index = index
	stage_data = data
	label.text = "%s (%d)" % [data.type, data.amount]
	update_button_visuals()
	visual_bar.visible = false

func update_button_visuals():
	if stage_data.worker:
		assign_btn.text = stage_data.worker.employee_name
	else:
		assign_btn.text = "+ Назначить"

func update_bar(start_offset_px: float, width_px: float, color: Color):
	if not stage_data.worker:
		visual_bar.visible = false
		return
		
	visual_bar.visible = true
	visual_bar.color = color
	visual_bar.position.x = start_offset_px
	visual_bar.custom_minimum_size.x = width_px
	visual_bar.size.x = width_px 

# --- НОВАЯ ФУНКЦИЯ ---
func update_progress(percent: float):
	# Ограничиваем процент от 0.0 до 1.0
	percent = clamp(percent, 0.0, 1.0)
	
	# Зеленая полоска занимает % от ширины синей полоски
	progress_bar.size.x = visual_bar.size.x * percent

func _ready():
	assign_btn.pressed.connect(func(): emit_signal("assignment_requested", stage_index))
