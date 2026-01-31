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

# НОВАЯ КНОПКА (Убедись, что создал её в сцене!)
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
	
	# --- ИСПРАВЛЕНИЕ ТУТ ---
	# 1. Сначала полностью очищаем контейнер, чтобы индексы не сбились
	for child in tracks_container.get_children():
		tracks_container.remove_child(child) # Мгновенное удаление из дерева
		child.queue_free() # Очистка памяти
	
	# 2. Создаем новые дорожки
	for i in range(project.stages.size()):
		var stage = project.stages[i]
		var new_track = track_scene.instantiate()
		tracks_container.add_child(new_track)
		new_track.setup(i, stage)
		new_track.assignment_requested.connect(_on_track_assignment_requested)
	
	if not selector_ref.employee_selected.is_connected(_on_employee_chosen):
		selector_ref.employee_selected.connect(_on_employee_chosen)

	draw_timeline_header()
	
	# 3. Обновляем кнопки
	update_buttons_visibility()

	# 4. Рисуем график
	call_deferred("recalculate_schedule")

func _ready():
	# Логика кнопок
	cancel_btn.pressed.connect(_on_cancel_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	# Кнопка закрытия просто прячет окно
	close_window_btn.pressed.connect(func(): visible = false)

# Функция управления видимостью кнопок
func update_buttons_visibility():
	if project.state == ProjectData.State.IN_PROGRESS:
		# Если проект идет: Кнопки управления планом пропадают
		start_btn.visible = false
		cancel_btn.visible = false
		# Кнопка закрытия окна всегда доступна
		close_window_btn.visible = true
	else:
		# Если проект на стадии планирования
		start_btn.visible = true
		cancel_btn.visible = true
		close_window_btn.visible = true

func _on_start_pressed():
	# 1. Меняем состояние
	project.state = project.State.IN_PROGRESS
	print("Проект запущен! Окно остается открытым.")
	
	# 2. Обновляем кнопки (скрываем Старт/Отмена)
	update_buttons_visibility()
	
	# 3. Окно НЕ закрываем (visible = true остается)

func _on_cancel_pressed():
	# Логика отказа от проекта
	print("Отказ от проекта")
	visible = false
	# Тут можно добавить логику удаления проекта из активных

# --- ДАЛЕЕ СТАРЫЙ КОД БЕЗ ИЗМЕНЕНИЙ ---

func _process(delta):
	if not project: return
	for i in range(project.stages.size()):
		if i < tracks_container.get_child_count():
			var stage = project.stages[i]
			var track_node = tracks_container.get_child(i)
			var percent = 0.0
			if stage.amount > 0: percent = stage.progress / float(stage.amount)
			track_node.update_progress(percent)

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
			var speed_per_second = float(skill) / 60.0
			active_stage.progress += speed_per_second * delta

func get_employee_node(data: EmployeeData):
	if not data: return null
	var all_npcs = get_tree().get_nodes_in_group("npc")
	for npc in all_npcs:
		if npc.data == data:
			return npc
	return null

# --- ОБНОВЛЕННАЯ ФУНКЦИЯ ОТРИСОВКИ СЕТКИ ---
func draw_timeline_header():
	for child in timeline_header.get_children():
		child.queue_free()
	
	var pixels_per_day = WORK_HOURS_PER_DAY * PIXELS_PER_HOUR
	
	# ВАЖНО: Это ширина твоей левой колонки с именем сотрудника.
	# Посмотри в ProjectTrack.tscn -> InfoPanel -> Custom Minimum Size -> x
	# Оно должно совпадать точно! Если там 150, ставь тут 150.
	var left_margin = 155.0 
	
	var total_days_to_draw = 30 
	
	for i in range(total_days_to_draw): 
		var current_day_num = project.created_at_day + i
		
		# --- МЕТКА (Рисуем цифру только каждый 2-й день, чтобы не было тесно) ---
		# Если i делится на 2 без остатка (0, 2, 4...)
		if i % 2 == 0:
			var lbl = Label.new()
			lbl.text = str(current_day_num)
			lbl.modulate = Color(1, 1, 1, 0.5)
			# Шрифт можно сделать поменьше через LabelSettings, но пока так
			
			# Центруем цифру внутри дня (сдвигаем чуть правее от начала дня)
			lbl.position = Vector2(left_margin + i * pixels_per_day + 2, 0)
			timeline_header.add_child(lbl)
		
		# --- ЛИНИЯ ---
		var line = ColorRect.new()
		line.color = Color(0.39, 0.58, 0.93, 0.2) 
		line.size = Vector2(1, 2000) # Тонкая линия (1px) вниз
		
		line.position = Vector2(left_margin + i * pixels_per_day, 15)
		line.z_index = 1 
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timeline_header.add_child(line)

func _on_track_assignment_requested(index):
	# Запрещаем менять людей, если проект уже идет!
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

func recalculate_schedule():
	var current_time_offset_hours = 0.0 
	var total_salary_cost = 0.0
	var all_assigned = true
	
	for i in range(project.stages.size()):
		var stage = project.stages[i]
		var track_node = tracks_container.get_child(i)
		
		# Если работник назначен
		if stage.worker:
			var skill = get_skill_for_stage(stage.type, stage.worker)
			if skill < 1: skill = 1 
			var duration_hours = float(stage.amount) / float(skill)
			
			var start_px = current_time_offset_hours * PIXELS_PER_HOUR
			var width_px = duration_hours * PIXELS_PER_HOUR
			var color = get_color_for_stage(stage.type)
			
			# РИСУЕМ ПОЛОСКУ (ПЛАН)
			track_node.update_bar(start_px, width_px, color)
			
			# ОБНОВЛЯЕМ ПРОГРЕСС (ФАКТ) - Чтобы при перезаходе видно было зеленую часть
			var percent = 0.0
			if stage.amount > 0: percent = stage.progress / float(stage.amount)
			track_node.update_progress(percent)
			
			var hourly_rate = 20 
			total_salary_cost += duration_hours * hourly_rate
			current_time_offset_hours += duration_hours
		else:
			all_assigned = false
			track_node.update_bar(0, 0, Color.WHITE)
	
	cost_label.text = "Расходы: $%d" % int(total_salary_cost)
	var profit = project.budget - total_salary_cost
	profit_label.text = "Прибыль: $%d" % int(profit)
	profit_label.modulate = Color.RED if profit < 0 else Color.GREEN
	
	# Кнопку старт блокируем только если это планирование
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
