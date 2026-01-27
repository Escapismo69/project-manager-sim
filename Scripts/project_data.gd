extends Resource
class_name ProjectData

@export var title: String = "Проект"

# Требования (сколько очков нужно набить)
@export var ba_needed: int = 500
@export var dev_needed: int = 1000
@export var qa_needed: int = 650

# Бюджет (награда)
@export var budget: int = 5000

# Текущий прогресс
var ba_progress: float = 0.0
var dev_progress: float = 0.0
var qa_progress: float = 0.0

# Назначенные люди
var assignee_ba: EmployeeData
var assignee_dev: EmployeeData
var assignee_qa: EmployeeData

# Состояния
enum Stage { NOT_STARTED, BA, DEV, QA, FINISHED }
var current_stage = Stage.NOT_STARTED
