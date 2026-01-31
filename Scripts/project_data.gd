extends Resource
class_name ProjectData

@export var title: String = "Проект"

# --- НОВЫЕ ДАННЫЕ ---

# Когда проект был создан (чтобы считать просрочку)
var created_at_day: int = 1

# Дедлайн (номер дня, к которому надо успеть)
var deadline_day: int = 0

# Массив этапов. Порядок важен! (BA -> DEV -> QA)
# Каждый элемент массива будет выглядеть так:
# {
#   "type": "BA",           # Тип работ (для иконок и логики)
#   "amount": 500,          # Сколько очков работы нужно
#   "progress": 0.0,        # Текущий прогресс
#   "worker": null          # Кто назначен (EmployeeData)
# }
@export var stages: Array = []

# Бюджет (награда)
@export var budget: int = 5000

# Текущее состояние всего проекта
enum State { DRAFTING, IN_PROGRESS, FINISHED, FAILED }
var state = State.DRAFTING # DRAFTING - это режим планирования
