extends Node2D

signal return_to_town(won: bool)
var town_visit := false
var reward_text := ""
var blessed := false

const ORIGIN := Vector2(530, 126)
const SIZE := Vector2(12, 10)
const JOYSTICK := Vector2(108, 535)
const BUTTONS := [Vector2(950, 485), Vector2(1040, 485), Vector2(950, 570), Vector2(1040, 570)]
const PLANTAS = preload("res://plantas.gd")
var planta := 1
var columna: Rect2
var refuerzos := false
var elite := false
var eco_invocado := false
const BRASAS := [Rect2(3.85, 5.55, 8.15, 1.1), Rect2(3.85, 7.70, 8.15, 1.1)]
var cadaveres: Array[Vector2] = []
var recompensa_pendiente := -1
const ESCENARIO = preload("res://escenario_3d.gd")
const VIROTE = preload("res://virote.gd")
var escenario: ESCENARIO
const FIGURA = preload("res://figura_3d.gd")
var figuras: Dictionary[Combatiente, FIGURA] = {}
const COLORS := {"player": Color("#b87155"), "sabueso": Color("#d3c19d"), "ballestero": Color("#b19e8d"), "guardian": Color("#a87b48"), "minero": Color("#927c74"), "capataz": Color("#a04f46")}

var player: Combatiente
var allies: Array[Combatiente] = []
var enemies: Array[Combatiente] = []
var shots: Array[Dictionary] = []
var virotes: Array[VIROTE] = []
var modelos_virotes: Dictionary[VIROTE, Node3D] = {}
var marked: Combatiente
const ALTURAS := {"player": 112, "sabueso": 46, "ballestero": 77, "guardian": 99, "minero": 64, "capataz": 92}
const ANILLOS := {"player": Color("#8de7e4"), "sabueso": Color("#c9d4c4"), "ballestero": Color("#c0a9e9"), "guardian": Color("#f1c475")}
const INVOCACIONES := ["sabueso", "ballestero", "guardian"]
const INVOCAR := Rect2(931, 64, 185, 44)
const TECLAS_INVOCACION := [KEY_Z, KEY_X, KEY_C]
const ETIQUETAS_INVOCACION := ["Sabueso [Z]", "Ballestero [X]", "Custodio [C]"]
const CERRAR_RITUAL := Rect2(451, 468, 250, 45)
var ritual := false
var enjambre_sugerido := false
var aviso_ritual := ""
var defense_cooldown := 0.0
const Progreso = preload("res://progreso.gd")
var progreso := Progreso.new()
var piercing := false
var retaliation := false
var relic := -1
var relic_taken := false
var wave := 1
var veteran_guard := false
var save_failed := false
var regroup := 0.0
var guard := 0.0
var bell_cooldown := 0.0
var order_cooldown := 0.0
var elapsed := 0.0
var flood := 0.0
var state := "menu"
var stick_id := -1
var stick := Vector2.ZERO
var sprites := {}
var rituales_visuales: Array[Dictionary] = []
var guardia_visual := 0.0
var guardia_origen := Vector2.ZERO
const RITUAL_DURACION := 0.70
const NOMBRES_RITUAL := ["Sabueso osario", "Ballestero de cripta", "Custodio sepulcral"]
const EFECTOS_RITUAL := ["Remata presas marcadas", "Cada tercer virote frena", "Comparte el daño cercano"]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	progreso.cargar()
	for role in COLORS:
		sprites[role] = progreso.sprite_vinculador() if role == "player" else load("res://arte/%s.png" % role)
	columna = PLANTAS.DATOS[0].pilar
	player = Combatiente.new("player", Vector2(2, 7), 100)

func start(use_swarm: bool, use_veteran: bool, destino := 1) -> void:
	enjambre_sugerido = use_swarm
	allies.clear()
	veteran_guard = use_veteran
	piercing = false
	retaliation = false
	relic = -1
	relic_taken = false
	entrar_planta(destino)

func entrar_planta(destino: int) -> void:
	planta = clampi(destino, 1, progreso.tramo)
	columna = PLANTAS.DATOS[planta - 1].pilar
	if not is_instance_valid(escenario) or escenario.planta != planta:
		if is_instance_valid(escenario):
			escenario.queue_free()
		figuras.clear()
		modelos_virotes.clear()
		escenario = ESCENARIO.new()
		escenario.planta = planta
		escenario.obstaculo = columna
		add_child(escenario)
	refuerzos = planta == 4
	elite = false
	eco_invocado = false
	cadaveres.clear()
	rituales_visuales.clear()
	guardia_visual = 0.0
	recompensa_pendiente = -1
	save_failed = false
	wave = 1
	reward_text = ""
	player = Combatiente.new("player", Vector2(2, 7), 100 + (progreso.nivel() - 1) * 5 + progreso.bonus("vida"))
	enemies.clear()
	for enemigo: Array in PLANTAS.DATOS[planta - 1].enemigos:
		enemies.append(Combatiente.new(enemigo[0], enemigo[1], enemigo[2]))
	for index in allies.size():
		var unit := allies[index]
		unit.position = posicion_invocacion(index)
		unit.cooldown = 0.0
	reiniciar_poses()
	shots.clear()
	virotes.clear()
	marked = null
	elapsed = 0
	flood = 0
	if planta == 3:
		escenario.actualizar(0, 0)
	regroup = 0
	guard = 0
	defense_cooldown = 0
	bell_cooldown = 0
	order_cooldown = 0
	stick_id = -1
	stick = Vector2.ZERO
	ritual = false
	aviso_ritual = ""
	state = "play"

func use_town_blessing(enabled: bool) -> void:
	town_visit = true
	blessed = enabled

func hurt_player(amount: float) -> void:
	if blessed and amount >= 5:
		blessed = false
		return
	var golpe := amount * (1.0 - progreso.bonus("proteccion") / 100.0)
	for aliado in allies:
		if aliado.role == "guardian" and aliado.health > 0 and aliado.position.distance_squared_to(player.position) <= 2.6 ** 2 and clear_line(aliado.position, player.position):
			var desviado := minf(golpe * 0.28, aliado.health)
			aliado.hurt(desviado)
			guardia_origen = aliado.position
			guardia_visual = 0.26
			golpe -= desviado
			break
	player.hurt(golpe)

func seleccionar_reliquia(index: int) -> void:
	relic = index
	relic_taken = true
	piercing = index == 0
	retaliation = index == 1 and tiene_custodio()
	if index == 1 and not tiene_custodio():
		bell_cooldown = 0
	player.health = minf(player.maximum_health, player.health + 24)
	if index == 2:
		player.health = player.maximum_health
	guard = 0
	reiniciar_poses()
	elapsed = 0
	flood = 0
	if planta == 3:
		escenario.actualizar(0, 0)
	shots.clear()
	virotes.clear()
	wave = 2
	enemies.assign([
		Combatiente.new("capataz", Vector2(10, 5), 250),
		Combatiente.new("minero", Vector2(10, 2), 62),
	])
	state = "play"

func iso(p: Vector2) -> Vector2:
	return ORIGIN + Vector2((p.x - p.y) * 39, (p.x + p.y) * 20)

func sobre_suelo(p: Vector2) -> Vector2:
	var punto := iso(p)
	if planta == 3:
		punto.y -= ESCENARIO.altura(p) * 47.55
	return punto

func world(p: Vector2) -> Vector2:
	var q := p - ORIGIN
	return Vector2(q.y / 40 + q.x / 78, q.y / 40 - q.x / 78)

func walk(unit: Combatiente, direction: Vector2, distance: float) -> void:
	var origen := unit.position
	var step := direction.limit_length() * distance
	for offset in [Vector2(step.x, 0), Vector2(0, step.y)]:
		var candidate: Vector2 = (unit.position + offset).clamp(Vector2(0.25, 0.25), SIZE - Vector2(0.25, 0.25))
		if not columna.grow(0.16).has_point(candidate):
			var movement_x := iso(candidate).x - iso(unit.position).x
			if absf(movement_x) > 0.08:
				unit.facing_right = movement_x > 0
				unit.last_move = elapsed
			unit.position = candidate
	if not unit.position.is_equal_approx(origen):
		unit.rumbo = origen.direction_to(unit.position)
		unit.last_move = elapsed

func toward(unit: Combatiente, goal: Vector2, pace: float, delta: float) -> void:
	var block := columna.grow(0.18)
	if not clear_line(unit.position, goal, block):
		var outline := block.grow(0.22)
		var corners: Array[Vector2] = [outline.position, Vector2(outline.end.x, outline.position.y),
			outline.end, Vector2(outline.position.x, outline.end.y)]
		var best := INF
		var waypoint := goal
		for first in corners:
			if not clear_line(unit.position, first, block):
				continue
			var approach := unit.position.distance_to(first)
			for last in corners:
				if not clear_line(first, last, block) or not clear_line(last, goal, block):
					continue
				var cost := approach + first.distance_to(last) + last.distance_to(goal)
				if cost < best:
					best = cost
					waypoint = first
		goal = waypoint
	var offset := goal - unit.position
	walk(unit, offset.normalized(), minf(pace * delta, offset.length()))

func clear_line(from: Vector2, to: Vector2, block: Rect2 = Rect2()) -> bool:
	if not block.has_area():
		block = columna
	if from.is_equal_approx(to):
		return not block.has_point(from)
	var a := block.position
	var b := Vector2(block.end.x, a.y)
	var c := block.end
	var d := Vector2(a.x, c.y)
	return Geometry2D.segment_intersects_segment(from, to, a, b) == null and Geometry2D.segment_intersects_segment(from, to, b, c) == null and Geometry2D.segment_intersects_segment(from, to, c, d) == null and Geometry2D.segment_intersects_segment(from, to, d, a) == null

func ritual_slot(index: int, add_unit: bool) -> Rect2:
	return Rect2(684 if add_unit else 627, 260 + index * 65, 44, 43)

func cantidad_invocada(tipo: String) -> int:
	var cantidad := 0
	for unit in allies:
		if unit.role == tipo and unit.health > 0:
			cantidad += 1
	return cantidad

func tiene_custodio() -> bool:
	return cantidad_invocada("guardian") > 0

func vinculos_ocupados() -> int:
	return allies.size() + cantidad_invocada("guardian")

func motivo_invocacion(index: int) -> String:
	if index == 2 and tiene_custodio():
		return "Ya tienes un custodio."
	if vinculos_ocupados() + (2 if index == 2 else 1) > 6:
		return "Faltan vínculos libres."
	if bell_cooldown > 0:
		return "Campana lista en %.1f s." % bell_cooldown
	return ""

func cambiar_invocacion(index: int, add_unit: bool) -> void:
	if state != "play":
		return
	var kind: String = INVOCACIONES[index]
	if add_unit:
		aviso_ritual = motivo_invocacion(index)
		if not aviso_ritual.is_empty():
			return
		invocar(kind, allies.size())
		var recarga := 1.4 if relic == 1 and not retaliation else 2.5
		bell_cooldown = maxf(0.8, recarga - progreso.bonus("campana"))
	else:
		for unit in allies:
			if unit.role == kind:
				allies.erase(unit)
				break
	aviso_ritual = ""

func toggle_ritual() -> void:
	if state != "play":
		return
	ritual = not ritual
	stick = Vector2.ZERO
	stick_id = -1

func boton_invocacion(index: int) -> Rect2:
	return Rect2(320 + index * 169, 575, 158, 54)

func draw_ritual() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("#0f0b11cf"))
	var book := Rect2(360, 133, 432, 397)
	draw_rect(book, Color("#261c23"))
	draw_rect(book, Color("#aa8756"), false, 2)
	label(Vector2(388, 179), "Círculo de vínculos", 29)
	label(Vector2(388, 212), "%d / 6 vínculos · El guardián ocupa dos" % vinculos_ocupados(), 16)
	label(Vector2(388, 238), "Sugerencia: 4 sabuesos y 2 ballesteros" if enjambre_sugerido else "Sugerencia: 2 sabuesos, 2 ballesteros y un custodio", 14)
	for index in INVOCACIONES.size():
		var at := Vector2(439, 288 + index * 65)
		var retrato: Texture2D = sprites[INVOCACIONES[index]]
		var tamano := retrato.get_size()
		tamano *= 39.0 / maxf(tamano.x, tamano.y)
		draw_texture_rect(retrato, Rect2(at + Vector2(-28, -7) - tamano * 0.5, tamano), false)
		label(at - Vector2(0, 7), "%s ×%d" % [NOMBRES_RITUAL[index], cantidad_invocada(INVOCACIONES[index])], 15)
		label(at + Vector2(0, 13), EFECTOS_RITUAL[index], 12, Color("#b8b39a"))
		for add_unit: bool in [false, true]:
			var rect := ritual_slot(index, add_unit)
			draw_rect(rect, Color("#534036"))
			label(rect.position + Vector2(14, 29), "+" if add_unit else "−", 22)
	label(Vector2(388, 453), "Campana lista en %.1f s · Sal al combate para recargar" % bell_cooldown if bell_cooldown > 0 else aviso_ritual, 14, Color("#ffb986"))
	draw_rect(CERRAR_RITUAL, Color("#594339"))
	label(CERRAR_RITUAL.position + Vector2(47, 28), "Continuar [F]", 18)

func posicion_invocacion(index: int) -> Vector2:
	var offset := Vector2.from_angle(index * TAU / 6.0) * 0.85
	var at := (player.position + offset).clamp(Vector2(0.25, 0.25), SIZE - Vector2(0.25, 0.25))
	return player.position if columna.grow(0.16).has_point(at) else at

func invocar(kind: String, index: int) -> void:
	var at := posicion_invocacion(index)
	var hp := 40 + progreso.bonus("esbirros")
	if kind == "guardian":
		hp = (130 if veteran_guard else 100) + progreso.bonus("guardian")
	allies.append(Combatiente.new(kind, at, hp))
	rituales_visuales.append({"at": at, "tiempo": RITUAL_DURACION})

func closest(units: Array, at: Vector2) -> Combatiente:
	var best: Combatiente
	var distance := INF
	for unit: Combatiente in units:
		var candidate := unit.position.distance_squared_to(at)
		if unit.health > 0 and candidate < distance:
			distance = candidate
			best = unit
	return best

func shoot(from: Combatiente, to: Combatiente, power: float, through := false) -> void:
	from.last_strike = elapsed
	if not from.position.is_equal_approx(to.position):
		from.rumbo = from.position.direction_to(to.position)
	if from.role == "ballestero":
		from.ataques += 1
		var virote := VIROTE.new(from.position, to.position, power, through, through and progreso.bonus("cal") > 0)
		virote.grillete = from.ataques % 3 == 0
		virotes.append(virote)
	else:
		to.hurt(power)
		shots.append({"from": from.position, "to": to.position, "time": 0.14})

func avanzar_virote(virote: VIROTE, delta: float) -> bool:
	var largo := minf(virote.alcance, VIROTE.VELOCIDAD * delta)
	var destino := virote.posicion + virote.direccion * largo
	var objetivos: Array[Dictionary] = []
	for unidad in enemies:
		if unidad.health <= 0 or unidad in virote.alcanzados:
			continue
		var punto := Geometry2D.get_closest_point_to_segment(unidad.position, virote.posicion, destino)
		if punto.distance_squared_to(unidad.position) <= VIROTE.RADIO ** 2 and clear_line(virote.posicion, punto) and clear_line(punto, unidad.position):
			objetivos.append({"unidad": unidad, "distancia": virote.posicion.distance_squared_to(punto)})
	objetivos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distancia < b.distancia)
	for impacto in objetivos:
		var unidad: Combatiente = impacto.unidad
		unidad.hurt(virote.potencia if virote.alcanzados.is_empty() else virote.potencia * 0.75)
		if virote.ralentiza or virote.grillete:
			unidad.slow = maxf(unidad.slow, 2.0 if virote.ralentiza else 1.45)
		virote.alcanzados.append(unidad)
		if not virote.perfora:
			return false
	if not clear_line(virote.posicion, destino):
		return false
	virote.posicion = destino
	virote.alcance -= largo
	return virote.alcance > 0.0

func action(index: int) -> void:
	if state != "play" or ritual:
		return
	var target := marked if is_instance_valid(marked) and marked.health > 0 else closest(enemies, player.position)
	match index:
		0:
			if target and player.cooldown <= 0 and player.position.distance_to(target.position) <= 3.3 and clear_line(player.position, target.position):
				shoot(player, target, 14 + progreso.nivel() - 1 + progreso.bonus("ataque"))
				player.cooldown = 0.57
		1: recall()
		2:
			if target and order_cooldown <= 0:
				marked = target
				player.last_strike = elapsed
				regroup = 0
				order_cooldown = 4.0 - progreso.bonus("orden")
				for unit in allies:
					unit.cooldown = 0
		3:
			if defense_cooldown <= 0:
				guard = 0.6
				defense_cooldown = 3.2

func recall() -> void:
	regroup = 2.8
	marked = null

func _physics_process(delta: float) -> void:
	queue_redraw()
	if state != "play" or ritual:
		return
	elapsed += delta
	guardia_visual = maxf(0.0, guardia_visual - delta)
	for efecto in rituales_visuales:
		efecto.tiempo -= delta
	rituales_visuales = rituales_visuales.filter(func(efecto: Dictionary) -> bool: return efecto.tiempo > 0)
	flood = fmod(elapsed, 12.0)
	escenario.actualizar(flood, elapsed)
	regroup = maxf(0, regroup - delta)
	guard = maxf(0, guard - delta)
	defense_cooldown = maxf(0, defense_cooldown - delta)
	bell_cooldown = maxf(0, bell_cooldown - delta)
	order_cooldown = maxf(0, order_cooldown - delta)
	for unit: Combatiente in [player] + allies + enemies:
		unit.cooldown -= delta
		unit.flash -= delta
		unit.slow = maxf(0.0, unit.slow - delta)
		if planta == 3 and flood >= 9.0 and ESCENARIO.inundable(unit.position):
			unit.hurt(delta * (12.0 if unit == player else 15.0))
		if planta == 7 and fmod(elapsed, 9.0) >= 6.2 and franja_brasas().has_point(unit.position):
			unit.hurt(delta * (18.0 if unit == player else 10.0))
	if refuerzos and elapsed >= 7.0:
		refuerzos = false
		enemies.append(Combatiente.new("minero", Vector2(3, 1.2), 90))
		enemies.append(Combatiente.new("minero", Vector2(6, 1.1), 95))
	virotes = virotes.filter(func(virote: VIROTE) -> bool: return avanzar_virote(virote, delta))
	for shot in shots:
		shot.time -= delta
	shots = shots.filter(func(shot: Dictionary) -> bool: return shot.time > 0)
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var screen_move := keyboard + stick
	screen_move += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	walk(player, (world(ORIGIN + screen_move) * 35.0).limit_length(), 3.5 * delta)
	if Input.is_physical_key_pressed(KEY_SPACE):
		action(0)
	for i in allies.size():
		if allies[i].health > 0:
			update_ally(allies[i], i, delta)
	for unit in enemies:
		if unit.health > 0:
			update_enemy(unit, delta)
	allies = allies.filter(func(unit: Combatiente) -> bool: return unit.health > 0)
	if planta == 5:
		for unit in enemies:
			if unit.health <= 0 and unit.role == "minero":
				cadaveres.append(unit.position)
	enemies = enemies.filter(func(unit: Combatiente) -> bool: return unit.health > 0)
	if player.health <= 0:
		virotes.clear()
		state = "death"
	elif enemies.is_empty() and not refuerzos:
		virotes.clear()
		stick = Vector2.ZERO
		stick_id = -1
		var paso := PLANTAS.PLANO if planta == 3 and wave == 1 else planta
		if elite:
			paso = PLANTAS.ELITE if planta == 2 else PLANTAS.FORJA_ELITE
		grant_reward(paso)

func grant_reward(paso: int) -> void:
	var datos: Dictionary = PLANTAS.DATOS[planta - 1]
	var experiencia: int = datos.xp
	var botin: int = datos.botin
	if paso == PLANTAS.PLANO:
		experiencia = 40
		botin = 3
	elif paso == PLANTAS.ELITE:
		experiencia = 35
		botin = 2
	elif paso == PLANTAS.FORJA_ELITE:
		experiencia = 65
		botin = 13
	var entregado := paso in progreso.recompensas
	var nuevo := botin not in progreso.inventario
	var previo := progreso.nivel()
	save_failed = progreso.registrar(paso, experiencia, botin) != OK
	recompensa_pendiente = paso if save_failed else -1
	state = "relic" if paso == PLANTAS.PLANO else "won"
	if save_failed:
		return
	reward_text = "Recompensa ya entregada" if entregado else "+%d XP · +%d cobre" % [experiencia, Progreso.premio_cobre(paso)]
	if nuevo and not entregado:
		reward_text += " · " + Progreso.OBJETOS[botin][0]
	if progreso.nivel() > previo:
		player.maximum_health += (progreso.nivel() - previo) * 5
		reward_text += " · Nv. %d" % progreso.nivel()

func aceptar_elite() -> void:
	elite = true
	player.health = minf(player.maximum_health, player.health + 35)
	reiniciar_poses()
	elapsed = 0.0
	marked = null
	if planta == 7:
		enemies.append(Combatiente.new("verdugo", Vector2(8.6, 7.1), 210))
		enemies.append(Combatiente.new("corista", Vector2(10.5, 8.2), 113))
	else:
		enemies.append(Combatiente.new("capataz", Vector2(8.6, 8.7), 145))
		enemies.append(Combatiente.new("minero", Vector2(10.5, 8.7), 72))
	state = "play"

func reiniciar_poses() -> void:
	for unit: Combatiente in [player] + allies:
		unit.last_move = -1.0
		unit.last_strike = -10.0
	guardia_visual = 0.0

func update_ally(unit: Combatiente, index: int, delta: float) -> void:
	var target := marked if is_instance_valid(marked) and marked.health > 0 else closest(enemies, unit.position)
	var offset := Vector2.from_angle(index * TAU / allies.size()) * 0.95
	var ranged := unit.role == "ballestero"
	var reach := 4.4 if ranged else 0.85
	if regroup > 0 or target == null or (target != marked and target.position.distance_to(player.position) > 3.4):
		toward(unit, player.position + offset, 4.2, delta)
		return
	var distance := unit.position.distance_to(target.position)
	if ranged and distance < 2.0:
		walk(unit, (unit.position - target.position).normalized(), 2.7 * delta)
	elif distance > reach or not clear_line(unit.position, target.position):
		var destination := target.position
		if distance > reach and ranged:
			destination = target.position.lerp(unit.position, 0.45)
		toward(unit, destination, 3.8 if unit.role == "sabueso" and target == marked else 3.2, delta)
	elif unit.cooldown <= 0:
		var coordination := 1.0 if target == marked else 0.35
		if ranged:
			shoot(unit, target, (12 + progreso.bonus("virotes")) * coordination, piercing or progreso.bonus("cal") > 0)
		else:
			var damage := 12 + progreso.bonus("sabuesos") if unit.role == "sabueso" else 10
			unit.last_strike = elapsed
			if not unit.position.is_equal_approx(target.position):
				unit.rumbo = unit.position.direction_to(target.position)
			var remate := unit.role == "sabueso" and target == marked and target.health <= target.maximum_health * 0.35
			target.hurt(damage * coordination * (1.40 if remate else 1.0))
			if remate and target.health <= 0:
				unit.health = minf(unit.maximum_health, unit.health + 10.0)
			if unit.role == "guardian":
				target.cooldown = maxf(target.cooldown, 0.22)
		unit.cooldown = 1.0 if ranged else 0.76

func update_enemy(unit: Combatiente, delta: float) -> void:
	var target := player if unit.role == "acechador" else closest([player] + allies, unit.position)
	if not target:
		return
	var guardian: Combatiente
	for ally in allies:
		if ally.health > 0 and ally.role == "guardian":
			guardian = ally
			if ally.position.distance_to(unit.position) < (0.95 if unit.role == "acechador" else 2.5):
				target = ally
			break
	if unit.role == "enterrador":
		if unit.windup > 0:
			unit.windup -= delta
			if unit.windup <= 0:
				for i in mini(2, cadaveres.size()):
					enemies.append(Combatiente.new("reanimado", cadaveres.pop_front(), 50))
			return
		if not cadaveres.is_empty() and unit.cooldown <= 0:
			unit.windup = 2.4
			unit.cooldown = 7.0
			return
	if unit.role == "corista":
		var herido: Combatiente
		for enemigo in enemies:
			if enemigo != unit and enemigo.health > 0 and enemigo.health < enemigo.maximum_health - 12 and enemigo.position.distance_to(unit.position) <= 4.0:
				herido = enemigo
				break
		if unit.windup > 0:
			unit.windup -= delta
			if unit.windup <= 0:
				unit.last_strike = elapsed
				for enemigo in enemies:
					if enemigo != unit and enemigo.health > 0 and enemigo.position.distance_to(unit.position) <= 4.0 and clear_line(unit.position, enemigo.position):
						enemigo.health = minf(enemigo.health + 30.0, enemigo.maximum_health)
			return
		if unit.cooldown <= 0 and herido != null:
			unit.windup = 1.55
			unit.cooldown = 6.4
			return
	if unit.role == "campanero" and campanada(unit, delta):
		return
	if unit.role not in ["capataz", "verdugo"]:
		if unit.windup > 0:
			unit.windup -= delta
			if unit.windup <= 0:
				swing(unit)
			return
		if unit.position.distance_to(target.position) <= 1.15 and clear_line(unit.position, target.position):
			if unit.cooldown <= 0:
				unit.destination = target.position
				unit.windup = 0.62 if unit.role in ["reanimado", "acechador"] else 0.72
				unit.cooldown = 1.8
		else:
			toward(unit, target.position, 1.0 if unit.slow > 0 else (2.7 if unit.role == "acechador" else 2.25), delta)
		return
	if unit.windup > 0:
		unit.windup -= delta
		if unit.windup <= 0:
			unit.last_strike = elapsed
			var start_at := unit.position
			var intercepted := guardian and Geometry2D.get_closest_point_to_segment(guardian.position, start_at, unit.destination).distance_to(guardian.position) < 0.72
			var end := guardian.position if intercepted else unit.destination
			for step in range(8):
				walk(unit, (end - unit.position).normalized(), minf(0.55, end.distance_to(unit.position)))
			if intercepted:
				guardian.hurt(16)
				if retaliation:
					for ally in allies:
						if ally.role == "ballestero" and ally.health > 0 and clear_line(ally.position, unit.position):
							shoot(ally, unit, 17 + progreso.bonus("virotes"))
			elif Geometry2D.get_closest_point_to_segment(player.position, start_at, unit.position).distance_to(player.position) < 0.6:
				hurt_player(6 if guard > 0 else 32)
		return
	if unit.role in ["capataz", "verdugo"] and unit.cooldown <= 0 and unit.position.distance_to(player.position) < 5 and clear_line(unit.position, player.position):
		unit.destination = player.position
		unit.windup = 0.96 if unit.role == "verdugo" else 0.85
		unit.cooldown = 3.8
	elif unit.position.distance_to(target.position) > 0.78 or not clear_line(unit.position, target.position):
		toward(unit, target.position, 0.9 if unit.slow > 0 else 2.25, delta)
	elif unit.cooldown <= 0:
		if target == player:
			hurt_player(3 if guard > 0 else 13)
		else:
			target.hurt(13)
		unit.cooldown = 1.12

func campanada(unit: Combatiente, delta: float) -> bool:
	if not eco_invocado and unit.health < unit.maximum_health * 0.48:
		eco_invocado = true
		enemies.append(Combatiente.new("reanimado", Vector2(9.8, 3.65), 64))
		enemies.append(Combatiente.new("reanimado", Vector2(4.8, 8.2), 64))
	if unit.windup > 0:
		unit.windup -= delta
		if unit.windup <= 0:
			unit.last_strike = elapsed
			for objetivo: Combatiente in [player] + allies:
				if objetivo.position.distance_to(unit.position) <= 2.1 and clear_line(unit.position, objetivo.position):
					if objetivo == player:
						hurt_player(9 if guard > 0 else 33)
					else:
						objetivo.hurt(20)
		return true
	if unit.cooldown <= 0 and unit.position.distance_to(player.position) <= 3.8:
		unit.windup = 1.30
		unit.cooldown = 4.65
		return true
	toward(unit, player.position, 1.45, delta)
	return true

func franja_brasas() -> Rect2:
	return BRASAS[floori(elapsed / 9.0) % BRASAS.size()]

func swing(attacker: Combatiente) -> void:
	attacker.last_strike = elapsed
	var damage := (27.0 if attacker.role == "acechador" else 19.0) + planta * 2
	for unit: Combatiente in [player] + allies:
		if unit.position.distance_to(attacker.destination) > 0.82 or not clear_line(attacker.position, unit.position):
			continue
		if unit == player:
			hurt_player(damage * (0.25 if guard > 0 else 1.0))
		else:
			unit.hurt(damage * (0.65 if unit.role == "guardian" else 1.0))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F or (ritual and event.physical_keycode == KEY_ESCAPE):
			toggle_ritual()
			return
		var invocacion := TECLAS_INVOCACION.find(event.physical_keycode)
		if invocacion >= 0:
			cambiar_invocacion(invocacion, true)
			return
		if ritual:
			return
		match event.physical_keycode:
			KEY_1: choose(0)
			KEY_2: choose(1)
			KEY_3: choose(2)
			KEY_R:
				if state in ["won", "death"]:
					if town_visit:
						return_to_town.emit(state == "won")
					else:
						state = "menu"
				else:
					recall()
			KEY_E: action(2)
			KEY_SHIFT: action(3)
	elif event is InputEventScreenTouch:
		pointer(event.position, event.index, event.pressed)
	elif event is InputEventScreenDrag and event.index == stick_id:
		stick = ((event.position - JOYSTICK) / 47.0).limit_length()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		pointer(event.position, 100, event.pressed)
	elif event is InputEventMouseMotion and stick_id == 100:
		stick = ((event.position - JOYSTICK) / 47.0).limit_length()

func options() -> Array[String]:
	if save_failed:
		return ["1   Reintentar guardado", "2   Volver a Valdebronce"]
	if state == "won":
		var choices: Array[String] = []
		if planta < PLANTAS.DATOS.size():
			choices.append("1   Continuar a " + PLANTAS.nombre(planta + 1))
		choices.append("%d   Volver a Valdebronce" % (choices.size() + 1))
		if planta == 2 and PLANTAS.ELITE not in progreso.recompensas:
			choices.append("3   Desvío de élite · Diente de ceniza +35 XP")
		if planta == 7 and PLANTAS.FORJA_ELITE not in progreso.recompensas:
			choices.append("3   Horno sellado · Talismán del horno")
		return choices
	if state == "death":
		return ["1   Volver a Valdebronce"]
	if state == "relic":
		return ["1   Virotes perforantes · Atraviesan enemigos",
			"2   Salva de represalia" if tiene_custodio() else "2   Campana de refuerzo",
			"3   Bálsamo de la mina · Recupera toda tu salud"]
	return ["1   Formación mixta", "2   Guardia de Mara" if progreso.hallazgo else "2   Guardia de Mara · Requiere el plano", "3   Enjambre"]

func choose(index: int) -> void:
	if state == "play" or index >= options().size():
		return
	if save_failed and index == 0:
		grant_reward(recompensa_pendiente)
	elif state == "won" and not save_failed and index == 0 and planta < PLANTAS.DATOS.size():
		entrar_planta(planta + 1)
	elif state == "won" and not save_failed and index == 2 and planta in [2, 7]:
		aceptar_elite()
	elif state in ["won", "death"] or save_failed:
		if town_visit:
			return_to_town.emit(state == "won" and not save_failed)
		else:
			state = "menu"
	elif state == "relic":
		seleccionar_reliquia(index)
	elif index != 1 or progreso.hallazgo:
		start(index == 2, index == 1)

func pointer(at: Vector2, id: int, down: bool) -> void:
	if not down:
		if id == stick_id:
			stick_id = -1
			stick = Vector2.ZERO
		return
	if ritual:
		if CERRAR_RITUAL.has_point(at):
			toggle_ritual()
		else:
			for index in INVOCACIONES.size():
				for add_unit: bool in [false, true]:
					if ritual_slot(index, add_unit).has_point(at):
						cambiar_invocacion(index, add_unit)
		return
	if state == "play" and INVOCAR.has_point(at):
		toggle_ritual()
		return
	if state != "play":
		for index in options().size():
			if menu_button(index).has_point(at):
				choose(index)
				return
		return
	if at.distance_to(JOYSTICK) < 85 and stick_id == -1:
		stick_id = id
		stick = ((at - JOYSTICK) / 47.0).limit_length()
		return
	for index in INVOCACIONES.size():
		if boton_invocacion(index).has_point(at):
			cambiar_invocacion(index, true)
			return
	for index in BUTTONS.size():
		if at.distance_to(BUTTONS[index]) < 40:
			action(index)
			return
	var best := 31.0
	for unit in enemies:
		var distance := at.distance_to(sobre_suelo(unit.position) - Vector2(0, 32))
		if distance < best:
			marked = unit
			regroup = 0
			best = distance

func menu_button(index: int) -> Rect2:
	return Rect2(342, 315 + index * 57, 468, 46)

func surface(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array([iso(rect.position), iso(Vector2(rect.end.x, rect.position.y)), iso(rect.end), iso(Vector2(rect.position.x, rect.end.y))])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, color.darkened(0.3), 1.5, true)

func label(at: Vector2, value: String, size := 18, color := Color("#e3cba5")) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_crecida() -> void:
	if flood < 6.4:
		return
	var inundada := flood >= 9.0
	label(Vector2(32, 162), "¡INUNDACIÓN!  ·  Cruza por la pasarela" if inundada else "COMPUERTA ABRIENDO  ·  Busca la pasarela", 16, Color("#fff0b1"))

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("#141114"))
	if is_instance_valid(escenario):
		draw_texture(escenario.get_texture(), Vector2.ZERO)
		if planta == 3:
			draw_crecida()
		elif planta == 7 and fmod(elapsed, 9.0) >= 4.3:
			surface(franja_brasas(), Color("#e0523d75") if fmod(elapsed, 9.0) >= 6.2 else Color("#eab94563"))
	if not player:
		return
	var items := [player] + allies + enemies
	if refuerzos:
		surface(Rect2(2.4, 0.6, 4.5, 1.15), Color("#e1905555"))
		label(iso(Vector2(3.1, 1.3)), "Refuerzos en %d s" % ceili(7.0 - elapsed), 15)
	for cuerpo in cadaveres:
		draw_circle(iso(cuerpo), 6, Color("#9eb77a"))
	items.sort_custom(func(a: Combatiente, b: Combatiente) -> bool: return iso(a.position).y < iso(b.position).y)
	for unit: Combatiente in items:
		if unit.role == "enterrador" and unit.windup > 0:
			draw_arc(iso(unit.position), 31, 0, TAU, 32, Color("#dbfa9b"), 4, true)
			label(iso(unit.position) - Vector2(55, 104), "¡REANIMACIÓN!", 15, Color("#e5ffac"))
		elif unit.windup > 0 and unit.role in ["corista", "campanero"]:
			draw_set_transform(sobre_suelo(unit.position), 0.0, Vector2(1, 0.51))
			draw_arc(Vector2.ZERO, 82 if unit.role == "campanero" else 29, 0, TAU, 40, Color("#eab382") if unit.role == "campanero" else Color("#c9ee9d"), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			label(sobre_suelo(unit.position) - Vector2(43, 115), "¡CAMPANADA!" if unit.role == "campanero" else "Cántico", 15)
		elif unit.windup > 0 and unit.role in ["capataz", "verdugo"]:
			draw_line(sobre_suelo(unit.position), sobre_suelo(unit.destination), Color("#ff8954aa"), 15, true)
		elif unit.windup > 0:
			var danger := sobre_suelo(unit.destination)
			draw_set_transform(danger, 0.0, Vector2(1.0, 0.51))
			draw_circle(Vector2.ZERO, 32, Color("#dd5b443b"))
			draw_arc(Vector2.ZERO, 32, 0, TAU, 32, Color("#ffaa70"), 2.5, true)
			draw_set_transform(Vector2.ZERO)
	draw_rituales_visuales()
	for unit: Combatiente in items:
		draw_unit(unit)
	for shot in shots:
		draw_line(sobre_suelo(shot.from) - Vector2(0, 16), sobre_suelo(shot.to) - Vector2(0, 16), Color("#ffe3a9"), 2.0, true)
	label(Vector2(32, 39), "LAS CAMPANAS DEL UMBRAL", 21)
	label(Vector2(32, 66), PLANTAS.nombre(planta).to_upper(), 15)
	draw_rect(Rect2(32, 82, 220, 12), Color("#3a2427"))
	draw_rect(Rect2(32, 82, 220 * player.health / player.maximum_health, 12), Color("#a6433d"))
	if state == "play":
		draw_rect(INVOCAR, Color("#372631"))
		draw_rect(INVOCAR, Color("#a07654"), false, 1)
		label(INVOCAR.position + Vector2(16, 28), "Invocaciones [F]", 17)
		draw_rect(Rect2(300, 537, 532, 103), Color("#141018f5"))
		var estado_campana := "Campana lista" if bell_cooldown <= 0 else "Recarga de invocación: %.1f s" % bell_cooldown
		label(Vector2(320, 562), "%d/6 vínculos  ·  %s" % [vinculos_ocupados(), estado_campana], 18, Color("#fff0d5"))
		for index in INVOCACIONES.size():
			var rect := boton_invocacion(index)
			var listo := motivo_invocacion(index).is_empty()
			draw_rect(rect, Color("#4e3950") if listo else Color("#28222d"))
			draw_rect(rect, Color("#e3cba5") if listo else Color("#847788"), false, 2)
			label(rect.position + Vector2(9, 23), ETIQUETAS_INVOCACION[index], 17, Color("#fff0d5"))
			label(rect.position + Vector2(9, 44), "%d activos · %d vínculo%s" % [cantidad_invocada(INVOCACIONES[index]), 2 if index == 2 else 1, "s" if index == 2 else ""], 13)
		label(Vector2(32, 115), "Nv. %d  ·  Vida %d/%d  ·  Enemigos %d" % [progreso.nivel(), ceili(player.health), ceili(player.maximum_health), enemies.size()], 16)
		label(Vector2(925, 441), "Defensa %.1f s" % defense_cooldown, 15)
		var relic_names := ["Virotes perforantes", "Salva de represalia" if retaliation else "Campana de refuerzo", "Bálsamo de la mina"]
		if blessed:
			label(Vector2(32, 160), "Bendición de Elías", 15, Color("#b4cfcb"))
		label(Vector2(32, 138), "Oleada %d/2 · %s" % [wave, relic_names[relic] if relic_taken else "Reliquia por descubrir"] if planta == 3 else PLANTAS.DATOS[planta - 1].aviso, 14)
		if planta < PLANTAS.DATOS.size():
			label(Vector2(770, 39), "Siguiente · " + PLANTAS.nombre(planta + 1), 15)
		draw_circle(JOYSTICK, 57, Color("#1e181cbb"))
		draw_arc(JOYSTICK, 57, 0, TAU, 48, Color("#998061"), 2.0, true)
		draw_circle(JOYSTICK + stick * 37, 23, Color("#695244"))
		var names := ["Ataque", "Reagrupar", "Orden", "Defensa"]
		var keys := ["ESPACIO", "R", "E", "MAYÚS"]
		for i in BUTTONS.size():
			var at: Vector2 = BUTTONS[i]
			draw_circle(at, 37, Color("#241c1fee"))
			draw_arc(at, 37, 0, TAU, 48, Color("#a28153"), 2.0, true)
			var name: String = names[i]
			label(at + Vector2(-name.length() * 3.8, 1), name, 14)
			label(at + Vector2(-11, 19), keys[i], 8)
	else:
		draw_rect(Rect2(310, 185, 532, 320), Color("#1c1619f4"))
		draw_rect(Rect2(310, 185, 532, 320), Color("#997149"), false, 2)
		var title := "Elige tu formación"
		if state == "relic": title = "Elige una reliquia"
		if state == "won": title = "Campanario silenciado" if planta == PLANTAS.DATOS.size() else "Sala asegurada"
		if state == "death": title = "El Vinculador ha caído"
		label(Vector2(342, 244), title, 29)
		var subtitle := "Invoca tu propio séquito al entrar en la mina."
		var choices := options()
		if state in ["won", "relic"]:
			subtitle = reward_text
		if state == "death":
			subtitle = "Conservas XP, equipo, talentos y accesos."
		if save_failed:
			subtitle = "No se pudo guardar la recompensa."
		label(Vector2(342, 278), subtitle, 16)
		for i in choices.size():
			var rect := menu_button(i)
			draw_rect(rect, Color("#3c2d29"))
			label(rect.position + Vector2(14, 29), choices[i], 17)

	if ritual:
		draw_ritual()

func draw_rituales_visuales() -> void:
	if guardia_visual > 0:
		var color_guardia := Color("#e3cb9b")
		color_guardia.a = guardia_visual / 0.26 * 0.84
		draw_line(sobre_suelo(guardia_origen) - Vector2(0, 24), sobre_suelo(player.position) - Vector2(0, 27), color_guardia, 2.1, true)
	for efecto in rituales_visuales:
		var avance := 1.0 - float(efecto.tiempo) / RITUAL_DURACION
		var base := sobre_suelo(efecto.at)
		var color := Color("#a2e6ba")
		color.a = (1.0 - avance) * 0.82
		draw_set_transform(base, 0.0, Vector2(1, 0.50))
		draw_arc(Vector2.ZERO, 12 + avance * 22, 0, TAU, 28, color, 1.8, true)
		draw_arc(Vector2.ZERO, 8 + avance * 16, 0, TAU, 24, color.darkened(0.24), 1.2, true)
		draw_set_transform(Vector2.ZERO)
		for i in 5:
			var giro := float(i) * TAU / 5.0 + avance * 1.3
			var punto := base + Vector2(cos(giro) * (10.0 + avance * 9.0), sin(giro) * 6.0 - avance * 42)
			draw_circle(punto, 1.6 - avance * 0.7, color)

func rol_de_sprite(unit: Combatiente) -> String:
	if unit.role in ["enterrador", "campanero", "verdugo"]:
		return "capataz"
	if unit.role in ["reanimado", "acechador", "corista"]:
		return "minero"
	return unit.role

func actualizar_virotes_3d() -> void:
	for virote in modelos_virotes.keys():
		if virote not in virotes:
			modelos_virotes[virote].queue_free()
			modelos_virotes.erase(virote)
	for virote in virotes:
		if virote not in modelos_virotes:
			modelos_virotes[virote] = escenario.crear_virote(virote.ralentiza, virote.grillete)
		var nivel := ESCENARIO.altura(virote.posicion) if planta == 3 else 0.0
		modelos_virotes[virote].actualizar(virote.posicion, virote.direccion, nivel)

func _process(delta: float) -> void:
	if not is_instance_valid(escenario):
		return
	actualizar_virotes_3d()
	var presentes: Array[Combatiente] = [player]
	presentes.append_array(allies)
	presentes.append_array(enemies)
	for unit in figuras.keys():
		if unit not in presentes:
			figuras[unit].queue_free()
			figuras.erase(unit)
	for unit in presentes:
		if unit not in figuras:
			figuras[unit] = escenario.crear_figura()
		var role := rol_de_sprite(unit)
		var sprite: Texture2D = sprites[role]
		var altura: float = ALTURAS[role]
		var nivel_pies := ESCENARIO.altura(unit.position) if planta == 3 else 0.0
		var pies := Vector3(unit.position.x, nivel_pies, unit.position.y)
		var marcha := elapsed - unit.last_move < 0.10
		var fase := elapsed * (12.0 if marcha else 3.0) + unit.position.x
		var tint := Color.WHITE
		if unit.flash > 0:
			tint = Color("#ffafa1")
		elif unit.role in ["enterrador", "reanimado"]:
			tint = Color("#bfe4a9")
		elif unit.role == "acechador":
			tint = Color("#f0a898")
		if unit == player:
			tint *= Color.WHITE.lerp(progreso.color_vinculador(), 0.74)
		var golpe := clampf(1.0 - (elapsed - unit.last_strike) / 0.24, 0.0, 1.0)
		if unit.windup > 0:
			golpe = maxf(golpe, 0.32)
		var figura := figuras[unit]
		figura.actualizar(pies, escenario.camara, sprite, altura,
			23.0 if role in ["guardian", "capataz"] else 18.0,
			unit.facing_right, tint, fase, marcha, ESCENARIO.ESCALA, escenario.malla_sombra, golpe, unit.role, progreso.aspecto, delta, unit.rumbo)
		if unit == player:
			escenario.mover_farol_vinculador(pies, unit.facing_right, elapsed, golpe, figura.modelo.punto_farol.global_position)
			escenario.actualizar_ocultacion(pies, delta)

func draw_unit(unit: Combatiente) -> void:
	var at := sobre_suelo(unit.position)
	var height: float = ALTURAS[rol_de_sprite(unit)]
	var width := 18.0 if unit.role in ["guardian", "capataz"] else 13.0
	var ring: Color = Color("#f5846a") if unit == marked else ANILLOS.get(unit.role, Color.WHITE)
	if unit == player or unit == marked or unit in allies:
		draw_set_transform(at, 0.0, Vector2(1, 0.56))
		draw_arc(Vector2.ZERO, width + 5, 0, TAU, 40, Color("#170f16"), 4.3, true)
		draw_arc(Vector2.ZERO, width + 5, 0, TAU, 40, ring, 2.15 if unit == player else 1.65, true)
		draw_set_transform(Vector2.ZERO)
	if unit != player and (unit in enemies or unit.health < unit.maximum_health):
		var bar := at - Vector2(14, height + 8)
		draw_rect(Rect2(bar, Vector2(28, 4)), Color("#201618"))
		draw_rect(Rect2(bar, Vector2(28 * unit.health / unit.maximum_health, 4)), Color("#c65e4e") if unit in enemies else Color("#91b582"))
