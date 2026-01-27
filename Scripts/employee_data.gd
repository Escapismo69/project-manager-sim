extends Resource
class_name EmployeeData

# @export позволяет редактировать эти поля прямо в Инспекторе
@export var employee_name: String = "Новичок"
@export var job_title: String = "Junior Developer"
@export var monthly_salary: int = 3000

var daily_salary: int:
	get:
		return monthly_salary / 30

# Навыки (от 0 до 100)
@export var skill_backend: int = 10
@export var skill_frontend: int = 5
@export var skill_management: int = 0

# Сюда можно добавить иконку лица (аватарку)
@export var avatar: Texture2D
