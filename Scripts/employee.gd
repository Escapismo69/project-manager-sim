extends CharacterBody2D

# Пустой слот под данные
@export var data: EmployeeData

@onready var sprite = $Sprite2D # Убедись, что у тебя есть этот узел

func _ready():
	# 1. АВТОМАТИЧЕСКИ добавляем в группу NPC (важно для зарплат!)
	add_to_group("npc")
	
	# Если данные уже есть (выдали в редакторе, как Васе), красим сразу
	if data:
		update_visuals()

# 2. ФУНКЦИЯ НАЙМА (ее будет вызывать кнопка "Нанять")
func setup_employee(new_data: EmployeeData):
	data = new_data
	update_visuals()

# Обновление внешнего вида
func update_visuals():
	if not sprite: return # Защита, если спрайта нет
	
	# Твоя логика покраски
	if data.job_title == "Backend Lead" or data.job_title == "Backend Developer":
		modulate = Color.DARK_MAGENTA
	elif data.job_title == "Business Analyst":
		modulate = Color.ORANGE
	else:
		modulate = Color.GREEN

# 3. ВЗАИМОДЕЙСТВИЕ (чтобы смотреть карточку)
func interact():
	var hud = get_tree().get_first_node_in_group("ui")
	if hud and data:
		hud.show_employee_card(data)
