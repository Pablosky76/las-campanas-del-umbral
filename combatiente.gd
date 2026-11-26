extends RefCounted
class_name Combatiente

var role: String
var position: Vector2
var health: float
var maximum_health: float
var cooldown := 0.0
var slow := 0.0
var windup := 0.0
var destination := Vector2.ZERO
var flash := 0.0
var facing_right := false
var rumbo := Vector2(0.25, 1.0)
var last_move := -1.0
var last_strike := -10.0
var ataques := 0

func _init(kind: String, at: Vector2, hp: float) -> void:
	role = kind
	position = at
	health = hp
	maximum_health = hp

func hurt(amount: float) -> void:
	health = maxf(0.0, health - amount)
	flash = 0.15
