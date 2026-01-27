extends Node2D

# Загружаем ресурсы (поменяй пути на свои!)
var test_project = preload("res://Resources/Projects/project_test.tres") 
var test_employee = preload("res://Resources/Employees/vasya.tres")

@onready var window = $ProjectWindow

func _ready():
	# 1. Загружаем данные в окно
	window.setup(test_project)
	
	# 2. ЧИТЕРСТВО: Вручную назначаем Васю на ВСЕ этапы сразу
	test_project.assignee_ba = test_employee
	test_project.assignee_dev = test_employee
	test_project.assignee_qa = test_employee
	
	# Теперь если нажать кнопку Start в игре, полоски должны поползти
