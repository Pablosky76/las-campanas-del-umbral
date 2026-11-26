extends RefCounted

const VELOCIDAD := 17.0
const RADIO := 0.40

var posicion: Vector2
var direccion: Vector2
var alcance: float
var potencia: float
var perfora: bool
var ralentiza: bool
var grillete := false
var alcanzados: Array[Combatiente] = []

func _init(origen: Vector2, destino: Vector2, dano: float, perforante: bool, con_cal: bool) -> void:
	posicion = origen
	direccion = origen.direction_to(destino)
	alcance = origen.distance_to(destino) + (2.1 if perforante else 0.75)
	potencia = dano
	perfora = perforante
	ralentiza = con_cal
