extends Control

# --- ССЫЛКИ НА UI ---
@onready var title_label = $Panel/VBoxContainer/HeaderInfo/TitleLabel
@onready var deadline_label = $Panel/VBoxContainer/HeaderInfo/DeadlineLabel
@onready var budget_label = $Panel/VBoxContainer/HeaderInfo/BudgetLabel
@onready var tracks_container = $Panel/VBoxContainer/TracksContainer
@onready var cost_label = $Panel/VBoxContainer/Footer/CostLabel
@onready var profit_label = $Panel/VBoxContainer/Footer/ProfitLabel
@onready var start_btn = $Panel/VBoxContainer/Footer/StartButton
@onready var cancel_btn = $Panel/VBoxContainer/Footer/CancelButton
@onready var timeline_header = $Panel/VBoxContainer/TimelineHeader
@onready var close_window_btn = $Panel/CloseWindowButton 

@export var track_scene: PackedScene 

# --- ДАННЫЕ ---
var project: ProjectData
var selector_ref
var current_selecting_track_index: int = -1

const PIXELS_PER_HOUR = 3.0 
const WORK_HOURS_PER_DAY = 9.0

func setup(data: ProjectData, selector_node):
	project = data
	selector_ref = selector_node
	
	title_label.text = project.title
	budget_label.text = "Бюджет: $%d" % project.budget
	deadline_label.text = "Дедлайн: День %d" % project.deadline_day
	
	for child in tracks_container.get_children():
		tracks_container.remove_child(child)
		child.queue_free() 
	
	for i in range(project.stages.size()):
		var stage = project.stages[i]
		var new_track = track_scene.instantiate()
		tracks_container.add_child(new_track)
		new_track.setup(i, stage)
		new_track.assignment_requested.connect(_on_track_assignment_requested)
	
	if not selector_ref.employee_selected.is_connected(_on_employee_chosen):
		selector_ref.employee_selected.connect(_on_employee_chosen)

	draw_timeline_header()
	update_buttons_visibility()
	call_deferred("recalculate_schedule")

func _ready():
	cancel_btn.pressed.connect(_on_cancel_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	close_window_btn.pressed.connect(func(): visible = false)

func update_buttons_visibility():
	if project.state == ProjectData.State.IN_PROGRESS:
		start_btn.visible = false
		cancel_btn.visible = false
		close_window_btn.visible = true
	else:
		start_btn.visible = true
		cancel_btn.visible = true
		close_window_btn.visible = true

func _on_start_pressed():
	project.state = project.State.IN_PROGRESS
	print("Проект запущен! Окно остается открытым.")
	update_buttons_visibility()

func _on_cancel_pressed():
	print("Отказ от проекта")
	visible = false

# --- ВИЗУАЛИЗАЦИЯ ПРОГРЕССА ---
func _process(delta):
	if not project: return
	for i in range(project.stages.size()):
		if i < tracks_container.get_child_count():
			var stage = project.stages[i]
			var track_node = tracks_container.get_child(i)
			var percent = 0.0
			if stage.amount > 0: percent = stage.progress / float(stage.amount)
			track_node.update_progress(percent)

# --- РЕАЛЬНАЯ РАБОТА (Зависит от усталости) ---
func _physics_process(delta):
	if not project or project.state != ProjectData.State.IN_PROGRESS:
		return
	
	var active_stage = null
	for stage in project.stages:
		if stage.progress < stage.amount:
			active_stage = stage
			break
	
	if active_stage == null:
		print("ПРОЕКТ ЗАВЕРШЕН!")
		project.state = ProjectData.State.FINISHED
		GameState.change_balance(project.budget)
		visible = false
		return

	if active_stage.worker:
		var worker_node = get_employee_node(active_stage.worker)
		if worker_node and worker_node.current_state == worker_node.State.WORKING:
			var skill = get_skill_for_stage(active_stage.type, active_stage.worker)
			
			# ТУТ ОСТАВЛЯЕМ УЧЕТ ЭНЕРГИИ
			# Зеленая полоска будет ползти медленнее, если он устал
			var efficiency = active_stage.worker.get_efficiency_multiplier()
			var speed_per_second = (float(skill) * efficiency) / 60.0
			
			active_stage.progress += speed_per_second * delta

func get_employee_node(data: EmployeeData):
	if not data: return null
	var all_npcs = get_tree().get_nodes_in_group("npc")
	for npc in all_npcs:
		if npc.data == data:
			return npc
	return null

func draw_timeline_header():
	for child in timeline_header.get_children():
		child.queue_free()
	
	var pixels_per_day = WORK_HOURS_PER_DAY * PIXELS_PER_HOUR
	var left_margin = 150.0 
	var total_days_to_draw = 30 
	
	for i in range(total_days_to_draw): 
		var current_day_num = project.created_at_day + i
		if i % 2 == 0:
			var lbl = Label.new()
			lbl.text = str(current_day_num)
			lbl.modulate = Color(1, 1, 1, 0.5)
			lbl.position = Vector2(left_margin + i * pixels_per_day + 2, 0)
			timeline_header.add_child(lbl)
		
		var line = ColorRect.new()
		line.color = Color(0.39, 0.58, 0.93, 0.2) 
		line.size = Vector2(1, 2000)
		line.position = Vector2(left_margin + i * pixels_per_day, 15)
		line.z_index = 1 
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timeline_header.add_child(line)

func _on_track_assignment_requested(index):
	if project.state == ProjectData.State.IN_PROGRESS:
		print("Нельзя менять коней на переправе!")
		return
	current_selecting_track_index = index
	selector_ref.open_list()

func _on_employee_chosen(emp_data):
	if current_selecting_track_index != -1:
		project.stages[current_selecting_track_index].worker = emp_data
		var track_node = tracks_container.get_child(current_selecting_track_index)
		track_node.update_button_visuals()
		recalculate_schedule()

# --- РАСЧЕТ ПЛАНА (Идеальный, не зависит от усталости) ---
func recalculate_schedule():
	var current_time_offset_hours = 0.0 
	var total_salary_cost = 0.0
	var all_assigned = true
	
	for i in range(project.stages.size()):
		var stage = project.stages[i]
		var track_node = tracks_container.get_child(i)
		
		if stage.worker:
			var skill = get_skill_for_stage(stage.type, stage.worker)
			
			# --- ВОТ ТУТ ИСПРАВИЛ ---
			# Мы НЕ умножаем на эффективность. План всегда идеальный (100%).
			# Если сотрудник устанет, зеленая полоска просто будет отставать от синей.
			if skill < 1: skill = 1
			var duration_hours = float(stage.amount) / float(skill)
			
			var start_px = current_time_offset_hours * PIXELS_PER_HOUR
			var width_px = duration_hours * PIXELS_PER_HOUR
			var color = get_color_for_stage(stage.type)
			
			track_node.update_bar(start_px, width_px, color)
			
			var percent = 0.0
			if stage.amount > 0: percent = stage.progress / float(stage.amount)
			track_node.update_progress(percent)
			
			var rate = stage.worker.hourly_rate 
			total_salary_cost += duration_hours * rate
			
			current_time_offset_hours += duration_hours
		else:
			all_assigned = false
			track_node.update_bar(0, 0, Color.WHITE)
	
	cost_label.text = "Расходы: $%d" % int(total_salary_cost)
	var profit = project.budget - total_salary_cost
	profit_label.text = "Прибыль: $%d" % int(profit)
	profit_label.modulate = Color.RED if profit < 0 else Color.GREEN
	
	if project.state == ProjectData.State.DRAFTING:
		start_btn.disabled = not all_assigned

func get_skill_for_stage(type, worker):
	match type:
		"BA": return worker.skill_business_analysis
		"DEV": return worker.skill_backend
		"QA": return worker.skill_qa
	return 10

func get_color_for_stage(type):
	match type:
		"BA": return Color.ORANGE
		"DEV": return Color.CORNFLOWER_BLUE
		"QA": return Color.PALE_GREEN
	return Color.GRAY
