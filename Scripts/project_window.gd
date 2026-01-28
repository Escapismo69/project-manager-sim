extends Control

# --- ДАННЫЕ ---
var project: ProjectData
var selector_ref # Ссылка на окно выбора (придет из setup)
var current_target_role = "" # Запоминаем, кого выбираем ("BA", "DEV" или "QA")
var is_running = false

# --- ССЫЛКИ НА UI ---
@onready var title_label = $Panel/VBoxContainer/TitleLabel

# Полоски прогресса
@onready var ba_bar = $Panel/VBoxContainer/BA_Bar
@onready var dev_bar = $Panel/VBoxContainer/Dev_Bar
@onready var qa_bar = $Panel/VBoxContainer/QA_Bar

# Кнопки назначения (Убедись, что ты создал их в сцене и назвал именно так!)
@onready var assign_ba_btn = $Panel/AssignBA_Btn
@onready var assign_dev_btn = $Panel/AssignDev_Btn
@onready var assign_qa_btn = $Panel/AssignQA_Btn

@onready var close_btn = $Panel/CloseButton

# --- НАСТРОЙКА (ВЫЗЫВАЕТСЯ ИЗ СТОЛА) ---
# Обрати внимание: теперь тут два аргумента
func setup(data: ProjectData, selector_node):
	project = data
	selector_ref = selector_node # Запоминаем ссылку на селектор
	
	title_label.text = project.title
	
	# Настраиваем максимумы полосок
	ba_bar.max_value = project.ba_needed
	dev_bar.max_value = project.dev_needed
	qa_bar.max_value = project.qa_needed
	
	# Обнуляем текущие значения
	ba_bar.value = project.ba_progress
	dev_bar.value = project.dev_progress
	qa_bar.value = project.qa_progress
	
	# Подписываемся на сигнал выбора (если еще не подписаны)
	# Это значит: "Если селектор крикнет 'выбрали', запусти мою функцию _on_employee_chosen"
	if not selector_ref.employee_selected.is_connected(_on_employee_chosen):
		selector_ref.employee_selected.connect(_on_employee_chosen)
		
	# Обновляем текст на кнопках (вдруг там уже кто-то назначен)
	update_buttons()



func _ready():
	# Подключаем нажатие кнопки к функции закрытия
	close_btn.pressed.connect(_on_close_button_pressed)

# --- ВИЗУАЛ ---
func _process(delta):
	if project:
		ba_bar.value = project.ba_progress
		dev_bar.value = project.dev_progress
		qa_bar.value = project.qa_progress

# Обновляем надписи на кнопках
func update_buttons():
	if project.assignee_ba: assign_ba_btn.text = project.assignee_ba.employee_name
	else: assign_ba_btn.text = "+"
	
	if project.assignee_dev: assign_dev_btn.text = project.assignee_dev.employee_name
	else: assign_dev_btn.text = "+"
	
	if project.assignee_qa: assign_qa_btn.text = project.assignee_qa.employee_name
	else: assign_qa_btn.text = "+"

# --- ОБРАБОТКА НАЖАТИЙ НА КНОПКИ "+" ---
# Не забудь подключить сигналы pressed() от кнопок к этим функциям!

func _on_assign_ba_btn_pressed():
	current_target_role = "BA" # Запоминаем: сейчас ищем Аналитика
	selector_ref.open_list()   # Открываем окно выбора

func _on_assign_dev_btn_pressed():
	current_target_role = "DEV"
	selector_ref.open_list()

func _on_assign_qa_btn_pressed():
	current_target_role = "QA"
	selector_ref.open_list()

# --- КОГДА МЫ ВЫБРАЛИ ЧЕЛОВЕКА В СПИСКЕ ---
func _on_employee_chosen(emp_data):
	# Смотрим, кого мы хотели назначить, и записываем данные в проект
	match current_target_role:
		"BA": project.assignee_ba = emp_data
		"DEV": project.assignee_dev = emp_data
		"QA": project.assignee_qa = emp_data
	
	update_buttons() # Обновляем текст на кнопке

# --- ЛОГИКА СИМУЛЯЦИИ ---
func _on_start_button_pressed():
	print("Кнопка Старт нажата!")
	if project.current_stage == project.Stage.NOT_STARTED:
		project.current_stage = project.Stage.BA
	is_running = true

func _physics_process(delta):
	if not is_running or not project:
		return
		
	match project.current_stage:
		# ЭТАП 1: БИЗНЕС АНАЛИЗ
		project.Stage.BA:
			if project.assignee_ba:
				var speed = project.assignee_ba.skill_business_analysis * delta
				project.ba_progress += speed
				if project.ba_progress >= project.ba_needed:
					project.ba_progress = project.ba_needed
					project.current_stage = project.Stage.DEV
					print("BA Завершен! Начало Dev.")
			else:
				print("Ждем назначения аналитика...")
				is_running = false

		# ЭТАП 2: РАЗРАБОТКА
		project.Stage.DEV:
			if project.assignee_dev:
				var speed = project.assignee_dev.skill_backend * delta
				project.dev_progress += speed
				if project.dev_progress >= project.dev_needed:
					project.dev_progress = project.dev_needed
					project.current_stage = project.Stage.QA
					print("Dev Завершен! Начало QA.")
			else:
				print("Ждем назначения разработчика...")
				is_running = false

		# ЭТАП 3: ТЕСТИРОВАНИЕ
		project.Stage.QA:
			if project.assignee_qa:
				var speed = project.assignee_qa.skill_qa * delta
				project.qa_progress += speed
				if project.qa_progress >= project.qa_needed:
					project.qa_progress = project.qa_needed
					project.current_stage = project.Stage.FINISHED
					is_running = false
					print("ПРОЕКТ ГОТОВ!")
					GameState.change_balance(project.budget)
			else:
				print("Ждем назначения тестировщика...")
				is_running = false
				
func _on_close_button_pressed():
	visible = false # Просто прячем окно
	# is_running = false # (Опционально) Если хочешь, чтобы работа вставала на паузу, когда окно закрыто. Если не раскомментируешь — работа пойдет в фоне.
