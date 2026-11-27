extends SceneTree

const Perfil = preload("res://progreso.gd")
const Plantas = preload("res://plantas.gd")
const Mina = preload("res://mina.tscn")
const Pueblo = preload("res://valdebronce.tscn")
const PASO := 1.0 / 60.0
var tmp := OS.get_environment("UMBRAL_TEST_DIR")
var archivos := 0
var resultados: Array[Dictionary] = []
var escena: Node
const MIXTA := [0, 0, 1, 1, 2]
const ENJAMBRE := [0, 0, 0, 0, 1, 1]

func _initialize() -> void:
	call_deferred("run")

func perfil():
	var datos := Perfil.new()
	archivos += 1
	datos.ruta_guardado = tmp.path_join("perfil-%d.cfg" % archivos)
	return datos

func mina(planta := 1, enjambre := false, con_sequito := true):
	var batalla := Mina.instantiate()
	batalla.progreso = perfil()
	batalla.progreso.tramo = planta
	root.add_child(batalla)
	batalla.set_physics_process(false)
	batalla.set_process(false)
	batalla.start(enjambre, false, planta)
	if con_sequito:
		for tipo: int in ENJAMBRE if enjambre else MIXTA:
			batalla.bell_cooldown = 0
			batalla.cambiar_invocacion(tipo, true)
	escena = batalla
	return batalla

func adversario(batalla: Node, posicion := Vector2(4, 7), vida := 60.0) -> Combatiente:
	var enemigo := Combatiente.new("minero", posicion, vida)
	batalla.enemies.assign([enemigo])
	return enemigo

func run() -> void:
	if tmp.is_empty() or not DirAccess.dir_exists_absolute(tmp):
		printerr("Usa qa/godot/run.sh para crear un directorio separado de partidas.")
		quit(2)
		return
	var casos := [
		["C01 | La mina empieza sin esbirros ni ritual abierto", c01],
		["C02 | Las teclas Z, X y C invocan su propio esbirro", c02],
		["C03 | El custodio ocupa dos vínculos", c03],
		["C04 | Reagrupar elimina la marca", c04],
		["C05 | El ritual pausa la simulación", c05],
		["C06 | El virote impacta tras viajar", c06],
		["C07 | El pilar detiene el virote", c07],
		["C08 | Un virote normal se detiene en el primer enemigo", c08],
		["C09 | El virote perforante golpea dos objetivos", c09],
		["C10 | El tercer virote ralentiza", c10],
		["C11 | El amuleto de cal ralentiza al perforar", c11],
		["C12 | El sabueso se cura al rematar al marcado", c12],
		["C13 | El custodio cercano absorbe daño", c13],
		["C14 | La pasarela protege de la inundación", c14],
		["C15 | Los botones táctiles respetan la recarga compartida", c15],
		["C16 | Una baja libera vínculos sin resucitar sola", c16],
		["C17 | Continuar conserva vivos y un nuevo intento empieza vacío", c17],
		["C18 | La ayuda inicial tiene foco y se puede reabrir", c18],
		["P01 | La expedición empieza en la Bocamina", p01],
		["P02 | Se gana experiencia y se desbloquea la planta siguiente", p02],
		["P03 | No se duplica el botín al repetir una victoria", p03],
		["P04 | El plano de Mara queda registrado", p04],
		["P05 | El progreso se recupera desde disco", p05],
		["P06 | Un guardado antiguo de la −5 abre la −6", p06],
		["P07 | Una expedición no salta a plantas bloqueadas", p07],
		["P08 | La derrota mantiene el equipo guardado", p08],
		["P09 | El ascensor conserva el progreso al volver al pueblo", p09],
		["P10 | La primera victoria de la −7 abre el Horno sellado", p10],
		["P11 | La élite del Horno deja el Talismán", p11],
		["P12 | La formación mixta completa las ocho plantas", p12],
		["P13 | El enjambre completa las ocho plantas", p13],
		["P14 | El final da el Corazón de la campana", p14],
		["E01 | Comprar descuenta el precio y entrega la pieza", e01],
		["E02 | La tienda rechaza saldo insuficiente", e02],
		["E03 | No se puede comprar dos veces la misma pieza", e03],
		["E04 | El equipo activa su bonificación", e04],
		["E05 | No se vende una pieza equipada", e05],
		["E06 | Venta y recompra conservan el precio", e06],
		["E07 | Se cobra un contrato tras completar su objetivo", e07],
		["E08 | Un contrato no se cobra dos veces", e08],
	]
	print("1..%d" % casos.size())
	for i in casos.size():
		var caso: Array = casos[i]
		var prueba: Callable = caso[1]
		var correcto: Variant = prueba.call()
		resultados.append({"name": caso[0], "passed": correcto == true})
		print("%s %d - %s" % ["ok" if correcto == true else "not ok", i + 1, caso[0]])
		if is_instance_valid(escena):
			escena.free()
		escena = null
		await process_frame
	var aprobados := resultados.filter(func(caso: Dictionary) -> bool: return caso.passed).size()
	print("Godot: %d/%d casos aprobados." % [aprobados, casos.size()])
	quit(0 if aprobados == casos.size() else 1)

func pulsar(nodo: Node, tecla: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	evento.pressed = true
	nodo._input(evento)

func c01() -> bool:
	var m = mina(1, false, false)
	return m.allies.is_empty() and not m.ritual and m.state == "play"

func c02() -> bool:
	var m = mina(1, false, false)
	for tecla: Key in [KEY_Z, KEY_X, KEY_C]:
		m.bell_cooldown = 0
		pulsar(m, tecla)
	return m.allies.map(func(unit: Combatiente): return unit.role) == ["sabueso", "ballestero", "guardian"]

func c03() -> bool:
	var m = mina(1, true)
	m.bell_cooldown = 0
	m.cambiar_invocacion(2, true)
	if m.tiene_custodio():
		return false
	m.cambiar_invocacion(0, false)
	m.cambiar_invocacion(0, false)
	m.cambiar_invocacion(2, true)
	m.bell_cooldown = 0
	m.cambiar_invocacion(2, true)
	return m.vinculos_ocupados() == 6 and m.cantidad_invocada("guardian") == 1

func c04() -> bool:
	var m = mina()
	m.marked = m.enemies[0]
	m.recall()
	return m.marked == null and m.regroup > 0

func c05() -> bool:
	var m = mina()
	m.toggle_ritual()
	m._physics_process(0.5)
	return m.ritual and m.elapsed == 0.0

func c06() -> bool:
	var m = mina()
	var e := adversario(m)
	m.allies[2].position = Vector2(1, 7)
	m.shoot(m.allies[2], e, 12)
	if e.health != 60 or m.virotes.size() != 1:
		return false
	m.avanzar_virote(m.virotes[0], 0.19)
	return e.health == 48

func c07() -> bool:
	var m = mina(3)
	var e := adversario(m, Vector2(8, 4.2))
	m.allies[2].position = Vector2(4, 4.2)
	m.shoot(m.allies[2], e, 12)
	return not m.avanzar_virote(m.virotes[0], 0.30) and e.health == 60

func c08() -> bool:
	return impactos_en_linea(false)

func c09() -> bool:
	return impactos_en_linea(true)

func impactos_en_linea(perforante: bool) -> bool:
	var m = mina()
	var primero := adversario(m, Vector2(3, 7))
	var segundo := Combatiente.new("minero", Vector2(4, 7), 60)
	m.enemies.push_front(segundo)
	m.allies[2].position = Vector2(1, 7)
	m.shoot(m.allies[2], segundo, 12, perforante)
	m.avanzar_virote(m.virotes[0], 0.25)
	return primero.health == 48 and segundo.health == (51 if perforante else 60)

func c10() -> bool:
	var m = mina()
	var e := adversario(m)
	m.allies[2].position = Vector2(1, 7)
	for i in 3:
		m.shoot(m.allies[2], e, 1)
	m.avanzar_virote(m.virotes[2], 0.19)
	return not m.virotes[0].grillete and m.virotes[2].grillete and e.slow >= 1.45

func c11() -> bool:
	var m = mina()
	var e := adversario(m)
	m.allies[2].position = Vector2(1, 7)
	m.progreso.equipo[2] = 6
	m.shoot(m.allies[2], e, 1, true)
	m.avanzar_virote(m.virotes[0], 0.19)
	return e.slow == 2.0

func c12() -> bool:
	var m = mina()
	var e := adversario(m, Vector2(3, 7))
	m.marked = e
	e.health = 15
	m.allies[0].position = Vector2(2.5, 7)
	m.allies[0].health = 10
	m.update_ally(m.allies[0], 0, PASO)
	return e.health == 0 and m.allies[0].health == 20

func c13() -> bool:
	var m = mina()
	var guardian: Combatiente = m.allies[4]
	guardian.position = m.player.position + Vector2(1, 0)
	m.hurt_player(20)
	return is_equal_approx(m.player.health, 85.6) and is_equal_approx(guardian.health, 94.4)

func c14() -> bool:
	var m = mina(3)
	m.elapsed = 9.5
	m.player.position = Vector2(8, 1.5)
	m.allies[0].position = Vector2(8, 2.3)
	var vida: float = m.allies[0].health
	m._physics_process(PASO)
	return m.player.health == 100 and m.allies[0].health < vida

func c15() -> bool:
	var m = mina(1, false, false)
	m.pointer(m.boton_invocacion(0).get_center(), 0, true)
	m.pointer(m.boton_invocacion(1).get_center(), 1, true)
	if m.allies.size() != 1:
		return false
	m._physics_process(2.5)
	m.pointer(m.boton_invocacion(1).get_center(), 1, true)
	return m.cantidad_invocada("ballestero") == 1

func c16() -> bool:
	var m = mina()
	m.allies.back().health = 0
	m._physics_process(PASO)
	m.recall()
	return not m.tiene_custodio() and m.vinculos_ocupados() == 4

func c17() -> bool:
	var m = mina()
	m.allies[0].health = 17
	m.allies.back().health = 0
	m._physics_process(PASO)
	m.grant_reward(1)
	m.choose(0)
	if m.planta != 2 or m.allies.size() != 4 or m.allies[0].health != 17:
		return false
	m.start(false, false, 2)
	return m.allies.is_empty()

func c18() -> bool:
	var pueblo := Pueblo.instantiate()
	pueblo.progreso = perfil()
	root.add_child(pueblo)
	escena = pueblo
	if not pueblo.ayuda.visible or not pueblo.continuar_ayuda.has_focus():
		return false
	pulsar(pueblo, KEY_ENTER)
	if pueblo.ayuda.visible:
		return false
	pulsar(pueblo, KEY_H)
	return pueblo.ayuda.visible and pueblo.continuar_ayuda.has_focus()

func p01() -> bool:
	var m = mina()
	return m.planta == 1 and m.enemies.size() == 3 and m.progreso.xp == 0

func p02() -> bool:
	var p = perfil()
	return p.registrar(1, 55, 0) == OK and p.tramo == 2 and p.xp == 55 and p.puntos() == 1

func p03() -> bool:
	var p = perfil()
	if p.registrar(1, 55, 0) != OK or p.registrar(1, 55, 0) != OK:
		return false
	return p.inventario == [0] and p.xp == 55 and p.cobre == Perfil.COBRE_INICIAL + 25

func p04() -> bool:
	var p = perfil()
	return p.registrar(Plantas.PLANO, 40, 3) == OK and p.hallazgo and p.victorias == 0

func p05() -> bool:
	var p = perfil()
	if p.registrar(1, 55, 0) != OK or p.equipar(0) != OK or p.aprender(0) != OK:
		return false
	var nuevo := Perfil.new()
	nuevo.ruta_guardado = p.ruta_guardado
	nuevo.cargar()
	return nuevo.equipo == [0, -1, -1] and nuevo.talentos == [0] and nuevo.xp == 55

func p06() -> bool:
	var p = perfil()
	var antiguo := ConfigFile.new()
	antiguo.set_value("mina", "tramo", 5)
	antiguo.set_value("mina", "recompensas", [1, 2, 3, 4, 5])
	antiguo.set_value("personaje", "xp", 250)
	if antiguo.save(p.ruta_guardado) != OK:
		return false
	p.cargar()
	return p.tramo == 6 and p.xp == 250

func p07() -> bool:
	var m = mina()
	m.entrar_planta(8)
	return m.planta == 1

func p08() -> bool:
	var m = mina()
	if m.progreso.registrar(1, 55, 0) != OK or m.progreso.equipar(0) != OK:
		return false
	m.player.health = 0
	m._physics_process(PASO)
	var nuevo := Perfil.new()
	nuevo.ruta_guardado = m.progreso.ruta_guardado
	nuevo.cargar()
	return m.state == "death" and nuevo.equipo[0] == 0 and nuevo.tramo == 2

func p09() -> bool:
	var pueblo := Pueblo.instantiate()
	pueblo.progreso = perfil()
	root.add_child(pueblo)
	escena = pueblo
	pueblo.descend(1)
	pueblo.battle.grant_reward(1)
	pueblo.battle.choose(1)
	return pueblo.battle == null and pueblo.progreso.tramo == 2 and pueblo.progreso.xp == 55

func p10() -> bool:
	var m = mina(7)
	m.enemies.clear()
	m.grant_reward(7)
	m.choose(2)
	return m.elite and m.state == "play" and m.enemies.size() == 2 and m.enemies.back().role == "corista"

func p11() -> bool:
	var m = mina(7)
	m.enemies.clear()
	m.grant_reward(7)
	m.choose(2)
	m.player.position = Vector2(3.4, 7.2)
	ticks(m)
	return m.state == "won" and 13 in m.progreso.inventario and Plantas.FORJA_ELITE in m.progreso.recompensas

func p12() -> bool:
	return recorrido(false)

func p13() -> bool:
	return recorrido(true)

func p14() -> bool:
	var m = mina(8)
	m.grant_reward(8)
	return m.state == "won" and 12 in m.progreso.inventario and m.options().size() == 1

func recorrido(enjambre: bool) -> bool:
	var m = mina(1, enjambre, false)
	for planta in range(1, 9):
		if m.planta != planta:
			return false
		ticks(m, enjambre)
		if planta == 3 and m.state == "relic":
			m.choose(1 if enjambre else 0)
			ticks(m, enjambre)
		if m.state != "won" or m.save_failed:
			return false
		if planta == 1 and (m.progreso.equipar(0) != OK or m.progreso.aprender(6 if enjambre else 3) != OK):
			return false
		if planta < 8:
			m.choose(0)
	return m.progreso.tramo == 8 and 12 in m.progreso.inventario

func ticks(m: Node, enjambre := false) -> void:
	var composicion := [4, 2, 0] if enjambre else [2, 2, 1]
	var prioridad := [0, 1, 2] if enjambre else [2, 1, 0]
	for i in 5400:
		if m.state != "play":
			return
		var objetivo: Combatiente = m.closest(m.enemies, m.player.position)
		if objetivo:
			for unit in m.enemies:
				if unit.role == "enterrador" and (unit.windup > 0 or m.player.position.distance_to(unit.position) < 5.0):
					objetivo = unit
					break
			m.marked = objetivo
			if m.player.position.distance_to(objetivo.position) > 2.3 or not m.clear_line(m.player.position, objetivo.position):
				m.toward(m.player, objetivo.position, 3.5, PASO)
			if i % 66 == 0:
				m.action(2)
		elif m.refuerzos:
			m.toward(m.player, Vector2(3, 3), 3.5, PASO)
		if m.planta == 3 and m.flood >= 6.4 and m.player.position.y < 3.9:
			m.walk(m.player, Vector2.DOWN, 0.14)
			m.recall()
		m.action(0)
		if m.bell_cooldown <= 0:
			for tipo: int in prioridad:
				if m.cantidad_invocada(m.INVOCACIONES[tipo]) < composicion[tipo]:
					pulsar(m, m.TECLAS_INVOCACION[tipo])
					break
		if i % 30 == 0:
			m.action(3)
		m._physics_process(PASO)

func e01() -> bool:
	var p = perfil()
	return p.comprar(7) == OK and 7 in p.inventario and p.cobre == 2

func e02() -> bool:
	var p = perfil()
	return p.comprar(8) == ERR_UNAVAILABLE and p.inventario.is_empty() and p.cobre == 26

func e03() -> bool:
	var p = perfil()
	p.cobre = 100
	return p.comprar(7) == OK and p.comprar(7) == ERR_UNAVAILABLE and p.inventario == [7] and p.cobre == 76

func e04() -> bool:
	var p = perfil()
	return p.comprar(7) == OK and p.equipar(7) == OK and p.equipo[0] == 7 and p.bonus("ataque") == 3

func e05() -> bool:
	var p = perfil()
	return p.comprar(7) == OK and p.equipar(7) == OK and p.vender(7) == ERR_UNAVAILABLE and p.cobre == 2

func e06() -> bool:
	var p = perfil()
	return p.comprar(7) == OK and p.vender(7) == OK and p.precio_compra(7) == 12 and p.comprar(7) == OK and p.cobre == 2

func e07() -> bool:
	var p = perfil()
	if p.cobrar_contrato(0) != ERR_UNAVAILABLE or p.registrar(6, 125, 10) != OK:
		return false
	var saldo: int = p.cobre
	return p.cobrar_contrato(0) == OK and p.cobre == saldo + 36

func e08() -> bool:
	var p = perfil()
	if p.registrar(6, 125, 10) != OK or p.cobrar_contrato(0) != OK:
		return false
	var saldo: int = p.cobre
	return p.cobrar_contrato(0) == ERR_UNAVAILABLE and p.cobre == saldo and p.contratos == [0]
