extends Node

var first_names = ["Олег", "Мария", "Алексей", "Дарья", "Иван", "Елена", "Макс", "Сергей", "Анна"]
var last_names = ["Петров(а)", "Смирнов(а)", "Кузнецов(а)", "Попов(а)", "Васильев(а)", "Соколов(а)", "Михайлов(а)"]
var roles = ["Business Analyst", "Backend Developer", "QA Engineer"]

func generate_random_candidate() -> EmployeeData:
	var new_emp = EmployeeData.new()
	
	# 1. Имя и Роль
	new_emp.employee_name = first_names.pick_random() + " " + last_names.pick_random()
	var role = roles.pick_random()
	new_emp.job_title = role
	
	# 2. Навыки (Сначала обнуляем всё)
	new_emp.skill_business_analysis = 0.0
	new_emp.skill_backend = 0.0
	new_emp.skill_qa = 0.0
	
	# 3. Выдаем навык ТОЛЬКО по специальности
	var primary_skill_value = randf_range(1.5, 4.0) # От 1.5 до 4.0
	
	match role:
		"Business Analyst":
			new_emp.skill_business_analysis = primary_skill_value
		"Backend Developer":
			new_emp.skill_backend = primary_skill_value
		"QA Engineer":
			new_emp.skill_qa = primary_skill_value
	
	# 4. Считаем Зарплату (только от профильного навыка)
	var raw_salary = 500 + (primary_skill_value * 600)
	new_emp.monthly_salary = round(raw_salary / 100.0) * 100
	
	return new_emp
