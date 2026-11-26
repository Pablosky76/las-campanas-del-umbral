extends SubViewport

const RESOLUCION := Vector2i(1152, 648)
const CENTRO_CAMARA := Vector3(5.539744, 0, 4.360256)
const ESCALA := 55.15433
const PASARELA := Rect2(5.35, 1.10, 6.65, 0.85)
const CANALES := [Rect2(6, 0, 6, 1.10), Rect2(6, 1.95, 6, 1.05)]
const ALTURA_PASARELA := 0.21
const VIROTE_VISUAL = preload("res://virote_visual.gd")
const FIGURA = preload("res://figura_3d.gd")
const PIZARRA = preload("res://arte/pizarra.png")

const ATLAS = preload("res://arte/suelos-mina.png")
const TONOS := ["#b9a28c", "#8198af", "#939084", "#a17f86", "#c4bea1", "#9baa9e", "#ab795d", "#9c9ebd"]
var planta := 3
var obstaculo := Rect2(5.4, 3.6, 1.15, 1.2)
var chispas: Array[MeshInstance3D] = []
var camara: Camera3D
var rejilla: GridMap
var compuerta: Node3D
var volante: Node3D
var luces: Array[OmniLight3D] = []
var piedra: StandardMaterial3D
var metal: StandardMaterial3D
var bronce: StandardMaterial3D
var madera: StandardMaterial3D
var luz: StandardMaterial3D
var malla_sombra: PlaneMesh
var farol_vinculador: OmniLight3D
var pilar_alto: Node3D
var altura_pilar := 1.04
var caja_pilar: AABB
var material_crecida: StandardMaterial3D
var superficies_crecida: Array[MeshInstance3D] = []
var ondas_crecida: Array[MeshInstance3D] = []

func _ready() -> void:
	size = RESOLUCION
	own_world_3d = true
	transparent_bg = planta == 0
	render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	gui_disable_input = true
	msaa_3d = Viewport.MSAA_2X
	piedra = material(Color("#9b9690"), 0.9, 0.0, PIZARRA)
	metal = material(Color("#454c50"), 0.57, 0.45)
	bronce = material(Color("#a57247"), 0.52, 0.48)
	madera = material(Color("#674c3b"), 0.92, 0.0, PIZARRA)
	luz = material(Color("#ffe2a3"), 0.7)
	luz.emission_enabled = true
	luz.emission = Color("#ffbc66")
	configurar_camara()
	construir_sombra()
	if planta == 0:
		construir_detalles_plaza()
	else:
		construir_suelo()
		if planta == 3:
			construir_muros()
			construir_maquinaria()
			construir_pasarela()
			construir_crecida()
		else:
			construir_galeria()

static func altura(posicion: Vector2) -> float:
	if not PASARELA.has_point(posicion):
		return 0.0
	return ALTURA_PASARELA * clampf((posicion.x - PASARELA.position.x) / 0.55, 0.0, 1.0)

static func inundable(posicion: Vector2) -> bool:
	return CANALES[0].has_point(posicion) or CANALES[1].has_point(posicion)

func crear_virote(con_cal: bool, con_grillete: bool) -> VIROTE_VISUAL:
	var virote := VIROTE_VISUAL.new()
	add_child(virote)
	var color := Color("#c7e6a6") if con_cal else (Color("#c4a6fc") if con_grillete else Color("#cfe2e3"))
	virote.montar(madera, color)
	return virote

func crear_figura() -> FIGURA:
	var figura := FIGURA.new()
	figura.proyectar_sombra = planta > 0
	add_child(figura)
	return figura

func mover_farol_vinculador(pies: Vector3, derecha: bool, fase: float, pulso := 0.0, origen := Vector3.INF) -> void:
	if farol_vinculador == null:
		farol_vinculador = OmniLight3D.new()
		farol_vinculador.light_color = Color("#bbf3b7")
		farol_vinculador.omni_range = 3.2
		farol_vinculador.omni_attenuation = 1.65
		add_child(farol_vinculador)
	var lado := 1.0 if derecha else -1.0
	farol_vinculador.position = origen if origen.is_finite() else pies + Vector3(0, 1.03, 0) + camara.basis.x * 0.43 * lado
	farol_vinculador.light_energy = 0.95 + 0.09 * sin(fase * 5.0) + pulso * 1.2

func construir_sombra() -> void:
	var degradado := Gradient.new()
	degradado.colors = PackedColorArray([Color("#130d17bd"), Color("#130d1773"), Color("#130d1700")])
	degradado.offsets = PackedFloat32Array([0.0, 0.56, 1.0])
	var halo := GradientTexture2D.new()
	halo.width = 64
	halo.height = 64
	halo.gradient = degradado
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(1, 0.5)
	var acabado := material(Color.WHITE, 1.0, 0.0, halo)
	acabado.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	acabado.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	malla_sombra = PlaneMesh.new()
	malla_sombra.size = Vector2.ONE
	malla_sombra.material = acabado

func construir_pilar(alto: float) -> void:
	altura_pilar = alto
	var centro := obstaculo.get_center()
	var base := 0.15
	caja(self, Vector3(centro.x, base * 0.5, centro.y), Vector3(obstaculo.size.x, base, obstaculo.size.y), piedra)
	pilar_alto = Node3D.new()
	pilar_alto.position = Vector3(centro.x, base, centro.y)
	add_child(pilar_alto)
	var fuste := alto - base - 0.16
	caja(pilar_alto, Vector3(0, fuste * 0.5, 0), Vector3(obstaculo.size.x * 0.92, fuste, obstaculo.size.y * 0.91), piedra)
	caja(pilar_alto, Vector3(0, fuste + 0.08, 0), Vector3(obstaculo.size.x, 0.16, obstaculo.size.y), piedra)
	caja_pilar = AABB(Vector3(obstaculo.position.x, base, obstaculo.position.y), Vector3(obstaculo.size.x, alto - base, obstaculo.size.y))

func actualizar_ocultacion(pies: Vector3, delta: float) -> void:
	if pilar_alto == null:
		return
	var hacia_camara := camara.basis.z
	var bloquea := false
	for y in [0.35, 0.66]:
		if caja_pilar.intersects_ray(pies + Vector3(0, y, 0), hacia_camara) != null:
			bloquea = true
			break
	var objetivo := 0.19 if bloquea else 1.0
	pilar_alto.scale.y = lerpf(pilar_alto.scale.y, objetivo, 1.0 - exp(-delta * 13.0))

func configurar_camara() -> void:
	var fondo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_CLEAR_COLOR if planta == 0 else Environment.BG_COLOR
	entorno.background_color = Color("#141114")
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color("#a8b8cf")
	entorno.ambient_light_energy = 0.65
	fondo.environment = entorno
	add_child(fondo)
	var principal := DirectionalLight3D.new()
	principal.rotation_degrees = Vector3(-49, -35, 0)
	principal.light_color = Color("#c3d3db")
	principal.light_energy = 0.9
	principal.shadow_enabled = planta > 0
	principal.directional_shadow_max_distance = 44
	add_child(principal)
	if planta > 0:
		var contraluz := DirectionalLight3D.new()
		contraluz.rotation_degrees = Vector3(-31, 134, 0)
		contraluz.light_color = Color("#8ba9e2")
		contraluz.light_energy = 0.42
		add_child(contraluz)
	camara = Camera3D.new()
	camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara.size = RESOLUCION.y / ESCALA
	camara.far = 60
	add_child(camara)
	camara.position = CENTRO_CAMARA + Vector3(1, 0.8447, 1).normalized() * 22
	camara.look_at(CENTRO_CAMARA)
	camara.current = true

func construir_suelo() -> void:
	rejilla = GridMap.new()
	rejilla.name = "Galerias"
	rejilla.cell_size = Vector3.ONE
	rejilla.cell_center_y = false
	var biblioteca := MeshLibrary.new()
	for i in 4:
		var losa := BoxMesh.new()
		losa.size = Vector3(0.99, 0.24, 0.99)
		var tonalidad := Color(TONOS[planta - 1]).lightened(0.21).darkened(float(i) * 0.065)
		var acabado := material(tonalidad, 0.92, 0.0, PIZARRA if planta == 3 or planta > 5 else ATLAS)
		if planta != 3 and planta <= 5:
			acabado.uv1_scale = Vector3(0.49, 0.325, 1.0)
			acabado.uv1_offset = Vector3((planta - 1) % 2 * 0.5 + 0.004, floorf((planta - 1) / 2.0) / 3.0 + 0.004, 0)
		losa.material = acabado
		biblioteca.create_item(i)
		biblioteca.set_item_name(i, ["Pizarra", "Pizarra oscura", "Pizarra húmeda", "Canal"][i])
		biblioteca.set_item_mesh(i, losa)
		biblioteca.set_item_mesh_transform(i, Transform3D(Basis.IDENTITY, Vector3(0, -0.12, 0)))
	rejilla.mesh_library = biblioteca
	add_child(rejilla)
	for x in 12:
		for z in 10:
			var id := 3 if planta == 3 and x >= 6 and z < 3 else (x * 7 + z * 13 + x * z) % 3
			rejilla.set_cell_item(Vector3i(x, 0, z), id)

func construir_galeria() -> void:
	piedra.albedo_color = Color(TONOS[planta - 1])
	for x in 12:
		var alto := 1.30 + (x * 7 % 4) * 0.10
		caja(self, Vector3(x + 0.5, alto * 0.5, -0.22), Vector3(0.996, alto, 0.44), piedra)
		caja(self, Vector3(x + 0.5, alto + 0.02, -0.22), Vector3(0.98, 0.09, 0.48), piedra)
	for z in [1.4, 4.1, 7.5, 9.25]:
		caja(self, Vector3(-0.22, 0.60, z), Vector3(0.44, 1.20, 1.19), piedra)
	construir_pilar(1.08)
	match planta:
		1:
			for x in [1.4, 4.8, 8.0, 10.9]:
				caja(self, Vector3(x, 1.04, -0.09), Vector3(0.23, 2.1, 0.34), madera)
				var viga := caja(self, Vector3(x + 0.22, 1.44, -0.11), Vector3(0.18, 0.7, 0.20), madera)
				viga.rotation.z = -0.65
			for x in [0.55, 1.25, 1.95]:
				caja(self, Vector3(x, 0.12, 0.16), Vector3(0.48, 0.30, 0.41), madera)
				caja(self, Vector3(x, 0.29, 0.16), Vector3(0.51, 0.08, 0.44), bronce)
		2:
			for tramo in [Vector2(0, 3.75), Vector2(6.3, 10.0)]:
				var largo: float = tramo.y - tramo.x
				for x in [8.14, 8.72]:
					caja(self, Vector3(x, 0.028, tramo.x + largo / 2), Vector3(0.075, 0.056, largo), metal)
				for i in floori(largo / 0.39):
					caja(self, Vector3(8.43, 0.02, tramo.x + 0.19 + i * 0.39), Vector3(0.91, 0.05, 0.16), madera)
			var rail := caja(self, Vector3(8.32, 0.045, 4.66), Vector3(0.08, 0.09, 1.50), metal)
			rail.rotation.y = 0.34
		4:
			for x in [1.6, 4.0, 7.9, 10.5]:
				caja(self, Vector3(x, 0.61, 0.034), Vector3(0.73, 1.22, 0.15), madera)
				caja(self, Vector3(x, 0.34, 0.117), Vector3(0.76, 0.09, 0.04), metal)
				caja(self, Vector3(x, 1.23, 0.07), Vector3(0.92, 0.18, 0.34), piedra)
				caja(self, Vector3(x + 0.20, 0.56, 0.13), Vector3(0.075, 0.08, 0.085), bronce)
		5:
			for x in [1.4, 3.7, 6.1, 9.5, 11.3]:
				caja(self, Vector3(x, 0.14, 0.13), Vector3(0.77, 0.30, 0.40), piedra)
				caja(self, Vector3(x, 0.31, 0.13), Vector3(0.84, 0.09, 0.44), piedra)
				for d in [-0.21, 0.21]:
					cilindro(self, Vector3(x + d, 0.39, 0.17), 0.032, 0.12, luz)
		6:
			for x in [1.5, 4.35, 8.2, 10.45]:
				caja(self, Vector3(x, 0.61, -0.08), Vector3(0.78, 1.19, 0.34), metal)
				caja(self, Vector3(x, 0.38, 0.12), Vector3(0.52, 0.32, 0.09), bronce)
				cilindro(self, Vector3(x, 0.69, 0.13), 0.11, 0.20, luz)
		7:
			for z in [4.8, 6.8, 8.8]:
				for x in [4.5, 11.0]:
					caja(self, Vector3(x, 0.014, z), Vector3(0.67, 0.026, 0.71), metal)
					for i in 5:
						caja(self, Vector3(x - 0.26 + i * 0.13, 0.031, z), Vector3(0.055, 0.025, 0.66), piedra)
			for x in [3.8, 7.5, 10.65]:
				cilindro(self, Vector3(x, 0.57, 0.13), 0.33, 1.14, metal)
				cilindro(self, Vector3(x, 0.55, 0.42), 0.11, 0.13, luz).rotation.x = PI * 0.5
		8:
			caja(self, Vector3(8.1, 1.84, -0.17), Vector3(5.2, 0.28, 0.44), madera)
			for x in [6.1, 8.1, 10.1]:
				cilindro(self, Vector3(x, 1.02, 0.05), 0.38, 0.73, bronce)
				cilindro(self, Vector3(x, 0.68, 0.05), 0.43, 0.15, metal)
				cilindro(self, Vector3(x, 1.55, 0.05), 0.07, 0.42, metal)
	for i in 3:
		var pos := Vector3(2.0 + i * 3.9, 1.25, 0.22)
		farol_en(pos, Color("#b4d4ef") if planta == 2 else (Color("#e8edb1") if planta == 5 else Color("#ffc88c")))

func farol_en(pos: Vector3, color: Color) -> void:
	caja(self, pos - Vector3(0, 0.14, 0), Vector3(0.24, 0.09, 0.23), metal)
	caja(self, pos, Vector3(0.13, 0.23, 0.13), luz)
	var farol := OmniLight3D.new()
	farol.position = pos + Vector3(0, 0.03, 0.32)
	farol.light_color = color
	farol.omni_range = 4.1
	farol.light_energy = 1.48
	add_child(farol)
	luces.append(farol)

func coordenada_plaza(punto: Vector2) -> Vector3:
	var local := punto - Vector2(530, 126)
	return Vector3(local.y / 40.0 + local.x / 78.0, 0.0, local.y / 40.0 - local.x / 78.0)

func construir_detalles_plaza() -> void:
	# La ilustración aporta los edificios. Las mallas solo ocupan zonas libres junto a la mina.
	var base := coordenada_plaza(Vector2(1012, 347))
	var madera_oscura := material(Color("#79583c"), 0.92, 0.0, PIZARRA)
	var caja_mina := Node3D.new()
	caja_mina.position = base
	caja_mina.rotation.y = 0.19
	add_child(caja_mina)
	caja(caja_mina, Vector3(0, 0.15, 0), Vector3(0.49, 0.30, 0.42), madera_oscura)
	for offset in [-0.15, 0.15]:
		caja(caja_mina, Vector3(offset, 0.302, 0), Vector3(0.071, 0.043, 0.43), bronce)
		caja(caja_mina, Vector3(offset, 0.15, 0.217), Vector3(0.071, 0.31, 0.032), bronce)
	var barril := coordenada_plaza(Vector2(1046, 348))
	cilindro(self, barril + Vector3(0, 0.21, 0), 0.16, 0.42, madera_oscura)
	for altura_banda in [0.11, 0.32]:
		cilindro(self, barril + Vector3(0, altura_banda, 0), 0.165, 0.032, metal)
	var chispa := SphereMesh.new()
	chispa.radius = 0.025
	chispa.height = 0.05
	chispa.radial_segments = 8
	chispa.rings = 4
	chispa.material = luz
	for i in 14:
		chispas.append(malla(self, chispa, Vector3.ZERO))
	actualizar_plaza(0.0)

func actualizar_plaza(tiempo: float) -> void:
	var forja := coordenada_plaza(Vector2(273, 269))
	for i in chispas.size():
		var fase := fmod(tiempo * (0.76 + (i % 4) * 0.09) + i * 0.143, 1.0)
		var deriva := sin(tiempo * 2.0 + i * 2.4) * fase * 0.12
		chispas[i].position = forja + Vector3(deriva + float(i % 3) * 0.061, fase * 0.75, deriva * 0.4)
		chispas[i].scale = Vector3.ONE * (0.17 + 0.73 * (1.0 - fase))

func construir_muros() -> void:
	for extremo in [Vector2(0, 7.55), Vector2(10.2, 12)]:
		var ancho: float = extremo.y - extremo.x
		var centro: float = extremo.x + ancho * 0.5
		caja(self, Vector3(centro, 0.76, -0.18), Vector3(ancho, 1.52, 0.37), piedra)
		caja(self, Vector3(centro, 1.54, -0.18), Vector3(ancho, 0.14, 0.52), piedra)
	for x in [0.3, 2.65, 5.25, 7.55, 10.2, 11.7]:
		caja(self, Vector3(x, 0.92, -0.1), Vector3(0.34, 1.84, 0.49), piedra)
		caja(self, Vector3(x, 0.13, 0.01), Vector3(0.52, 0.26, 0.62), piedra)
	caja(self, Vector3(8.875, 1.77, -0.08), Vector3(2.9, 0.26, 0.58), piedra)
	construir_pilar(1.40)
	for pos in [Vector3(1.7, 1.14, 0.29), Vector3(6.1, 1.31, 0.31), Vector3(10.9, 1.15, 0.33)]:
		caja(self, pos - Vector3(0, 0.16, 0), Vector3(0.23, 0.1, 0.35), bronce)
		caja(self, pos, Vector3(0.13, 0.24, 0.13), luz)
		var farol := OmniLight3D.new()
		farol.position = pos + Vector3(0, 0.12, 0.42)
		farol.light_color = Color("#ffc88c")
		farol.omni_range = 4.0
		farol.light_energy = 1.48
		add_child(farol)
		luces.append(farol)

func construir_maquinaria() -> void:
	compuerta = Node3D.new()
	compuerta.name = "Compuerta"
	compuerta.position = Vector3(8.87, 0.02, -0.06)
	add_child(compuerta)
	for x in 10:
		var viga := (float(x) - 4.5) * 0.235
		caja(compuerta, Vector3(viga, 0.75, 0), Vector3(0.219, 1.5, 0.15), madera)
		for y in [0.27, 1.21]:
			caja(compuerta, Vector3(viga, y, 0.113), Vector3(0.065, 0.075, 0.06), bronce)
	for y in [0.27, 1.21]:
		caja(compuerta, Vector3(0, y, 0.07), Vector3(2.43, 0.13, 0.1), metal)
	cilindro(self, Vector3(3.12, 0.42, 0.58), 0.50, 0.83, metal)
	cilindro(self, Vector3(3.12, 0.83, 0.58), 0.56, 0.12, bronce)
	for x in [3.12, 3.58, 4.04]:
		cilindro(self, Vector3(x, 1.13, 0.58), 0.103, 0.62, bronce)
		cilindro(self, Vector3(x, 1.36, 0.58), 0.14, 0.068, metal)
	caja(self, Vector3(3.58, 1.46, 0.58), Vector3(1.22, 0.17, 0.17), bronce)
	for x in [0.65, 1.0, 1.35]:
		var tubo := cilindro(self, Vector3(x, 0.30, 1.0), 0.10, 1.7, bronce)
		tubo.rotation.x = PI * 0.5
	volante = Node3D.new()
	volante.position = Vector3(3.12, 0.61, 1.085)
	add_child(volante)
	for i in 8:
		var angulo := TAU * i / 8.0
		var brazo := caja(volante, Vector3.ZERO, Vector3(0.057, 0.74, 0.071), bronce)
		brazo.rotation.z = angulo
	var aro := TorusMesh.new()
	aro.inner_radius = 0.31
	aro.outer_radius = 0.40
	aro.rings = 16
	aro.ring_segments = 10
	aro.material = bronce
	var rueda := malla(volante, aro, Vector3.ZERO)
	rueda.rotation.x = PI * 0.5

func construir_pasarela() -> void:
	var z := PASARELA.get_center().y
	for i in 16:
		var x := PASARELA.position.x + (i + 0.5) * PASARELA.size.x / 16
		var alto := altura(Vector2(x, z))
		caja(self, Vector3(x, alto - 0.06, z), Vector3(0.403, 0.12, PASARELA.size.y), madera)
	for x in [5.95, 7.4, 8.85, 10.3, 11.75]:
		caja(self, Vector3(x, 0.12, z), Vector3(0.10, 0.28, 0.94), metal)
		for lado in [-0.49, 0.49]:
			caja(self, Vector3(x, 0.47, z + lado), Vector3(0.075, 0.55, 0.075), metal)
	for lado in [-0.49, 0.49]:
		caja(self, Vector3(8.85, 0.74, z + lado), Vector3(5.87, 0.07, 0.07), bronce)

func construir_crecida() -> void:
	material_crecida = material(Color("#f4bd5c67"), 0.8)
	material_crecida.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_crecida.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var espuma := material(Color("#d5f4ec67"), 0.8)
	espuma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	espuma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for canal: Rect2 in CANALES:
		var plano := PlaneMesh.new()
		plano.size = canal.size
		plano.material = material_crecida
		var centro := canal.get_center()
		var agua := malla(self, plano, Vector3(centro.x, 0.018, centro.y))
		agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		agua.hide()
		superficies_crecida.append(agua)
		for i in 4:
			var onda := PlaneMesh.new()
			onda.size = Vector2(canal.size.x - 0.09, 0.018)
			onda.material = espuma
			var franja := malla(self, onda, Vector3(centro.x, 0.024, centro.y))
			franja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			franja.hide()
			ondas_crecida.append(franja)

func actualizar(fase: float, tiempo: float) -> void:
	if planta == 3:
		compuerta.position.y = 0.02 + smoothstep(6.4, 9.0, fase) * 1.22
		volante.rotation.z = -tiempo * 0.65
		material_crecida.albedo_color = Color("#53aabcac") if fase >= 9.0 else Color("#f4bd5c67")
		for superficie in superficies_crecida:
			superficie.visible = fase >= 6.4
		for i in ondas_crecida.size():
			var franja := ondas_crecida[i]
			var canal: Rect2 = CANALES[0 if i < 4 else 1]
			franja.visible = fase >= 9.0
			franja.position.z = canal.position.y + fmod(tiempo * 0.71 + (i % 4) * canal.size.y / 4.0, canal.size.y)
	for i in luces.size():
		luces[i].light_energy = 1.43 + sin(tiempo * 5.0 + i * 2.1) * 0.12

func material(color: Color, rugosidad: float, metalico := 0.0, textura: Texture2D = null) -> StandardMaterial3D:
	var acabado := StandardMaterial3D.new()
	acabado.albedo_color = color
	acabado.albedo_texture = textura
	acabado.roughness = rugosidad
	acabado.metallic = metalico
	return acabado

func caja(padre: Node, centro: Vector3, dimensiones: Vector3, acabado: Material) -> MeshInstance3D:
	var forma := BoxMesh.new()
	forma.size = dimensiones
	forma.material = acabado
	return malla(padre, forma, centro)

func cilindro(padre: Node, centro: Vector3, radio: float, largo: float, acabado: Material) -> MeshInstance3D:
	var forma := CylinderMesh.new()
	forma.top_radius = radio
	forma.bottom_radius = radio
	forma.height = largo
	forma.radial_segments = 16
	forma.rings = 0
	forma.material = acabado
	return malla(padre, forma, centro)

func malla(padre: Node, forma: Mesh, centro: Vector3) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	objeto.mesh = forma
	objeto.position = centro
	padre.add_child(objeto)
	return objeto
