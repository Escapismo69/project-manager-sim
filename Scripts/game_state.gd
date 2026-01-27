extends Node

# Стартовый капитал
var company_balance: int = 10000

# Сигнал: "Эй, интерфейс, деньги изменились!"
signal balance_changed(new_amount)
