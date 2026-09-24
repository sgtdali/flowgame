class_name Wallet
extends RefCounted

## Oyuncunun parası (arayüzsüz). Bölge açma, hat ve araç aynı cüzdandan harcar.
## int — para her yerde tam sayı. Bakım parayı eksiye düşürebilir (tasarım:
## borç); eksideyken can_afford hiçbir alıma izin vermez.

var money: int = 0


func _init(starting_money: int = 0) -> void:
	money = starting_money


func can_afford(amount: int) -> bool:
	return money >= amount


## Para yetiyorsa düşer ve true döner; yetmiyorsa hiçbir şey değişmez.
func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	money -= amount
	return true


func refund(amount: int) -> void:
	money += amount


## Gelir (+) ya da bakım (−). Para eksiye inebilir.
func adjust(amount: int) -> void:
	money += amount
