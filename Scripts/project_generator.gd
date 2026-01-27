extends Node
class_name ProjectGenerator

const TITLES = ["Лендинг пекарни", "CRM такси", "Сайт визитка", "Мобильная игра", "Интернет-магазин"]

static func generate_random_project() -> ProjectData:
	var new_proj = ProjectData.new()
	
	new_proj.title = TITLES.pick_random()
	
	# Генерируем случайную сложность
	new_proj.ba_needed = randi_range(300, 600)
	new_proj.dev_needed = randi_range(800, 1500)
	new_proj.qa_needed = randi_range(400, 800)
	
	# Считаем бюджет (примерно $1 за 1 очко работы)
	var total_points = new_proj.ba_needed + new_proj.dev_needed + new_proj.qa_needed
	new_proj.budget = total_points * 2 
	
	return new_proj
