extends RefCounted

const DATOS := [
	{"nombre": "Bocamina", "aviso": "Marca al acechador para concentrar el daño. R reagrupa.", "color": Color("#cbb491"),
		"pilar": Rect2(7, 1, 1.2, 1.35), "xp": 55, "botin": 0,
		"enemigos": [["minero", Vector2(6.4, 7.4), 58], ["acechador", Vector2(4, 4), 60], ["minero", Vector2(8.2, 7.8), 63]]},
	{"nombre": "Raíles partidos", "aviso": "Alinea los disparos por los pasos junto al muro.", "color": Color("#a8b6ba"),
		"pilar": Rect2(5.6, 2, 1.25, 6), "xp": 65, "botin": 1,
		"enemigos": [["minero", Vector2(7.9, 8.8), 78], ["minero", Vector2(9.1, 8.8), 74], ["minero", Vector2(8.3, 1.1), 74], ["acechador", Vector2(10.2, 1.6), 82]]},
	{"nombre": "Sala de bombas", "aviso": "Sal del sector amarillo antes de que se abra la compuerta.", "color": Color("#ccc0b3"),
		"pilar": Rect2(5.4, 3.6, 1.15, 1.2), "xp": 90, "botin": 4,
		"enemigos": [["minero", Vector2(8, 3), 67], ["minero", Vector2(9, 6), 75], ["acechador", Vector2(9, 3.2), 75]]},
	{"nombre": "Viviendas ciegas", "aviso": "Llegarán refuerzos por el norte. Colócate junto a un acceso.", "color": Color("#b392a0"),
		"pilar": Rect2(5.4, 3, 2.1, 3.55), "xp": 85, "botin": 5,
		"enemigos": [["minero", Vector2(8, 7.6), 85], ["acechador", Vector2(10, 7.8), 85]]},
	{"nombre": "Osario de cal", "aviso": "Marca al enterrador y usa Orden cuando anuncie la reanimación.", "color": Color("#c8c6aa"),
		"pilar": Rect2(7.6, 2.5, 1.5, 2.45), "xp": 110, "botin": 6,
		"enemigos": [["enterrador", Vector2(9.2, 6.7), 225], ["minero", Vector2(6.7, 6.3), 80], ["minero", Vector2(7.4, 8.1), 85], ["acechador", Vector2(10.6, 5.8), 90]]},
	{"nombre": "Coro de sal", "aviso": "Los coristas sanan a su escolta. Márcalos antes de que termine el cántico.", "color": Color("#a4b5af"),
		"pilar": Rect2(5.9, 4.0, 1.2, 1.45), "xp": 125, "botin": 10,
		"enemigos": [["corista", Vector2(8.3, 7.2), 126], ["minero", Vector2(6.1, 7.2), 104], ["acechador", Vector2(7.2, 5.9), 97], ["minero", Vector2(9.5, 8.2), 104]]},
	{"nombre": "Fundición sepultada", "aviso": "El suelo advierte antes de expulsar brasas. Reagrupa fuera de la franja.", "color": Color("#b59075"),
		"pilar": Rect2(6.25, 2.0, 1.1, 2.3), "xp": 145, "botin": 11,
		"enemigos": [["verdugo", Vector2(8.3, 6.45), 247], ["minero", Vector2(9.6, 7.7), 100], ["acechador", Vector2(7.4, 8.7), 105]]},
	{"nombre": "Campanario hundido", "aviso": "Aléjate del Campanero cuando cargue la campana. Entra solo para atacar.", "color": Color("#9c9bb4"),
		"pilar": Rect2(6.1, 2.9, 1.25, 1.23), "xp": 170, "botin": 12,
		"enemigos": [["campanero", Vector2(8.8, 6.0), 345], ["corista", Vector2(10.1, 7.6), 124], ["minero", Vector2(8.45, 8.4), 106]]},
]
const PLANO := 101
const ELITE := 102
const FORJA_ELITE := 103

static func nombre(planta: int) -> String:
	return "−%d · %s" % [planta, DATOS[planta - 1].nombre]
