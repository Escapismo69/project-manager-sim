extends Node
class_name ProjectGenerator

const TITLES = ["Лендинг пекарни", "CRM такси", "Сайт визитка", "Мобильная игра", "Интернет-магазин"]

# Константы для расчета дедлайна "по рынку"
const MARKET_SPEED_PER_HOUR = 60.0 # Средняя скорость работы сотрудника (очков/час)
const WORK_HOURS_PER_DAY = 9.0     # Длительность рабочего дня (с 9 до 18)

# Функция теперь принимает текущий день игры, чтобы посчитать дату сдачи
static func generate_random_project(current_game_day: int) -> ProjectData:
	var new_proj = ProjectData.new()
	new_proj.title = TITLES.pick_random()
	new_proj.created_at_day = current_game_day
	new_proj.state = new_proj.State.DRAFTING
	
	# 1. Генерируем сложность этапов
	var ba_points = randi_range(1500, 3000)   # ~ 3-6 дней (при скилле 50)
	var dev_points = randi_range(4000, 8000)  # ~ 8-16 дней
	var qa_points = randi_range(2000, 4000)   # ~ 4-8 дней
	
	# 2. Заполняем массив этапов (Строгая последовательность!)
	new_proj.stages = [
		{ "type": "BA",  "amount": ba_points,  "progress": 0.0, "worker": null },
		{ "type": "DEV", "amount": dev_points, "progress": 0.0, "worker": null },
		{ "type": "QA",  "amount": qa_points,  "progress": 0.0, "worker": null }
	]
	
	# 3. Расчет Бюджета
	# Платим условно $1.5 за каждое очко работы
	var total_points = ba_points + dev_points + qa_points
	new_proj.budget = int(total_points * 1.5)
	
	# 4. Расчет Дедлайна (САМОЕ ВАЖНОЕ)
	# Сколько часов чистого времени нужно одному среднему сотруднику, 
	# чтобы сделать всё последовательно?
	var hours_needed_ideal = total_points / MARKET_SPEED_PER_HOUR
	
	# Переводим часы в дни (учитывая, что работают только 9 часов в сутки)
	var days_needed_ideal = hours_needed_ideal / WORK_HOURS_PER_DAY
	
	# Добавляем "Коэффициент спокойствия" (Запас времени)
	# Например, даем в 1.5 раза больше времени, чем нужно в идеале
	# Плюс минимум 1 день запаса
	var buffer_coef = randf_range(1.4, 1.8) 
	var days_given = ceil(days_needed_ideal * buffer_coef) + 1
	
	# Устанавливаем дедлайн
	new_proj.deadline_day = current_game_day + int(days_given)
	
	return new_proj
