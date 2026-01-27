extends CharacterBody2D

# Мы создаем пустой "слот", куда можно вставить файл .tres
@export var data: EmployeeData

func _ready():
	# При старте игры проверим, выдали ли паспорт
	if data:
		# Для теста покрасим человечка в зависимости от роли (просто визуальный дебаг)
		if data.job_title == "Backend Lead":
			modulate = Color.DARK_MAGENTA # Синий для бекендеров
		else:
			modulate = Color.GREEN # Зеленый для остальных
