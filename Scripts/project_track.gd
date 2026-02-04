extends Control

signal assignment_requested(track_index)

# --- ССЫЛКИ НА UI ---
@onready var role_label = $Layout/RoleLabel
# Убедись, что путь к кнопке правильный (мы добавляли Wrapper!)
@onready var assign_btn = $Layout/AssignWrapper/AssignButton
@onready var progress_label = $Layout/ProgressLabel

# ОБНОВЛЕННЫЕ ПУТИ (Они теперь соседи внутри GanttArea)
@onready var visual_bar = $Layout/GanttArea/VisualBar
@onready var progress_bar = $Layout/GanttArea/ProgressBar

const BAR_HEIGHT = 24.0 

var stage_index: int = -1
var stage_data: Dictionary = {}

# ВОТ ОНА - ФУНКЦИЯ SETUP. ОНА ДОЛЖНА БЫТЬ ЗДЕСЬ!
func setup(index: int, data: Dictionary):
	stage_index = index
	stage_data = data
	
	# Заполняем тексты
	role_label.text = data.type
	progress_label.text = "%d / %d" % [int(data.progress), int(data.amount)]
	
	update_button_visuals()
	
	# Скрываем полоски до расчета
	visual_bar.visible = false
	progress_bar.visible = false

func update_button_visuals():
	if stage_data.worker:
		assign_btn.text = stage_data.worker.employee_name
		assign_btn.modulate = Color(0.8, 0.9, 1.0) 
	else:
		assign_btn.text = "+ Назначить"
		assign_btn.modulate = Color.WHITE

func update_bar(start_offset_px: float, width_px: float, color: Color):
	if not stage_data.worker:
		visual_bar.visible = false
		progress_bar.visible = false
		return
		
	visual_bar.visible = true
	
	# --- НАСТРОЙКА СИНЕЙ (ПЛАН) ---
	var style = visual_bar.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
		style.bg_color = color
		visual_bar.add_theme_stylebox_override("panel", style)
	
	visual_bar.position.x = start_offset_px
	visual_bar.size.x = width_px
	visual_bar.size.y = BAR_HEIGHT
	visual_bar.position.y = (size.y - BAR_HEIGHT) / 2.0
	
	# --- НАСТРОЙКА ЗЕЛЕНОЙ (ФАКТ) ---
	progress_bar.visible = true
	progress_bar.position.y = visual_bar.position.y
	progress_bar.position.x = visual_bar.position.x
	progress_bar.size.y = BAR_HEIGHT

func update_progress(percent: float):
	if percent < 0: percent = 0.0
	
	# Зеленая полоска
	progress_bar.size.x = visual_bar.size.x * percent
	
	var current_val = int(stage_data.amount * percent)
	progress_label.text = "%d / %d" % [current_val, stage_data.amount]
	
	if percent >= 1.0:
		progress_label.modulate = Color.GREEN
	else:
		progress_label.modulate = Color("d93636")

func _ready():
	assign_btn.pressed.connect(func(): emit_signal("assignment_requested", stage_index))
