extends CharacterBody2D

@export var data: EmployeeData

# Новые ссылки на части тела
@onready var body_sprite = $Visuals/Body
@onready var head_sprite = $Visuals/Body/Head

func _ready():
	add_to_group("npc")
	start_breathing_animation()
	if data:
		update_visuals()
		

func start_breathing_animation():
	if not body_sprite: return
	
	# Создаем Tween (это встроенный аниматор Godot)
	var tween = create_tween()
	
	# Говорим ему: "Повторяй бесконечно"
	tween.set_loops()
	
	# Рандомная задержка старта, чтобы все сотрудники не дышали синхронно как роботы
	tween.tween_interval(randf_range(0.0, 1.0))
	
	# ВДОХ: Чуть вытягиваемся вверх (Scale Y > 1, Scale X < 1)
	# Время: 1.5 секунды. Переход: Sine (плавный)
	tween.tween_property(body_sprite, "scale", Vector2(0.98, 1.02), 1.5).set_trans(Tween.TRANS_SINE)
	
	# ВЫДОХ: Чуть сплющиваемся (Scale Y < 1, Scale X > 1)
	tween.tween_property(body_sprite, "scale", Vector2(1.02, 0.98), 1.5).set_trans(Tween.TRANS_SINE)

func setup_employee(new_data: EmployeeData):
	data = new_data
	update_visuals()

func update_visuals():
	# Если спрайты еще не загрузились - выходим
	if not body_sprite or not head_sprite: return
	
	# Красим ТОЛЬКО одежду (тело) в зависимости от роли
	# Голову оставляем как есть (цвет кожи)
	if data.job_title == "Backend Developer":
		body_sprite.self_modulate = Color(0.4, 0.4, 1.0) # Синий пиджак
	elif data.job_title == "Business Analyst":
		body_sprite.self_modulate = Color(1.0, 0.4, 0.4) # Красный пиджак
	elif data.job_title == "QA Engineer":
		body_sprite.self_modulate = Color(0.4, 1.0, 0.4) # Зеленый пиджак
	else:
		body_sprite.modulate = Color.WHITE

func interact():
	var hud = get_tree().get_first_node_in_group("ui")
	if hud and data:
		hud.show_employee_card(data)
		
