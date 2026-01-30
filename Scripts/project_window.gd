extends Control

# --- ДАННЫЕ ---
var project: ProjectData
var selector_ref 
var current_target_role = "" 
var is_running = false

# --- ССЫЛКИ НА UI ---
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var ba_bar = $Panel/VBoxContainer/BA_Bar
@onready var dev_bar = $Panel/VBoxContainer/Dev_Bar
@onready var qa_bar = $Panel/VBoxContainer/QA_Bar
@onready var assign_ba_btn = $Panel/AssignBA_Btn
@onready var assign_dev_btn = $Panel/AssignDev_Btn
@onready var assign_qa_btn = $Panel/AssignQA_Btn
@onready var close_btn = $Panel/CloseButton

func setup(data: ProjectData, selector_node):
	project = data
	selector_ref = selector_node
	
	title_label.text = project.title
	ba_bar.max_value = project.ba_needed
	dev_bar.max_value = project.dev_needed
	qa_bar.max_value = project.qa_needed
	ba_bar.value = project.ba_progress
	dev_bar.value = project.dev_progress
	qa_bar.value = project.qa_progress
	
	if not selector_ref.employee_selected.is_connected(_on_employee_chosen):
		selector_ref.employee_selected.connect(_on_employee_chosen)
		
	update_buttons()

func _ready():
	close_btn.pressed.connect(_on_close_button_pressed)

func _process(delta):
	if project:
		ba_bar.value = project.ba_progress
		dev_bar.value = project.dev_progress
		qa_bar.value = project.qa_progress

func update_buttons():
	if project.assignee_ba: assign_ba_btn.text = project.assignee_ba.employee_name
	else: assign_ba_btn.text = "+"
	
	if project.assignee_dev: assign_dev_btn.text = project.assignee_dev.employee_name
	else: assign_dev_btn.text = "+"
	
	if project.assignee_qa: assign_qa_btn.text = project.assignee_qa.employee_name
	else: assign_qa_btn.text = "+"

func _on_assign_ba_btn_pressed():
	current_target_role = "BA" 
	selector_ref.open_list()

func _on_assign_dev_btn_pressed():
	current_target_role = "DEV"
	selector_ref.open_list()

func _on_assign_qa_btn_pressed():
	current_target_role = "QA"
	selector_ref.open_list()

func _on_employee_chosen(emp_data):
	match current_target_role:
		"BA": project.assignee_ba = emp_data
		"DEV": project.assignee_dev = emp_data
		"QA": project.assignee_qa = emp_data
	update_buttons()

func _on_start_button_pressed():
	print("Кнопка Старт нажата!")
	if project.current_stage == project.Stage.NOT_STARTED:
		project.current_stage = project.Stage.BA
	is_running = true

func _on_close_button_pressed():
	visible = false

# --- [NEW] ГЛАВНАЯ ЛОГИКА ---

# Вспомогательная функция: Находит Node сотрудника по его Data
# Нам это нужно, чтобы узнать State (Working/Idle)
func get_employee_node(data: EmployeeData):
	if not data: return null
	# Ищем среди всех NPC в игре
	var all_npcs = get_tree().get_nodes_in_group("npc")
	for npc in all_npcs:
		if npc.data == data:
			return npc
	return null

func _physics_process(delta):
	if not is_running or not project:
		return
		
	match project.current_stage:
		# ЭТАП 1: БИЗНЕС АНАЛИЗ
		project.Stage.BA:
			if project.assignee_ba:
				# 1. Ищем физическое тело сотрудника
				var worker = get_employee_node(project.assignee_ba)
				
				# 2. Проверяем: он существует? Он работает (сидит)?
				# worker.State.WORKING берем из его скрипта
				if worker and worker.current_state == worker.State.WORKING:
					
					# 3. Новая формула: Скилл / 60 секунд
					var speed_per_second = project.assignee_ba.skill_business_analysis / 60.0
					project.ba_progress += speed_per_second * delta
					
				# Если он идет (MOVING) или стоит (IDLE) - прогресс просто не идет.
				
				if project.ba_progress >= project.ba_needed:
					project.ba_progress = project.ba_needed
					project.current_stage = project.Stage.DEV
					print("BA Завершен! Начало Dev.")
			else:
				# Если никого не назначили вообще - вот тогда стоп
				is_running = false

		# ЭТАП 2: РАЗРАБОТКА
		project.Stage.DEV:
			if project.assignee_dev:
				var worker = get_employee_node(project.assignee_dev)
				
				if worker and worker.current_state == worker.State.WORKING:
					var speed_per_second = project.assignee_ba.skill_backend / 60.0
					project.dev_progress += speed_per_second * delta
				
				if project.dev_progress >= project.dev_needed:
					project.dev_progress = project.dev_needed
					project.current_stage = project.Stage.QA
					print("Dev Завершен! Начало QA.")
			else:
				is_running = false

		# ЭТАП 3: ТЕСТИРОВАНИЕ
		project.Stage.QA:
			if project.assignee_qa:
				var worker = get_employee_node(project.assignee_qa)
				
				if worker and worker.current_state == worker.State.WORKING:
					var speed_per_second = project.assignee_ba.skill_qa / 60.0
					project.qa_progress += speed_per_second * delta
					
				if project.qa_progress >= project.qa_needed:
					project.qa_progress = project.qa_needed
					project.current_stage = project.Stage.FINISHED
					is_running = false
					print("ПРОЕКТ ГОТОВ!")
					GameState.change_balance(project.budget)
			else:
				is_running = false
