extends Node2D

# Ссылка на сцену сотрудника (наш шаблон)
# Мы загружаем его заранее, чтобы копировать
var employee_scene = preload("res://Scenes/Employee.tscn")

# Точка, вокруг которой будут появляться люди
@onready var spawn_point = $SpawnPoint

func _ready():
	# Пока пусто. Потом здесь будем удалять Васю и Лену при старте, если нужно.
	pass

# Эту функцию будет вызывать UI Найма
func spawn_new_employee(data: EmployeeData):
	# 1. Создаем копию человечка
	var new_npc = employee_scene.instantiate()
	
	# 2. Добавляем его в сцену (как ребенка Офиса)
	add_child(new_npc)
	
	# 3. Настраиваем данные (имя, роль, цвет)
	new_npc.setup_employee(data)
	
	# 4. РАССЧИТЫВАЕМ ПОЗИЦИЮ (Чтобы не слипались)
	# Берем координаты маркера + случайное смещение +- 50 пикселей
	var random_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	new_npc.global_position = spawn_point.global_position + random_offset
	
	print("Заспавнен сотрудник: ", data.employee_name)
	
