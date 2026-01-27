extends Node

# Глобальные сигналы (на них подпишутся все: UI, сотрудники, календарь)
signal time_tick(hour, minute)
signal day_started(day_number)
signal day_ended

# Настройки времени
const MINUTES_PER_REAL_SECOND = 10 # 1 реальная сек = 10 игровых минут (день пройдет за ~2.5 мин)
const START_HOUR = 8 # Начало рабочего дня
const END_HOUR = 18 # Конец рабочего дня

# Текущее состояние
var day = 1
var hour = 8
var minute = 0

var time_accumulator = 0.0 # Сюда копим доли секунд

func _process(delta):
	# Прибавляем реальное время к аккумулятору
	time_accumulator += delta * MINUTES_PER_REAL_SECOND
	
		
	# Если накопала целая минута
	if time_accumulator >= 1.0:
		minute += 1
		time_accumulator -= 1.0
		
		# Логика перевода часов
		if minute >= 60:
			minute = 0
			hour += 1
			
			if hour >= 24:
				hour = 0
				day += 1
				emit_signal("day_started", day)
				GameState.pay_daily_salaries()
		
		# Сообщаем всем, сколько сейчас времени
		emit_signal("time_tick", hour, minute)
