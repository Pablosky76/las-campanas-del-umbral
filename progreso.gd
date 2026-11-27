extends RefCounted

const PLANTAS = preload("res://plantas.gd")
const SAVE := "user://valdebronce.cfg"
var ruta_guardado := SAVE
const TALENTOS := [
	["Pulso de bronce", "+6 daño de ataque", "ataque", 6],
	["Tormenta de virotes", "+4 daño de ballesteros", "virotes", 4],
	["Mandato del Umbral", "Orden se recarga 1 s antes", "orden", 1],
	["Piel de pizarra", "+20 vida máxima", "vida", 20],
	["Baluarte", "+35 vida del guardián", "guardian", 35],
	["Refugio de bronce", "−25% daño de combate recibido", "proteccion", 25],
	["Colmillos de ceniza", "+5 daño de sabuesos", "sabuesos", 5],
	["Llamada insistente", "Campana se recarga 2 s antes", "campana", 2],
	["Manada eterna", "+18 vida de esbirros menores", "esbirros", 18],
]
const RANURAS := ["Bastón", "Armadura", "Amuleto"]
const OBJETOS := [
	["Bastón de cobre", 0, "+5 daño de ataque", "ataque", 5],
	["Jubón de la mina", 1, "+18 vida máxima", "vida", 18],
	["Diente de ceniza", 2, "+4 daño de sabuesos", "sabuesos", 4],
	["Vara de la fundición", 0, "+8 ataque y +3 daño de ballesteros", "ataque", 8],
	["Coraza del capataz", 1, "+28 vida máxima y +20 del guardián", "vida", 28],
	["Campanilla de Elías", 2, "Campana se recarga 2 s antes", "campana", 2],
	["Amuleto de cal", 2, "Los virotes perforan y ralentizan", "cal", 1],
	["Vara de fresno", 0, "+3 daño de ataque", "ataque", 3],
	["Cota de eslabones", 1, "+20 vida máxima", "vida", 20],
	["Sello del ballestero", 2, "+4 daño de ballesteros", "virotes", 4],
	["Vara del coro", 0, "+10 ataque y +3 daño de virotes", "ataque", 10],
	["Cota de la fundición", 1, "+32 vida y +20 de guardián", "vida", 32],
	["Corazón de la campana", 2, "Campana −3 s y +8 vida de esbirros", "campana", 3],
	["Talismán del horno", 2, "+7 daño de sabuesos", "sabuesos", 7],
	["Broquel de Mara", 1, "+16 vida y +35 de guardián", "vida", 16],
]
const COLORES_VINCULADOR := [Color.WHITE, Color("#f4aaa0"), Color("#accce9"), Color("#b4d29b"), Color("#cbb4e6")]
const ASPECTOS := [preload("res://arte/vinculador-necromante.png"), preload("res://arte/player.png")]
const NOMBRES_ASPECTOS := ["Nigromante", "Capa azul"]
var aspecto := 0
const CONTRATOS := [
	["Silencia el coro", "Completa Coro de sal (−6)", 6, 36],
	["Abre el horno sellado", "Vence a la pareja de élite en la Fundición (−7)", PLANTAS.FORJA_ELITE, 48],
	["La última campanada", "Derrota al Campanero en la −8", 8, 62],
]
var contratos: Array[int] = []
const COBRE_INICIAL := 26
const PRECIO_TIENDA := {7: 24, 8: 45, 9: 56, 14: 82}
const PRECIO_VENTA := [9, 11, 14, 21, 24, 19, 26, 12, 22, 28, 29, 34, 39, 35, 41]
var cobre := COBRE_INICIAL
var vendidos: Array[int] = []
var tinte := 0
var tramo := 1
var recompensas: Array[int] = []
var victorias := 0
var hallazgo := false
var xp := 0
var talentos: Array[int] = []
var inventario: Array[int] = []
var equipo: Array[int] = [-1, -1, -1]

func cargar() -> void:
	var config := ConfigFile.new()
	if config.load(ruta_guardado) != OK:
		return
	victorias = maxi(0, int(config.get_value("perfil", "victorias", 0)))
	hallazgo = config.get_value("perfil", "plano", false) == true
	tramo = clampi(int(config.get_value("mina", "tramo", 1)), 1, PLANTAS.DATOS.size())
	recompensas = ids_validos(config.get_value("mina", "recompensas", []), PLANTAS.FORJA_ELITE + 1)
	if tramo == 5 and 5 in recompensas:
		tramo = 6
	var cobre_legado := COBRE_INICIAL
	for paso in recompensas:
		cobre_legado += premio_cobre(paso)
	contratos = ids_validos(config.get_value("personaje", "contratos", []), CONTRATOS.size())
	cobre = maxi(0, int(config.get_value("personaje", "cobre", cobre_legado)))
	vendidos = ids_validos(config.get_value("personaje", "vendidos", []), OBJETOS.size())
	aspecto = clampi(int(config.get_value("personaje", "aspecto", 0)), 0, ASPECTOS.size() - 1)
	tinte = clampi(int(config.get_value("personaje", "tinte", 0)), 0, COLORES_VINCULADOR.size() - 1)
	xp = maxi(0, int(config.get_value("personaje", "xp", 0)))
	talentos = ids_validos(config.get_value("personaje", "talentos", []), TALENTOS.size())
	inventario = ids_validos(config.get_value("personaje", "inventario", []), OBJETOS.size())
	var guardado: Variant = config.get_value("personaje", "equipo", [])
	equipo = [-1, -1, -1]
	if guardado is Array:
		for slot in mini(equipo.size(), guardado.size()):
			var id: Variant = guardado[slot]
			if id is int and id in inventario and OBJETOS[id][1] == slot:
				equipo[slot] = id

func ids_validos(values: Variant, limite: int) -> Array[int]:
	var result: Array[int] = []
	if values is Array:
		for id in values:
			if id is int and id >= 0 and id < limite and id not in result:
				result.append(id)
	return result

func umbral(nivel_objetivo: int) -> int:
	var pasos := nivel_objetivo - 1
	return 50 * pasos + 10 * pasos * (pasos - 1)

func nivel() -> int:
	var resultado := 1
	while xp >= umbral(resultado + 1):
		resultado += 1
	return resultado

func puntos() -> int:
	return maxi(0, nivel() - 1 - talentos.size())

func puede_aprender(id: int) -> bool:
	return id not in talentos and puntos() > 0 and (id % 3 == 0 or id - 1 in talentos)

func aprender(id: int) -> Error:
	if not puede_aprender(id):
		return ERR_UNAVAILABLE
	talentos.append(id)
	var result := guardar()
	if result != OK:
		talentos.erase(id)
	return result

func equipar(id: int) -> Error:
	if id not in inventario:
		return ERR_UNAVAILABLE
	var slot: int = OBJETOS[id][1]
	var previous := equipo[slot]
	equipo[slot] = -1 if previous == id else id
	var result := guardar()
	if result != OK:
		equipo[slot] = previous
	return result

func bonus(stat: String) -> int:
	var total := 0
	for id in talentos:
		if TALENTOS[id][2] == stat:
			total += TALENTOS[id][3]
	for id in equipo:
		if id >= 0 and OBJETOS[id][3] == stat:
			total += OBJETOS[id][4]
	if 3 in equipo and stat == "virotes":
		total += 3
	if 4 in equipo and stat == "guardian":
		total += 20
	if 10 in equipo and stat == "virotes":
		total += 3
	if 11 in equipo and stat == "guardian":
		total += 20
	if 12 in equipo and stat == "esbirros":
		total += 8
	if 14 in equipo and stat == "guardian":
		total += 35
	return total

static func premio_cobre(paso: int) -> int:
	if paso == PLANTAS.FORJA_ELITE:
		return 40
	if paso in [PLANTAS.PLANO, PLANTAS.ELITE]:
		return 18
	if paso >= 1 and paso <= PLANTAS.DATOS.size():
		return 21 + paso * 4
	return 0

func cobrar_contrato(id: int) -> Error:
	if id < 0 or id >= CONTRATOS.size() or id in contratos or CONTRATOS[id][2] not in recompensas:
		return ERR_UNAVAILABLE
	var premio: int = CONTRATOS[id][3]
	contratos.append(id)
	cobre += premio
	var resultado := guardar()
	if resultado != OK:
		cobre -= premio
		contratos.erase(id)
	return resultado

func precio_compra(id: int) -> int:
	if id < 0 or id >= OBJETOS.size() or id in inventario:
		return -1
	if id in vendidos:
		return PRECIO_VENTA[id]
	if id == 14 and tramo < 6:
		return -1
	return PRECIO_TIENDA.get(id, -1)

func comprar(id: int) -> Error:
	var precio := precio_compra(id)
	if precio < 0 or precio > cobre:
		return ERR_UNAVAILABLE
	var recompra := id in vendidos
	cobre -= precio
	inventario.append(id)
	vendidos.erase(id)
	var resultado := guardar()
	if resultado != OK:
		cobre += precio
		inventario.erase(id)
		if recompra:
			vendidos.append(id)
	return resultado

func vender(id: int) -> Error:
	var posicion := inventario.find(id)
	if posicion < 0 or id in equipo:
		return ERR_UNAVAILABLE
	var precio: int = PRECIO_VENTA[id]
	inventario.remove_at(posicion)
	vendidos.append(id)
	cobre += precio
	var resultado := guardar()
	if resultado != OK:
		cobre -= precio
		vendidos.erase(id)
		inventario.insert(posicion, id)
	return resultado

func registrar(paso: int, experiencia: int, botin: int) -> Error:
	if paso in recompensas:
		return OK
	var tramo_anterior := tramo
	var plano_anterior := hallazgo
	var nuevo := botin >= 0 and botin not in inventario
	recompensas.append(paso)
	if paso >= 1 and paso <= PLANTAS.DATOS.size():
		tramo = maxi(tramo, mini(paso + 1, PLANTAS.DATOS.size()))
	victorias += int(paso == 3)
	hallazgo = hallazgo or paso == PLANTAS.PLANO
	xp += experiencia
	var entrada_cobre := premio_cobre(paso)
	cobre += entrada_cobre
	if nuevo:
		inventario.append(botin)
	var result := guardar()
	if result != OK:
		recompensas.erase(paso)
		tramo = tramo_anterior
		victorias -= int(paso == 3)
		hallazgo = plano_anterior
		xp -= experiencia
		cobre -= entrada_cobre
		if nuevo:
			inventario.erase(botin)
	return result

func sprite_vinculador() -> Texture2D:
	return ASPECTOS[aspecto]

func cambiar_aspecto() -> Error:
	var previo := aspecto
	aspecto = (aspecto + 1) % ASPECTOS.size()
	var resultado := guardar()
	if resultado != OK:
		aspecto = previo
	return resultado

func color_vinculador() -> Color:
	return COLORES_VINCULADOR[tinte]

func personalizar(indice: int) -> Error:
	var previo := tinte
	tinte = clampi(indice, 0, COLORES_VINCULADOR.size() - 1)
	var resultado := guardar()
	if resultado != OK:
		tinte = previo
	return resultado

func guardar() -> Error:
	var config := ConfigFile.new()
	config.set_value("mina", "tramo", tramo)
	config.set_value("mina", "recompensas", recompensas)
	config.set_value("perfil", "victorias", victorias)
	config.set_value("perfil", "plano", hallazgo)
	config.set_value("personaje", "tinte", tinte)
	config.set_value("personaje", "aspecto", aspecto)
	config.set_value("personaje", "xp", xp)
	config.set_value("personaje", "cobre", cobre)
	config.set_value("personaje", "contratos", contratos)
	config.set_value("personaje", "vendidos", vendidos)
	config.set_value("personaje", "talentos", talentos)
	config.set_value("personaje", "inventario", inventario)
	config.set_value("personaje", "equipo", equipo)
	var result := config.save(ruta_guardado + ".tmp")
	if result == OK:
		result = DirAccess.rename_absolute(ruta_guardado + ".tmp", ruta_guardado)
	return result
