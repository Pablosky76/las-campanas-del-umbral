extends Node2D

const PROGRESO = preload("res://progreso.gd")
const PLANTAS = preload("res://plantas.gd")
const MINA = preload("res://mina.tscn")
const ASPECTO_BOTON := Rect2(302, 183, 128, 33)
const JOYSTICK := Vector2(106, 548)
const INTERACT := Vector2(1035, 548)
const CENTER := Vector2(574, 446)
const LOCATIONS := [Vector2(282, 323), Vector2(587, 323), Vector2(930, 330), Vector2(142, 388)]
const NAMES := ["Forja de Mara", "Campanario", "Entrada a la mina", "Hospedería de Inés"]
const FORMATIONS := ["Formación mixta", "Guardia de Mara", "Enjambre"]
const COLORS := [Color("#e29562"), Color("#e6c785"), Color("#b5d2c9"), Color("#d3a5a0")]
const GOLD := Color("#e8cda5")
const CHARACTER_PANEL := Rect2(104, 118, 944, 433)
const CHARACTER_CLOSE := Rect2(979, 135, 54, 47)
const TALENT_BUTTON := Rect2(854, 103, 121, 44)
const EQUIP_BUTTON := Rect2(982, 103, 121, 44)
const PANEL := Rect2(340, 218, 472, 312)

const MOCHILA := Rect2(468, 216, 547, 213)
const BOTON_PIEZA := Rect2(842, 471, 167, 48)
const COMPRAR := Rect2(134, 184, 130, 37)
const VENDER := Rect2(274, 184, 130, 37)
const PAGINA_ANT := Rect2(652, 182, 31, 31)
const PAGINA_SIG := Rect2(758, 182, 31, 31)
const DIARIO_TAB := Rect2(284, 186, 162, 40)
const CONTRATO_TAB := Rect2(135, 186, 139, 40)
var pagina_mochila := 0
var pagina_tienda := 0
var ver_diario := false
var aviso_contrato := ""
const TRATO := Rect2(821, 477, 194, 46)
var vendiendo := false
var oferta := -1
var aviso_tienda := ""
var seleccion := -1
var arrastre_id := -1
var arrastre_pieza := -1
var arrastre_pos := Vector2.ZERO
var arrastre_inicio := Vector2.ZERO

var progreso := PROGRESO.new()
var at := CENTER
var dest := CENTER
var stick := Vector2.ZERO
var stick_id := -1
var panel := -1
var formation := 0
var destino_mina := 1
var blessing := false
var travel_to := -1
var battle: Node2D
var facing_right := false
var rumbo := Vector2(0.25, 1.0)
var walking_time := 0.0
var message := ""
const ESCENARIO = preload("res://escenario_3d.gd")
const FONDO_PLAZA = preload("res://arte/valdebronce.png")
var plaza: ESCENARIO
var figura_plaza: Node3D
var tiempo_plaza := 0.0
const AMBIENTE = preload("res://ambiente.gd")
const BOTON_AUDIO := Rect2(982, 55, 121, 34)
var ambiente: AMBIENTE
const BOTON_AYUDA := Rect2(726, 55, 116, 40)
var ayuda: ColorRect
var continuar_ayuda: Button

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	progreso.cargar()
	ambiente = AMBIENTE.new()
	add_child(ambiente)
	plaza = ESCENARIO.new()
	plaza.planta = 0
	add_child(plaza)
	figura_plaza = plaza.crear_figura()
	actualizar_figura_plaza(1.0)
	crear_ayuda()
	mostrar_ayuda()

func crear_ayuda() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	ayuda = ColorRect.new()
	ayuda.size = Vector2(1152, 648)
	ayuda.color = Color("#0e0b12f5")
	capa.add_child(ayuda)
	var contenido := VBoxContainer.new()
	contenido.position = Vector2(208, 55)
	contenido.custom_minimum_size.x = 736
	contenido.add_theme_constant_override("separation", 14)
	ayuda.add_child(contenido)
	var titulo := Label.new()
	titulo.text = "Controles del Vinculador"
	titulo.add_theme_font_size_override("font_size", 36)
	contenido.add_child(titulo)
	var pasos := [
		["Moverte", "WASD o flechas · En táctil, usa el joystick."],
		["Explorar Valdebronce", "Acércate a un edificio y pulsa E o toca su nombre."],
		["Invocar", "Z · Sabueso     X · Ballestero     C · Custodio (2 vínculos)"],
		["Combatir", "Espacio · Atacar     E · Dar la orden     Mayús · Defender"],
		["Dirigir al séquito", "Clic o toque en el objetivo · R o Reagrupar para reunirlo."],
		["Controles en pantalla", "Toca las acciones o las invocaciones para usarlas al instante."],
	]
	for paso in pasos:
		var fila := VBoxContainer.new()
		fila.add_theme_constant_override("separation", 1)
		contenido.add_child(fila)
		var encabezado := Label.new()
		encabezado.text = paso[0]
		encabezado.add_theme_color_override("font_color", Color("#f4ca91"))
		encabezado.add_theme_font_size_override("font_size", 21)
		fila.add_child(encabezado)
		var detalle := Label.new()
		detalle.text = paso[1]
		detalle.add_theme_font_size_override("font_size", 19)
		fila.add_child(detalle)
	continuar_ayuda = Button.new()
	continuar_ayuda.text = "Continuar [Intro]"
	continuar_ayuda.custom_minimum_size = Vector2(0, 58)
	continuar_ayuda.add_theme_font_size_override("font_size", 23)
	continuar_ayuda.pressed.connect(cerrar_ayuda)
	contenido.add_child(continuar_ayuda)

func mostrar_ayuda() -> void:
	stick = Vector2.ZERO
	stick_id = -1
	ayuda.show()
	continuar_ayuda.grab_focus()

func cerrar_ayuda() -> void:
	ayuda.hide()

func _process(delta: float) -> void:
	if is_instance_valid(battle):
		return
	tiempo_plaza += delta
	plaza.actualizar_plaza(tiempo_plaza)
	queue_redraw()
	if ayuda.visible or panel >= 0:
		actualizar_figura_plaza(delta)
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction += Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	direction += stick
	if direction.length_squared() > 0.04:
		dest = constrain(at + direction.limit_length() * 190.0 * delta)
		travel_to = -1
	var previous := at
	at = at.move_toward(dest, 190.0 * delta)
	if previous.distance_squared_to(at) > 0.01:
		walking_time += delta * 12.0
		var movimiento := plaza.coordenada_plaza(at) - plaza.coordenada_plaza(previous)
		rumbo = Vector2(movimiento.x, movimiento.z).normalized()
		if absf(at.x - previous.x) > 0.1:
			facing_right = at.x > previous.x
	else:
		walking_time = 0
	actualizar_figura_plaza(delta)
	if travel_to >= 0 and at.distance_to(LOCATIONS[travel_to]) < 8:
		open_location(travel_to)

func actualizar_figura_plaza(delta: float) -> void:
	var pies := plaza.coordenada_plaza(at)
	figura_plaza.actualizar(pies, plaza.camara, progreso.sprite_vinculador(),
		112.0, 20.0, facing_right, Color.WHITE.lerp(progreso.color_vinculador(), 0.74),
		walking_time if walking_time > 0 else tiempo_plaza * 2.0, walking_time > 0,
		ESCENARIO.ESCALA, plaza.malla_sombra, 0.0, "player", progreso.aspecto, delta, rumbo)
	plaza.mover_farol_vinculador(pies, facing_right, tiempo_plaza, 0.0, figura_plaza.modelo.punto_farol.global_position)

func constrain(point: Vector2) -> Vector2:
	return point.clamp(Vector2(142, 316), Vector2(964, 552))

func nearest() -> int:
	for index in LOCATIONS.size():
		if at.distance_to(LOCATIONS[index]) < 75:
			return index
	return -1

func open_location(index: int) -> void:
	arrastre_id = -1
	arrastre_pieza = -1
	if index == 2:
		destino_mina = progreso.tramo
	panel = index
	stick = Vector2.ZERO
	stick_id = -1
	travel_to = -1
	dest = at

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		ambiente.alternar()
		return
	if is_instance_valid(battle):
		return
	if ayuda.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode in [KEY_ENTER, KEY_ESCAPE, KEY_H, KEY_SPACE]:
				cerrar_ayuda()
				get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_H:
				mostrar_ayuda()
			KEY_E, KEY_ENTER:
				if panel == 2:
					descend(destino_mina)
				elif panel == 1:
					choose(0)
				elif panel < 0 and nearest() >= 0:
					open_location(nearest())
			KEY_ESCAPE:
				panel = 0 if panel == 6 else (3 if panel == 7 else -1)
			KEY_4:
				if panel == 0:
					choose(3)
			KEY_T:
				if panel in [-1, 4, 5]:
					open_location(-1 if panel == 4 else 4)
			KEY_I:
				if panel in [-1, 4, 5]:
					open_location(-1 if panel == 5 else 5)
			KEY_1, KEY_2, KEY_3:
				choose(int(event.physical_keycode) - KEY_1)
	elif event is InputEventScreenTouch:
		pointer(event.position, event.index, event.pressed)
	elif event is InputEventScreenDrag and event.index == arrastre_id:
		arrastre_pos = event.position
	elif event is InputEventScreenDrag and event.index == stick_id:
		stick = ((event.position - JOYSTICK) / 47.0).limit_length()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		pointer(event.position, 100, event.pressed)
	elif event is InputEventMouseMotion and arrastre_id == 100:
		arrastre_pos = event.position
	elif event is InputEventMouseMotion and stick_id == 100:
		stick = ((event.position - JOYSTICK) / 47.0).limit_length()

func pointer(point: Vector2, id: int, pressed: bool) -> void:
	if ayuda.visible:
		return
	if pressed and panel == -1 and BOTON_AYUDA.has_point(point):
		mostrar_ayuda()
		return
	if pressed and BOTON_AUDIO.has_point(point):
		ambiente.alternar()
		return
	if panel == 5:
		mochila_input(point, id, pressed)
		return
	if not pressed:
		if id == stick_id:
			stick_id = -1
			stick = Vector2.ZERO
		return
	if panel == 7:
		posada_input(point)
		return
	if panel == 6:
		tienda_input(point)
		return
	if panel == 4:
		if CHARACTER_CLOSE.has_point(point):
			panel = -1
			return
		var count := PROGRESO.TALENTOS.size()
		for entry_id in count:
			if character_option(entry_id).has_point(point):
				change_character(entry_id)
				return
		return
	if panel >= 0:
		if Rect2(750, 226, 52, 46).has_point(point):
			panel = -1
			return
		for index in (4 if panel == 0 else (1 if panel == 3 else (2 if panel == 2 and progreso.tramo > 1 else 1))):
			if option(index).has_point(point):
				choose(index)
				return
		return
	if TALENT_BUTTON.has_point(point):
		open_location(4)
		return
	if EQUIP_BUTTON.has_point(point):
		open_location(5)
		return
	if point.distance_to(JOYSTICK) < 75 and stick_id == -1:
		stick_id = id
		stick = ((point - JOYSTICK) / 47.0).limit_length()
		return
	if point.distance_to(INTERACT) < 58:
		if nearest() >= 0:
			open_location(nearest())
		return
	for index in LOCATIONS.size():
		if point.distance_to(LOCATIONS[index] - Vector2(0, 17)) < 70:
			if at.distance_to(LOCATIONS[index]) < 75:
				open_location(index)
			else:
				travel_to = index
				dest = LOCATIONS[index]
			return
	dest = constrain(point)
	travel_to = -1

func option(index: int) -> Rect2:
	if panel == 0:
		return Rect2(370, 332 + index * 43, 410, 38)
	if panel == 3:
		return Rect2(370, 447, 410, 43)
	return Rect2(370, 349 + index * 51, 410, 43)

func choose(index: int) -> void:
	match panel:
		0:
			if index == 3:
				abrir_tienda()
				return
			if index == 1 and not progreso.hallazgo:
				return
			formation = index
			panel = -1
			message = FORMATIONS[formation] + " seleccionada."
		1:
			if index == 0 and progreso.victorias > 0:
				blessing = not blessing
				panel = -1
				message = "Bendición de Elías preparada." if blessing else "Bendición retirada."
		3:
			if index == 0:
				open_location(7)
		2:
			if index == 0:
				descend(destino_mina)
			elif index == 1 and progreso.tramo > 1:
				destino_mina = posmod(destino_mina - 2, progreso.tramo) + 1

func descend(destino := 0) -> void:
	if is_instance_valid(battle):
		return
	panel = -1
	plaza.render_target_update_mode = SubViewport.UPDATE_DISABLED
	battle = MINA.instantiate()
	battle.progreso.ruta_guardado = progreso.ruta_guardado
	battle.return_to_town.connect(return_from_mine)
	add_child(battle)
	battle.start(formation == 2, formation == 1, progreso.tramo if destino == 0 else destino)
	battle.use_town_blessing(blessing)
	ambiente.cambiar_zona(true)
	queue_redraw()

func return_from_mine(won: bool) -> void:
	battle.hide()
	battle.set_process_input(false)
	battle.queue_free()
	battle = null
	ambiente.cambiar_zona(false)
	plaza.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	progreso.cargar()
	at = CENTER
	dest = CENTER
	message = "Progreso guardado · Acceso a " + PLANTAS.nombre(progreso.tramo) if won else "Has vuelto a Valdebronce."

func text(point: Vector2, value: String, size: int = 16, color: Color = GOLD) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if is_instance_valid(battle):
		return
	draw_texture_rect(FONDO_PLAZA, Rect2(0, 0, 1152, 648), false)
	draw_texture(plaza.get_texture(), Vector2.ZERO)
	draw_rect(Rect2(0, 0, 1152, 100), Color("#121017d8"))
	text(Vector2(34, 39), "VALDEBRONCE", 30)
	text(Vector2(34, 68), message if not message.is_empty() else "El pueblo de las diez campanadas", 16)
	var level := progreso.nivel()
	var base := progreso.umbral(level)
	var goal := progreso.umbral(level + 1) - base
	text(Vector2(855, 32), "Nivel %d  ·  %d/%d XP" % [level, progreso.xp - base, goal], 17)
	draw_rect(Rect2(855, 41, 216, 5), Color("#48342c"))
	draw_rect(Rect2(855, 41, 216.0 * (progreso.xp - base) / goal, 5), GOLD)
	text(Vector2(855, 72), FORMATIONS[formation], 14)
	draw_rect(BOTON_AYUDA, Color("#32242a"))
	text(BOTON_AYUDA.position + Vector2(12, 26), "Ayuda [H]", 17)
	draw_rect(BOTON_AUDIO, Color("#32242a"))
	text(BOTON_AUDIO.position + Vector2(9, 22), "Silencio [M]" if ambiente.silenciado else "Música [M]", 14)
	for index in LOCATIONS.size():
		var spot: Vector2 = LOCATIONS[index]
		draw_circle(spot, 7, COLORS[index])
		draw_arc(spot, 12, 0, TAU, 28, COLORS[index], 1.5, true)
		var width := ThemeDB.fallback_font.get_string_size(NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var title_rect := Rect2(spot - Vector2(width * 0.5 + 10, 49), Vector2(width + 20, 29))
		draw_rect(title_rect, Color("#1c1519ee"))
		draw_rect(title_rect, COLORS[index].darkened(0.35), false, 1.2)
		text(title_rect.position + Vector2(10, 20), NAMES[index], 16)
	draw_set_transform(at, 0, Vector2(1, 0.46))
	draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color("#9ed1ce"), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	draw_circle(JOYSTICK, 54, Color("#1a151cbb"))
	draw_arc(JOYSTICK, 54, 0, TAU, 36, Color("#9b7e60"), 2, true)
	draw_circle(JOYSTICK + stick * 35, 21, Color("#765e4a"))
	if nearest() >= 0:
		draw_circle(INTERACT, 44, Color("#211921ee"))
		draw_arc(INTERACT, 44, 0, TAU, 36, GOLD, 1.5, true)
		text(INTERACT + Vector2(-27, 4), "Entrar", 17)
		text(INTERACT + Vector2(-4, 23), "E", 12)
	draw_rect(TALENT_BUTTON, Color("#261b1fec"))
	draw_rect(EQUIP_BUTTON, Color("#261b1fec"))
	text(TALENT_BUTTON.position + Vector2(10, 28), "Talentos [T]")
	text(EQUIP_BUTTON.position + Vector2(10, 28), "Mochila [I]")
	if panel == 7:
		draw_posada()
		return
	if panel == 6:
		draw_tienda()
		return
	if panel in [4, 5]:
		draw_character()
		return
	if panel >= 0:
		draw_rect(Rect2(0, 0, 1152, 648), Color("#100e14a8"))
		draw_rect(PANEL, Color("#21191f"))
		draw_rect(PANEL, Color("#9e7952"), false, 2)
		text(Vector2(370, 266), NAMES[panel], 28)
		text(Vector2(768, 254), "×", 25)
		match panel:
			0:
				text(Vector2(370, 312), "Mara · Elige una sugerencia de formación.")
				for index in 3:
					var caption: String = FORMATIONS[index]
					if index == 1 and not progreso.hallazgo:
						caption += " · requiere el plano"
					draw_option(index, caption)
				draw_option(3, "Comprar y vender")
			1:
				var unlocked := progreso.victorias > 0
				text(Vector2(370, 312), "Elías · Vence al capataz para desbloquear su bendición." if not unlocked else "Elías · Empieza con una protección de un solo uso.", 15)
				draw_option(0, "Retirar bendición" if blessing else ("Equipar bendición" if unlocked else "Bendición bloqueada"))
			2:
				text(Vector2(370, 305), "Cada intento empieza sin esbirros ni reliquias.", 14)
				text(Vector2(370, 329), "Conservas XP, equipo, talentos y accesos.", 14)
				draw_option(0, "Descender a " + PLANTAS.nombre(destino_mina))
				if progreso.tramo > 1:
					draw_option(1, "Cambiar planta de entrada")
			3:
				text(Vector2(370, 312), "Inés · Anoto quién vuelve de la mina.")
				text(Vector2(370, 361), "Capataz derrotado: %d" % progreso.victorias)
				text(Vector2(370, 392), "Plano de Mara recuperado" if progreso.hallazgo else "El plano de Mara sigue en la sala de bombas.")
				draw_option(0, "Contratos y cuaderno de Inés")

func draw_option(index: int, caption: String) -> void:
	var rect := option(index)
	draw_rect(rect, Color("#493531"))
	text(rect.position + Vector2(12, 28), "%d   %s" % [index + 1, caption], 17)

func abrir_tienda() -> void:
	open_location(6)
	vendiendo = false
	pagina_tienda = 0
	oferta = -1
	aviso_tienda = ""

func existencias_tienda() -> Array[int]:
	if vendiendo:
		return progreso.inventario.duplicate()
	var disponibles: Array[int] = []
	for id in PROGRESO.OBJETOS.size():
		if progreso.precio_compra(id) >= 0:
			disponibles.append(id)
	return disponibles

func puesto_tienda(indice: int) -> Rect2:
	return Rect2(134 + (indice % 2) * 447, 236 + floori(indice / 2.0) * 43, 433, 38)

func tienda_input(punto: Vector2) -> void:
	if CHARACTER_CLOSE.has_point(punto):
		panel = 0
		return
	if COMPRAR.has_point(punto) or VENDER.has_point(punto):
		vendiendo = VENDER.has_point(punto)
		pagina_tienda = 0
		oferta = -1
		aviso_tienda = ""
		return
	if oferta >= 0 and TRATO.has_point(punto):
		confirmar_trato()
		return
	var disponibles := existencias_tienda()
	if PAGINA_ANT.has_point(punto) or PAGINA_SIG.has_point(punto):
		pagina_tienda = cambiar_pagina(pagina_tienda, disponibles.size(), PAGINA_SIG.has_point(punto))
		oferta = -1
		return
	var inicio := pagina_tienda * 10
	for i in mini(10, disponibles.size() - inicio):
		if puesto_tienda(i).has_point(punto):
			oferta = disponibles[inicio + i]
			aviso_tienda = ""
			return

func confirmar_trato() -> void:
	var nombre: String = PROGRESO.OBJETOS[oferta][0]
	var resultado := progreso.vender(oferta) if vendiendo else progreso.comprar(oferta)
	if resultado == OK:
		aviso_tienda = "Vendiste %s." % nombre if vendiendo else "Compraste %s. Equípalo en la mochila." % nombre
		pagina_tienda = mini(pagina_tienda, paginas(existencias_tienda().size()) - 1)
		oferta = -1
	elif resultado == ERR_UNAVAILABLE:
		aviso_tienda = "Quita primero la pieza en la mochila." if vendiendo else "No tienes cobre suficiente."
	else:
		aviso_tienda = "No se pudo guardar el trato."

func draw_tienda() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("#100c12d0"))
	draw_rect(CHARACTER_PANEL, Color("#21181a"))
	draw_rect(CHARACTER_PANEL, Color("#a47a4c"), false, 2)
	text(Vector2(132, 164), "Forja de Mara", 28)
	text(Vector2(832, 162), "%d cobre" % progreso.cobre, 18)
	text(Vector2(997, 166), "×", 26)
	for pestaña in [COMPRAR, VENDER]:
		var es_venta: bool = pestaña == VENDER
		draw_rect(pestaña, Color("#694a35") if vendiendo == es_venta else Color("#3a2a28"))
		text(pestaña.position + Vector2(22, 24), "Vender" if es_venta else "Comprar", 16)
	var disponibles := existencias_tienda()
	if disponibles.is_empty():
		text(Vector2(140, 277), "No hay piezas para vender." if vendiendo else "Has comprado todas las piezas disponibles.", 17)
	draw_paginacion(pagina_tienda, disponibles.size())
	var inicio := pagina_tienda * 10
	for i in mini(10, disponibles.size() - inicio):
		var id := disponibles[inicio + i]
		var rect := puesto_tienda(i)
		var precio: int = PROGRESO.PRECIO_VENTA[id] if vendiendo else progreso.precio_compra(id)
		draw_rect(rect, Color("#574034") if oferta == id else Color("#342825"))
		draw_item(id, rect.position + Vector2(21, 19))
		text(rect.position + Vector2(44, 25), PROGRESO.OBJETOS[id][0], 16)
		var derecha := "Equipado" if vendiendo and id in progreso.equipo else "%d cobre" % precio
		text(rect.position + Vector2(307, 25), derecha, 14)
	if oferta >= 0:
		var texto: String = PROGRESO.OBJETOS[oferta][2]
		text(Vector2(140, 487), texto, 16)
		draw_rect(TRATO, Color("#694a35"))
		text(TRATO.position + Vector2(16, 29), "Vender por %d" % PROGRESO.PRECIO_VENTA[oferta] if vendiendo else "Comprar por %d" % progreso.precio_compra(oferta), 17)
	text(Vector2(140, 520), aviso_tienda, 15)

func paginas(cantidad: int) -> int:
	return maxi(1, ceili(cantidad / 10.0))

func cambiar_pagina(pagina: int, cantidad: int, siguiente: bool) -> int:
	return clampi(pagina + (1 if siguiente else -1), 0, paginas(cantidad) - 1)

func draw_paginacion(pagina: int, cantidad: int) -> void:
	if paginas(cantidad) <= 1:
		return
	for rect in [PAGINA_ANT, PAGINA_SIG]:
		draw_rect(rect, Color("#4d3832"))
		text(rect.position + Vector2(9, 22), "‹" if rect == PAGINA_ANT else "›", 23)
	text(Vector2(699, 203), "%d / %d" % [pagina + 1, paginas(cantidad)], 15)

func contrato_rect(id: int) -> Rect2:
	return Rect2(835, 249 + id * 83, 180, 44)

func posada_input(punto: Vector2) -> void:
	if CHARACTER_CLOSE.has_point(punto):
		panel = 3
	elif CONTRATO_TAB.has_point(punto) or DIARIO_TAB.has_point(punto):
		ver_diario = DIARIO_TAB.has_point(punto)
		aviso_contrato = ""
	elif not ver_diario:
		for id in PROGRESO.CONTRATOS.size():
			if contrato_rect(id).has_point(punto):
				var estado := progreso.cobrar_contrato(id)
				aviso_contrato = "Inés te entrega %d de cobre." % PROGRESO.CONTRATOS[id][3] if estado == OK else ("La recompensa aún no está disponible." if estado == ERR_UNAVAILABLE else "No se pudo guardar el encargo.")
				return

func draw_posada() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("#100c12d0"))
	draw_rect(CHARACTER_PANEL, Color("#21181a"))
	draw_rect(CHARACTER_PANEL, Color("#a47a4c"), false, 2)
	text(Vector2(132, 164), "Hospedería de Inés", 28)
	text(Vector2(832, 162), "%d cobre" % progreso.cobre, 18)
	text(Vector2(997, 166), "×", 26)
	for rect in [CONTRATO_TAB, DIARIO_TAB]:
		draw_rect(rect, Color("#684835") if (rect == DIARIO_TAB) == ver_diario else Color("#3b2a28"))
		text(rect.position + Vector2(17, 26), "Cuaderno" if rect == DIARIO_TAB else "Contratos", 17)
	if ver_diario:
		var notas := [
			["Corista de sal", "Cura a su escolta cercana. Marca al corista cuando empiece el cántico."],
			["Verdugo de la fundición", "Anuncia su carga con un trazo. Usa el pilar y sal de las franjas de brasas."],
			["Campanero hundido", "Su onda solo alcanza a quien está cerca y a la vista. Invoca dos ecos al quedar herido."],
		]
		for i in notas.size():
			text(Vector2(140, 266 + i * 80), notas[i][0] if progreso.tramo >= i + 6 else "Página sin registrar", 19)
			text(Vector2(140, 297 + i * 80), notas[i][1] if progreso.tramo >= i + 6 else "Desbloquea la planta −%d." % (i + 6), 15)
		return
	for i in PROGRESO.CONTRATOS.size():
		var dato: Array = PROGRESO.CONTRATOS[i]
		var rect := contrato_rect(i)
		var cobrado := i in progreso.contratos
		var completo: bool = dato[2] in progreso.recompensas
		draw_rect(rect, Color("#5c4632") if completo and not cobrado else Color("#33272c"))
		text(Vector2(140, rect.position.y + 17), dato[0], 19)
		text(Vector2(140, rect.position.y + 40), dato[1], 14)
		text(rect.position + Vector2(12, 28), "Cobrado" if cobrado else ("Cobrar %d cobre" % dato[3] if completo else "%d cobre · Pendiente" % dato[3]), 14)
	text(Vector2(140, 514), aviso_contrato, 15)

func character_option(id: int) -> Rect2:
	var column := floori(id / 3.0)
	var row := id % 3
	return Rect2(132 + column * 300, 253 + row * 81, 282, 66)

func change_character(id: int) -> void:
	var result := progreso.aprender(id) if panel == 4 else progreso.equipar(id)
	match result:
		OK:
			message = "Talento aprendido." if panel == 4 else "Equipo actualizado."
		ERR_UNAVAILABLE:
			message = "Necesitas el talento anterior y un punto libre." if panel == 4 else "Consigue esta pieza en la mina."
		_:
			message = "No se pudo guardar el cambio."

func mochila_celda(index: int) -> Rect2:
	return Rect2(489 + (index % 5) * 101, 236 + floori(index / 5.0) * 85, 89, 74)

func ranura_celda(slot: int) -> Rect2:
	return Rect2(305, 224 + slot * 64, 126, 55)

func tinte_celda(index: int) -> Rect2:
	return Rect2(134 + index * 52, 482, 41, 31)

func mochila_input(point: Vector2, id: int, pressed: bool) -> void:
	if not pressed:
		if id != arrastre_id:
			return
		var item := arrastre_pieza
		arrastre_id = -1
		arrastre_pieza = -1
		if point.distance_to(arrastre_inicio) < 14.0:
			return
		var slot: int = PROGRESO.OBJETOS[item][1]
		if ranura_celda(slot).has_point(point) and item not in progreso.equipo:
			change_character(item)
		elif MOCHILA.has_point(point) and item in progreso.equipo:
			change_character(item)
		return
	if arrastre_id >= 0:
		return
	if CHARACTER_CLOSE.has_point(point):
		panel = -1
		return
	if PAGINA_ANT.has_point(point) or PAGINA_SIG.has_point(point):
		pagina_mochila = cambiar_pagina(pagina_mochila, piezas_en_mochila().size(), PAGINA_SIG.has_point(point))
		return
	if ASPECTO_BOTON.has_point(point):
		message = "Aspecto guardado." if progreso.cambiar_aspecto() == OK else "No se pudo guardar el aspecto."
		return
	if BOTON_PIEZA.has_point(point) and seleccion in progreso.inventario:
		change_character(seleccion)
		return
	for index in PROGRESO.COLORES_VINCULADOR.size():
		if tinte_celda(index).has_point(point):
			message = "Aspecto guardado." if progreso.personalizar(index) == OK else "No se pudo guardar el aspecto."
			return
	for slot in 3:
		if ranura_celda(slot).has_point(point) and progreso.equipo[slot] >= 0:
			seleccionar_pieza(progreso.equipo[slot], point, id)
			return
	var sueltas := piezas_en_mochila()
	var inicio := pagina_mochila * 10
	for index in mini(10, sueltas.size() - inicio):
		if mochila_celda(index).has_point(point):
			seleccionar_pieza(sueltas[inicio + index], point, id)
			return

func piezas_en_mochila() -> Array[int]:
	return progreso.inventario.filter(func(item: int) -> bool: return item not in progreso.equipo)

func seleccionar_pieza(item: int, point: Vector2, id: int) -> void:
	seleccion = item
	arrastre_pieza = item
	arrastre_id = id
	arrastre_inicio = point
	arrastre_pos = point

func draw_item(item: int, at_icon: Vector2) -> void:
	var metal := Color("#dfb579") if item < 3 else Color("#a9ccd0")
	match int(PROGRESO.OBJETOS[item][1]):
		0:
			draw_line(at_icon + Vector2(-13, 15), at_icon + Vector2(12, -13), Color("#75523a"), 7, true)
			draw_arc(at_icon + Vector2(9, -10), 8, 0, TAU, 20, metal, 3, true)
			draw_circle(at_icon + Vector2(9, -10), 3, metal)
		1:
			var silhouette := PackedVector2Array([Vector2(-17, -10), Vector2(-8, -16), Vector2(8, -16), Vector2(17, -10), Vector2(11, 13), Vector2(0, 17), Vector2(-11, 13)])
			for i in silhouette.size():
				silhouette[i] += at_icon
			draw_colored_polygon(silhouette, metal.darkened(0.4))
			draw_polyline(PackedVector2Array([at_icon + Vector2(-12, -8), at_icon, at_icon + Vector2(12, -8)]), metal, 2, true)
		2:
			draw_arc(at_icon + Vector2(0, -6), 11, 0, TAU, 20, metal, 2, true)
			draw_colored_polygon(PackedVector2Array([at_icon + Vector2(0, 1), at_icon + Vector2(8, 9), at_icon + Vector2(0, 17), at_icon + Vector2(-8, 9)]), metal)

func draw_mochila() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("#100c12d0"))
	draw_rect(CHARACTER_PANEL, Color("#21181a"))
	draw_rect(CHARACTER_PANEL, Color("#a47a4c"), false, 2)
	text(Vector2(132, 166), "El Vinculador", 28)
	text(Vector2(488, 166), "Mochila", 28)
	text(Vector2(997, 166), "×", 26)
	text(Vector2(488, 196), "Arrastra a la ranura", 15)
	draw_rect(Rect2(128, 215, 157, 200), Color("#120e15"))
	draw_rect(ASPECTO_BOTON, Color("#4b3835"))
	draw_rect(ASPECTO_BOTON, GOLD.darkened(0.48), false, 1)
	text(ASPECTO_BOTON.position + Vector2(12, 22), PROGRESO.NOMBRES_ASPECTOS[progreso.aspecto] + "  ↻", 14)
	var sprite := progreso.sprite_vinculador()
	var retrato := sprite.get_size()
	retrato *= minf(139.0 / retrato.x, 181.0 / retrato.y)
	draw_texture_rect(sprite, Rect2(Vector2(206.5, 316.5) - retrato * 0.5, retrato), false, Color.WHITE.lerp(progreso.color_vinculador(), 0.74))
	for slot in 3:
		var rect := ranura_celda(slot)
		var item := progreso.equipo[slot]
		draw_rect(rect, Color("#35282a"))
		draw_rect(rect, GOLD.darkened(0.45), false, 1)
		if item >= 0:
			draw_item(item, rect.position + Vector2(26, 26))
		text(rect.position + Vector2(48, 31), PROGRESO.RANURAS[slot], 13)
	text(Vector2(132, 442), "Nivel %d · Vida %d · Ataque %d" % [progreso.nivel(), 100 + (progreso.nivel() - 1) * 5 + progreso.bonus("vida"), 14 + progreso.nivel() - 1 + progreso.bonus("ataque")], 15)
	text(Vector2(132, 471), "Tinte del personaje", 14)
	for index in PROGRESO.COLORES_VINCULADOR.size():
		var rect := tinte_celda(index)
		draw_rect(rect, PROGRESO.COLORES_VINCULADOR[index].darkened(0.2))
		draw_rect(rect.grow(2), GOLD if index == progreso.tinte else Color("#54434c"), false, 2)
	draw_rect(MOCHILA, Color("#382923"))
	draw_rect(MOCHILA.grow(-7), Color("#755138"), false, 1)
	var sueltas := piezas_en_mochila()
	pagina_mochila = mini(pagina_mochila, paginas(sueltas.size()) - 1)
	draw_paginacion(pagina_mochila, sueltas.size())
	var inicio := pagina_mochila * 10
	for index in 10:
		var rect := mochila_celda(index)
		draw_rect(rect, Color("#291d1b"))
		draw_rect(rect, Color("#6e4d34"), false, 1)
		if inicio + index < sueltas.size():
			var item := sueltas[inicio + index]
			draw_item(item, rect.get_center())
			if item == seleccion:
				draw_rect(rect, GOLD, false, 2)
	if progreso.inventario.is_empty():
		var empty := Rect2(520, 292, 376, 47)
		draw_rect(empty, Color("#271d1a"))
		text(empty.position + Vector2(18, 30), "Tu primer bastón te espera en Bocamina.", 16)
	if seleccion in progreso.inventario:
		var data: Array = PROGRESO.OBJETOS[seleccion]
		text(Vector2(482, 468), data[0], 19)
		text(Vector2(482, 500), data[2], 14)
		draw_rect(BOTON_PIEZA, Color("#574232"))
		text(BOTON_PIEZA.position + Vector2(18, 30), "Quitar" if seleccion in progreso.equipo else "Equipar", 16)
	if arrastre_pieza >= 0 and arrastre_pos.distance_to(arrastre_inicio) >= 14.0:
		draw_item(arrastre_pieza, arrastre_pos)

func draw_character() -> void:
	if panel == 5:
		draw_mochila()
		return
	draw_rect(Rect2(0, 0, 1152, 648), Color("#100e14c2"))
	draw_rect(CHARACTER_PANEL, Color("#21191f"))
	draw_rect(CHARACTER_PANEL, Color("#9e7952"), false, 2)
	text(Vector2(132, 166), "Árbol de talentos", 28)
	text(Vector2(997, 166), "×", 26)
	text(Vector2(132, 196), "%d puntos disponibles · Desbloquea cada rama desde arriba" % progreso.puntos(), 15)
	var headings := ["Campana y virotes", "Baluarte", "Enjambre"]
	for column in 3:
		text(Vector2(135 + column * 300, 238), headings[column], 20)
	for id in PROGRESO.TALENTOS.size():
		var entry: Array = PROGRESO.TALENTOS[id]
		var rect := character_option(id)
		var owned := id in progreso.talentos
		var available := progreso.puede_aprender(id)
		var fill := Color("#394539") if owned else (Color("#543f35") if available else Color("#322730"))
		draw_rect(rect, fill)
		draw_rect(rect, GOLD.darkened(0.28 if owned or available else 0.61), false, 1)
		text(rect.position + Vector2(10, 21), entry[0], 16)
		text(rect.position + Vector2(10, 42), entry[1], 13)
		text(rect.position + Vector2(10, 58), "Aprendido" if owned else ("Aprender" if available else "Bloqueado"), 11)
		if id % 3 != 2:
			var bottom := Vector2(rect.get_center().x, rect.end.y)
			draw_line(bottom, bottom + Vector2(0, 15), GOLD.darkened(0.35 if owned else 0.67), 2)
