extends CharacterBody2D

# --- СОСТОЯНИЯ ---
enum State {
	IDLE,       # Стоит (не работает)
	MOVING,     # Идет к цели (не работает)
	WORKING     # Сидит за столом (РАБОТАЕТ)
}

var current_state = State.IDLE
var movement_target_position: Vector2 = Vector2.ZERO
var movement_speed = 100.0 # Скорость ходьбы

# Данные
@export var data: EmployeeData

# Ссылки
@onready var body_sprite = $Visuals/Body
@onready var head_sprite = $Visuals/Body/Head
@onready var nav_agent = $NavigationAgent2D # Наш GPS
@onready var debug_label = $DebugLabel
func _ready():
	add_to_group("npc")
	start_breathing_animation()
	
	# Настройка навигатора: отключаем лишнее, чтобы не тормозил
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	
	if data:
		update_visuals()

func _physics_process(delta):
	# Логика зависит от состояния
	update_debug_label()
	match current_state:
		State.IDLE:
			pass # Просто стоим
			
		State.WORKING:
			pass # Просто сидим (анимация работы будет тут)
			
		State.MOVING:
			# 1. Считаем реальное расстояние от тела до точки назначения (по прямой)
			# target_position мы задали в функции move_to_desk
			var dist = global_position.distance_to(nav_agent.target_position)
			
			# 2. ПРОВЕРКА ПРИБЫТИЯ
			# Если мы подошли ближе чем на 50 пикселей (размер тела работника) - садимся.
			# Даже если мы уперлись в стол, 50 пикселей должно хватить, чтобы засчитать прибытие.
			if dist < 100.0:
				_on_navigation_finished()
				return

			# 3. Если еще далеко - идем
			var next_path_position = nav_agent.get_next_path_position()
			var new_velocity = global_position.direction_to(next_path_position) * movement_speed
			
			# Важный фикс: если next_path_position внутри стола,
			# вектор может сойти с ума. Но move_and_slide справится.
			velocity = new_velocity
			move_and_slide()
# --- ФУНКЦИИ УПРАВЛЕНИЯ ---
	

# Команда: "Иди к столу!"
func move_to_desk(target_point: Vector2):
	current_state = State.MOVING
	
	# Возвращаем в нормальный слой (если сидел)
	z_index = 0 
	
	# Задаем цель навигатору
	nav_agent.target_position = target_point

# Когда дошел
func _on_navigation_finished():
	print("Сотрудник прибыл к столу. Садимся...")
	
	# --- САМОЕ ГЛАВНОЕ: ТЕЛЕПОРТАЦИЯ ---
	# Мы жестко ставим его в ту точку, куда он пытался дойти.
	# nav_agent.target_position хранит координаты, которые мы задали при старте.
	global_position = nav_agent.target_position
	
	# Меняем состояние
	current_state = State.WORKING
	
	# Прячем ноги за стол
	z_index = -1
	
	# Гасим инерцию
	velocity = Vector2.ZERO

# --- ВИЗУАЛ И ПРОЧЕЕ (Оставляем твой код) ---
func start_breathing_animation():
	if not body_sprite: return
	var tween = create_tween()
	tween.set_loops()
	tween.tween_interval(randf_range(0.0, 1.0))
	tween.tween_property(body_sprite, "scale", Vector2(0.98, 1.02), 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(body_sprite, "scale", Vector2(1.02, 0.98), 1.5).set_trans(Tween.TRANS_SINE)

func setup_employee(new_data: EmployeeData):
	data = new_data
	update_visuals()

func update_visuals():
	if not body_sprite: return
	if data.job_title == "Backend Developer":
		body_sprite.self_modulate = Color(0.4, 0.4, 1.0)
	elif data.job_title == "Business Analyst":
		body_sprite.self_modulate = Color(1.0, 0.4, 0.4)
	elif data.job_title == "QA Engineer":
		body_sprite.self_modulate = Color(0.4, 1.0, 0.4)
	else:
		body_sprite.self_modulate = Color.WHITE

func interact():
	var hud = get_tree().get_first_node_in_group("ui")
	if hud and data:
		hud.show_employee_card(data)
func update_debug_label():
	if debug_label:
		# State.keys() возвращает массив ["IDLE", "MOVING", "WORKING"]
		# Мы берем слово по индексу текущего состояния
		var state_name = State.keys()[current_state]
		debug_label.text = state_name
		# (Опционально) Меняем цвет текста для наглядности
		match current_state:
			State.IDLE:
				debug_label.modulate = Color.WHITE
			State.MOVING:
				debug_label.modulate = Color.YELLOW
			State.WORKING:
				debug_label.modulate = Color.GREEN
