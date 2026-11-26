extends Node3D

const HUESO := Color("#d7cbb0")
const OSCURO := Color("#272b32")
const HIERRO := Color("#555765")
const BRONCE := Color("#ad8151")
const PURPURA := Color("#514563")
const VERDE := Color("#a2e878")
const SOMBRA := Color("#17171d")
const CARA := Color("#c2afa1")

static var materiales: Dictionary = {}
static var mallas: Dictionary = {}
var especie := ""
var cuerpo: Node3D
var brazo_derecho: Node3D
var brazo_izquierdo: Node3D
var capa: MeshInstance3D
var piernas: Array[Node3D] = []
var boca: Node3D
var cola: Node3D
var punto_farol: Node3D
var tela: StandardMaterial3D
var pausa_paso := 0.0
var color_tela := OSCURO

func montar(rol: String, proyectar_sombra: bool) -> void:
	especie = rol
	cuerpo = pivote(self, Vector3.ZERO)
	match rol:
		"sabueso":
			sabueso()
		"guardian":
			custodio()
		"ballestero":
			ballestero()
		"player":
			vinculador()
		_:
			enemigo(rol)

	# Unas pocas piezas principales proyectan la silueta articulada cada fotograma.
	if proyectar_sombra:
		var piezas := cuerpo.find_children("*", "MeshInstance3D", true, false)
		var activadas := 0
		for nodo in piezas:
			var malla: MeshInstance3D = nodo
			if malla.mesh.get_aabb().get_longest_axis_size() * maxf(malla.scale.x, maxf(malla.scale.y, malla.scale.z)) < 0.21:
				continue
			malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			activadas += 1
			if activadas >= 8:
				break

func posar(rumbo: Vector2, fase: float, marcha: bool, golpe: float, tinte: Color, altura: float, escala: float, aspecto: int, delta: float) -> void:
	var referencia := 0.97 if especie == "sabueso" else (2.29 if especie == "player" else 2.09)
	scale = Vector3.ONE * altura / (escala * 0.86 * referencia)
	var objetivo := atan2(rumbo.x, rumbo.y)
	rotation.y = lerp_angle(rotation.y, objetivo, 1.0 - exp(-delta * 17.0))
	var paso := 0.50 if especie in ["sabueso", "acechador"] else (0.29 if especie in ["guardian", "capataz", "verdugo", "campanero"] else 0.40)
	pausa_paso = lerpf(pausa_paso, paso if marcha else 0.0, 1.0 - exp(-delta * 14.0))
	var amplitud := pausa_paso
	var oscilacion := sin(fase)
	cuerpo.position.y = absf(oscilacion) * (0.041 if marcha else 0.012)
	cuerpo.rotation.x = (0.06 if marcha else 0.0) + golpe * 0.12
	for i in piernas.size():
		var alterno := (i + i / 2) % 2 if piernas.size() == 4 else i % 2
		piernas[i].rotation.x = oscilacion * amplitud * (1 if alterno == 0 else -1)
	if brazo_derecho:
		brazo_derecho.rotation.x = -oscilacion * amplitud * 0.58 - golpe * (0.78 if especie == "guardian" else 0.42)
	if brazo_izquierdo:
		brazo_izquierdo.rotation.x = oscilacion * amplitud * 0.50 - golpe * 0.22
	if capa:
		capa.rotation.x = sin(fase * 0.76) * (0.13 if marcha else 0.047) + golpe * 0.21
	if boca:
		boca.rotation.x = golpe * 0.38
	if cola:
		cola.rotation.y = sin(fase * 0.93) * 0.18
	var base := Color("#366382") if especie == "player" and aspecto == 1 else color_tela
	if tela:
		base = base.lightened(golpe * (0.13 if especie == "player" else 0.055))
	var nuevo_color := base * tinte
	if tela and not tela.albedo_color.is_equal_approx(nuevo_color):
		tela.albedo_color = nuevo_color

func vinculador() -> void:
	tela = acabado(OSCURO).duplicate()
	cono(cuerpo, Vector3(0, 0.76, 0), 0.27, 0.40, 0.82, OSCURO, 10).material_override = tela
	cono(cuerpo, Vector3(0, 1.39, 0), 0.32, 0.23, 0.54, HIERRO, 8)
	armar_capa()
	for i in 3:
		var y := 1.29 + i * 0.115
		for lado in [-1, 1]:
			viga(cuerpo, Vector3(lado * 0.052, y, 0.24), Vector3(lado * 0.253, y + 0.064, 0.18), 0.071, HUESO)
	cono(cuerpo, Vector3(0, 1.025, 0), 0.29, 0.29, 0.10, BRONCE, 10)
	campana(cuerpo, Vector3(0.14, 0.91, 0.30), 0.07)
	caja(cuerpo, Vector3(-0.20, 1.01, 0.21), Vector3(0.12, 0.20, 0.13), Color("#765a43")).rotation.z = 0.18
	esfera(cuerpo, Vector3(0, 1.56, 0.267), Vector3(0.13, 0.15, 0.039), BRONCE)
	viga(cuerpo, Vector3(-0.17, 1.55, 0.243), Vector3(0.16, 1.18, 0.227), 0.039, BRONCE)
	var cabeza := pivote(cuerpo, Vector3(0, 1.80, 0))
	esfera(cabeza, Vector3(0, 0.07, -0.053), Vector3(0.55, 0.55, 0.51), OSCURO).material_override = tela
	cono(cabeza, Vector3(0, 0.284, -0.13), 0.012, 0.19, 0.30, OSCURO, 7).material_override = tela
	esfera(cabeza, Vector3(0, 0.045, 0.15), Vector3(0.30, 0.35, 0.27), CARA)
	for lado in [-1, 1]:
		esfera(cabeza, Vector3(lado * 0.066, 0.09, 0.255), Vector3(0.045, 0.028, 0.025), SOMBRA)
		armar_pierna(Vector3(lado * 0.149, 0.71, 0.0), OSCURO, HIERRO)
	brazo_derecho = brazo(Vector3(-0.31, 1.57, 0), OSCURO, HUESO)
	brazo_izquierdo = brazo(Vector3(0.31, 1.57, 0), OSCURO, HUESO)
	var vara := pivote(brazo_derecho, Vector3(-0.15, -0.46, 0.18))
	cono(vara, Vector3(0, -0.105, 0), 0.041, 0.052, 1.76, Color("#554836"), 7)
	viga(vara, Vector3(0, 0.69, 0), Vector3(-0.20, 0.91, 0.03), 0.066, BRONCE)
	campana(vara, Vector3(-0.11, 0.73, 0.04), 0.064)
	var farol := Vector3(-0.25, 0.62, 0.09)
	punto_farol = pivote(vara, farol)
	cono(vara, farol + Vector3(0, 0.126, 0), 0.028, 0.119, 0.069, BRONCE, 6)
	cono(vara, farol - Vector3(0, 0.11, 0), 0.105, 0.07, 0.05, BRONCE, 6)
	esfera(vara, farol, Vector3(0.12, 0.22, 0.12), VERDE, true)
	for i in 4:
		var offset := Vector3(cos(float(i) * PI * 0.5), 0, sin(float(i) * PI * 0.5)) * 0.095
		viga(vara, farol + offset - Vector3(0, 0.12, 0), farol + offset + Vector3(0, 0.115, 0), 0.021, HIERRO)

func ballestero() -> void:
	color_tela = PURPURA
	tela = acabado(PURPURA).duplicate()
	cono(cuerpo, Vector3(0, 0.94, 0.00), 0.18, 0.27, 0.44, PURPURA, 7).material_override = tela
	cono(cuerpo, Vector3(0, 1.35, -0.04), 0.22, 0.15, 0.56, PURPURA, 7).material_override = tela
	for i in 4:
		var y := 1.20 + i * 0.105
		for lado in [-1, 1]:
			viga(cuerpo, Vector3(lado * 0.025, y, 0.148), Vector3(lado * 0.19, y + 0.041, 0.117), 0.053, HUESO)
	calavera(cuerpo, Vector3(0, 1.83, 0.01), true)
	armar_pierna(Vector3(-0.13, 0.75, 0.0), HUESO, HIERRO)
	armar_pierna(Vector3(0.13, 0.75, 0.0), HUESO, HIERRO)
	brazo_derecho = brazo(Vector3(-0.24, 1.49, 0.02), HUESO, HUESO)
	brazo_izquierdo = brazo(Vector3(0.24, 1.49, 0.02), HUESO, HUESO)
	var carcaj := pivote(cuerpo, Vector3(0.19, 1.1, -0.25))
	carcaj.rotation.z = -0.27
	cono(carcaj, Vector3.ZERO, 0.097, 0.075, 0.46, Color("#654f3d"), 6)
	for i in 3:
		var virote := Vector3((i - 1) * 0.051, 0.24, 0)
		viga(carcaj, virote, virote + Vector3(0, 0.22 + 0.03 * i, 0), 0.026, HUESO)
	var arma := pivote(brazo_derecho, Vector3(0.21, -0.42, 0.34))
	caja(arma, Vector3(0.02, 0.0, 0.22), Vector3(0.10, 0.11, 0.67), Color("#685342"))
	caja(arma, Vector3(0.02, 0.061, 0.26), Vector3(0.075, 0.026, 0.55), HIERRO)
	for lado in [-1, 1]:
		viga(arma, Vector3(0.02, 0.052, 0.40), Vector3(lado * 0.31, 0.052, 0.32), 0.068, BRONCE)
		viga(arma, Vector3(lado * 0.31, 0.052, 0.32), Vector3(lado * 0.37, 0.064, 0.19), 0.044, HIERRO)
		viga(arma, Vector3(lado * 0.37, 0.064, 0.19), Vector3(0.02, 0.064, 0.12), 0.015, HUESO)

func custodio() -> void:
	color_tela = Color("#414044")
	tela = acabado(color_tela).duplicate()
	cono(cuerpo, Vector3(0, 1.29, 0), 0.42, 0.28, 0.63, HIERRO, 8)
	cono(cuerpo, Vector3(0, 0.83, 0), 0.25, 0.36, 0.47, color_tela, 7).material_override = tela
	for y in [1.15, 1.32, 1.49]:
		caja(cuerpo, Vector3(0, y, 0.30), Vector3(0.51, 0.13, 0.095), BRONCE)
	calavera(cuerpo, Vector3(0, 1.82, 0.0), false)
	cono(cuerpo, Vector3(0, 2.055, -0.055), 0.03, 0.24, 0.245, HIERRO, 7)
	for lado in [-1, 1]:
		armar_pierna(Vector3(lado * 0.221, 0.76, 0), HIERRO, BRONCE)
	brazo_derecho = brazo(Vector3(-0.40, 1.54, 0.01), HIERRO, HUESO)
	brazo_izquierdo = brazo(Vector3(0.40, 1.54, 0.01), HIERRO, HUESO)
	viga(brazo_derecho, Vector3(-0.025, -0.81, 0.22), Vector3(-0.025, -0.03, 0.22), 0.071, Color("#5f4a37"))
	caja(brazo_derecho, Vector3(-0.13, -0.12, 0.23), Vector3(0.34, 0.24, 0.13), HIERRO)
	var soporte := pivote(brazo_izquierdo, Vector3(0.11, -0.42, 0.40))
	soporte.rotation.y = 0.12
	escudo(soporte)
	for lado in [-1, 1]:
		var placa := caja(cuerpo, Vector3(lado * 0.34, 1.59, -0.08), Vector3(0.23, 0.117, 0.45), BRONCE)
		placa.rotation.z = -lado * 0.36

func sabueso() -> void:
	caja(cuerpo, Vector3(0, 0.67, -0.085), Vector3(0.33, 0.36, 0.77), SOMBRA)
	viga(cuerpo, Vector3(0, 0.86, -0.54), Vector3(0, 0.85, 0.42), 0.089, HUESO)
	for i in 4:
		var z := -0.38 + i * 0.19
		for lado in [-1, 1]:
			var mid := Vector3(lado * 0.23, 0.68, z + 0.036)
			viga(cuerpo, Vector3(lado * 0.045, 0.83, z), mid, 0.054, HUESO)
			viga(cuerpo, mid, Vector3(lado * 0.063, 0.51, z + 0.106), 0.052, HUESO)
	for z in [0.35, -0.44]:
		for lado in [-1, 1]:
			var pata := pivote(cuerpo, Vector3(lado * 0.164, 0.58, z))
			piernas.append(pata)
			esfera(pata, Vector3(0, -0.036, 0), Vector3(0.20, 0.22, 0.20), HUESO)
			viga(pata, Vector3.ZERO, Vector3(lado * 0.048, -0.25, -0.08), 0.096, HUESO)
			viga(pata, Vector3(lado * 0.048, -0.25, -0.08), Vector3(lado * 0.04, -0.51, 0.04), 0.067, HUESO)
			caja(pata, Vector3(lado * 0.04, -0.55, 0.09), Vector3(0.15, 0.074, 0.22), HUESO)
	for i in 4:
		var placa := caja(cuerpo, Vector3(0, 0.835, -0.42 + i * 0.22), Vector3(0.27, 0.069, 0.105), HIERRO)
		placa.rotation.x = 0.11
	var cuello := pivote(cuerpo, Vector3(0, 0.71, 0.41))
	cono(cuello, Vector3(0, 0.011, 0.05), 0.17, 0.17, 0.12, BRONCE, 9).rotation.x = PI * 0.5
	esfera(cuello, Vector3(0, 0.038, 0.22), Vector3(0.36, 0.31, 0.35), HUESO)
	caja(cuello, Vector3(0, -0.015, 0.42), Vector3(0.23, 0.14, 0.29), HUESO)
	boca = pivote(cuello, Vector3(0, -0.082, 0.25))
	caja(boca, Vector3(0, -0.065, 0.151), Vector3(0.21, 0.061, 0.29), HUESO)
	for lado in [-1, 1]:
		esfera(cuello, Vector3(lado * 0.147, 0.076, 0.302), Vector3(0.071, 0.059, 0.057), SOMBRA)
		esfera(cuello, Vector3(lado * 0.164, 0.077, 0.315), Vector3(0.032, 0.029, 0.030), VERDE, true)
		cono(cuello, Vector3(lado * 0.095, -0.108, 0.469), 0.041, 0.003, 0.105, HUESO, 5)
	cola = pivote(cuerpo, Vector3(0, 0.74, -0.51))
	viga(cola, Vector3.ZERO, Vector3(0, 0.1, -0.26), 0.074, HUESO)
	viga(cola, Vector3(0, 0.1, -0.26), Vector3(0, 0.015, -0.47), 0.048, HUESO)

func enemigo(rol: String) -> void:
	var verdugo := rol in ["capataz", "verdugo", "campanero"]
	var conjurador := rol in ["enterrador", "corista"]
	var ligero := rol in ["acechador", "reanimado"]
	color_tela = Color("#7d403b") if verdugo else (Color("#435b48") if conjurador else Color("#63554a"))
	tela = acabado(color_tela).duplicate()
	var hombros := 0.37 if verdugo else (0.24 if ligero else 0.29)
	var armadura := HIERRO if verdugo else color_tela
	cono(cuerpo, Vector3(0, 1.31, 0), hombros, 0.19, 0.58, armadura, 8).material_override = tela
	cono(cuerpo, Vector3(0, 0.93, 0), 0.20, 0.27, 0.36, color_tela, 8).material_override = tela
	cono(cuerpo, Vector3(0, 1.04, 0), 0.24, 0.24, 0.09, BRONCE, 8)
	if conjurador:
		armar_capa()
		cono(cuerpo, Vector3(0, 0.62, -0.05), 0.24, 0.38, 0.95, color_tela, 8).material_override = tela
	calavera(cuerpo, Vector3(0, 1.77, 0.0), conjurador or ligero)
	if verdugo:
		for lado in [-1, 1]:
			caja(cuerpo, Vector3(lado * 0.29, 1.51, 0.19), Vector3(0.16, 0.13, 0.28), BRONCE).rotation.z = lado * 0.30
	elif rol == "minero":
		caja(cuerpo, Vector3(0.14, 1.07, 0.16), Vector3(0.19, 0.22, 0.14), Color("#896744"))
	if verdugo or rol == "minero":
		var visera := pivote(cuerpo, Vector3(0, 1.87, -0.015))
		cono(visera, Vector3(0, 0.035, 0), 0.19, 0.234, 0.18, HIERRO, 8)
		cono(visera, Vector3(0, -0.053, 0), 0.245, 0.245, 0.05, BRONCE, 8)
		esfera(visera, Vector3(0, 0.014, 0.218), Vector3(0.094, 0.087, 0.07), Color("#f0a36c"), true)
	for lado in [-1, 1]:
		armar_pierna(Vector3(lado * 0.16, 0.76, 0), color_tela if not ligero else HUESO, HIERRO)
	brazo_derecho = brazo(Vector3(-hombros, 1.52, 0), armadura, HUESO)
	brazo_izquierdo = brazo(Vector3(hombros, 1.52, 0), armadura, HUESO)
	if ligero:
		for lado in [-1, 1]:
			var guante := brazo_derecho if lado == -1 else brazo_izquierdo
			for i in 3:
				viga(guante, Vector3((i - 1) * 0.047, -0.59, 0.22), Vector3((i - 1) * 0.065, -0.66, 0.34), 0.035, HUESO)
		return
	var arma := pivote(brazo_derecho, Vector3(0, -0.52, 0.20))
	if conjurador:
		viga(arma, Vector3(0, -0.90, 0), Vector3(0, 0.85, 0), 0.088, Color("#554736"))
		campana(arma, Vector3(0, 0.80, 0.04), 0.16)
		esfera(arma, Vector3(0, 0.96, 0), Vector3.ONE * 0.15, Color("#b5ed91"), true)
	elif rol == "campanero":
		viga(arma, Vector3(0, -0.4, 0.13), Vector3(0, 0.48, 0.13), 0.092, Color("#584638"))
		campana(arma, Vector3(0, 0.51, 0.13), 0.27)
	elif verdugo:
		viga(arma, Vector3(0, -0.31, 0.2), Vector3(0, 0.51, 0.2), 0.092, Color("#584638"))
		caja(arma, Vector3(0, 0.44, 0.2), Vector3(0.34, 0.27, 0.39), HIERRO)
		caja(arma, Vector3(0, 0.44, 0.397), Vector3(0.30, 0.24, 0.03), BRONCE)
	else:
		viga(arma, Vector3(0, -0.3, 0), Vector3(0, 0.43, 0), 0.068, Color("#6f5238"))
		viga(arma, Vector3(0, 0.41, -0.24), Vector3(0, 0.43, 0.23), 0.075, HIERRO)
		viga(arma, Vector3(0, 0.41, 0.23), Vector3(0, 0.30, 0.37), 0.045, HIERRO)

func calavera(padre: Node3D, posicion: Vector3, capucha: bool) -> void:
	var cráneo := pivote(padre, posicion)
	if capucha:
		esfera(cráneo, Vector3(0, 0.026, -0.044), Vector3(0.488, 0.47, 0.44), PURPURA).material_override = tela
	esfera(cráneo, Vector3(0, 0.038, 0.075), Vector3(0.32, 0.34, 0.32), HUESO)
	caja(cráneo, Vector3(0, -0.10, 0.154), Vector3(0.19, 0.104, 0.15), HUESO)
	for lado in [-1, 1]:
		esfera(cráneo, Vector3(lado * 0.073, 0.036, 0.202), Vector3(0.098, 0.075, 0.05), SOMBRA)
		esfera(cráneo, Vector3(lado * 0.073, 0.039, 0.228), Vector3(0.025, 0.019, 0.023), VERDE, true)
	caja(cráneo, Vector3(0, -0.075, 0.236), Vector3(0.124, 0.017, 0.02), SOMBRA)

func brazo(punto: Vector3, color: Color, mano: Color) -> Node3D:
	var articulacion := pivote(cuerpo, punto)
	esfera(articulacion, Vector3.ZERO, Vector3(0.28, 0.27, 0.29), color.lightened(0.22))
	viga(articulacion, Vector3.ZERO, Vector3(0, -0.31, 0.047), 0.16, color)
	viga(articulacion, Vector3(0, -0.31, 0.047), Vector3(0, -0.52, 0.17), 0.127, color.lightened(0.18))
	esfera(articulacion, Vector3(0, -0.535, 0.185), Vector3(0.147, 0.15, 0.14), mano)
	return articulacion

func armar_pierna(punto: Vector3, color: Color, bota: Color) -> void:
	var pierna := pivote(cuerpo, punto)
	piernas.append(pierna)
	viga(pierna, Vector3.ZERO, Vector3(0, -0.32, -0.02), 0.153, color)
	viga(pierna, Vector3(0, -0.30, -0.02), Vector3(0, -0.65, 0.014), 0.136, bota)
	caja(pierna, Vector3(0, -0.676, 0.084), Vector3(0.171, 0.107, 0.28), bota)

func armar_capa() -> void:
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 9:
		var a := deg_to_rad(28 + i * 15.5)
		var b := deg_to_rad(28 + (i + 1) * 15.5)
		var cima_a := Vector3(cos(a) * 0.31, 0.0, -sin(a) * 0.24)
		var cima_b := Vector3(cos(b) * 0.31, 0.0, -sin(b) * 0.24)
		var bajo_a := Vector3(cos(a) * 0.59, -1.30 + (i % 2) * 0.10, -sin(a) * 0.49)
		var bajo_b := Vector3(cos(b) * 0.59, -1.30 + ((i + 1) % 2) * 0.10, -sin(b) * 0.49)
		for vertice in [cima_a, bajo_a, cima_b, cima_b, bajo_a, bajo_b]:
			superficie.add_vertex(vertice)
	superficie.generate_normals()
	tela.cull_mode = BaseMaterial3D.CULL_DISABLED
	capa = pieza(cuerpo, superficie.commit(), Vector3(0, 1.61, -0.04), tela)

func escudo(padre: Node3D) -> void:
	var perfil := PackedVector2Array([Vector2(-0.30, 0.44), Vector2(0.30, 0.44), Vector2(0.35, 0.18),
		Vector2(0.27, -0.29), Vector2(0, -0.51), Vector2(-0.27, -0.29), Vector2(-0.35, 0.18)])
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in perfil.size():
		var a := perfil[i]
		var b := perfil[(i + 1) % perfil.size()]
		for vertice in [Vector3(0, 0, 0.15), Vector3(a.x, a.y, 0.055), Vector3(b.x, b.y, 0.055),
			Vector3(a.x, a.y, 0.055), Vector3(a.x, a.y, -0.056), Vector3(b.x, b.y, 0.055),
			Vector3(b.x, b.y, 0.055), Vector3(a.x, a.y, -0.056), Vector3(b.x, b.y, -0.056),
			Vector3.ZERO - Vector3(0, 0, 0.056), Vector3(b.x, b.y, -0.056), Vector3(a.x, a.y, -0.056)]:
			superficie.add_vertex(vertice)
		viga(padre, Vector3(a.x, a.y, 0.059), Vector3(b.x, b.y, 0.059), 0.053, BRONCE)
	superficie.generate_normals()
	pieza(padre, superficie.commit(), Vector3.ZERO, acabado(HIERRO))
	esfera(padre, Vector3(0, 0.12, 0.149), Vector3(0.19, 0.22, 0.104), HUESO)
	viga(padre, Vector3(0, 0.035, 0.16), Vector3(0, -0.35, 0.093), 0.047, HUESO)
	for y in [-0.05, -0.14, -0.22]:
		for lado in [-1, 1]:
			viga(padre, Vector3(0, y, 0.15), Vector3(lado * 0.152, y + 0.054, 0.109), 0.035, HUESO)

func campana(padre: Node3D, punto: Vector3, radio: float) -> void:
	cono(padre, punto, radio * 0.58, radio, radio * 1.65, BRONCE, 8)
	esfera(padre, punto - Vector3(0, radio * 0.75, 0), Vector3.ONE * radio * 0.67, HIERRO)

func pivote(padre: Node3D, punto: Vector3) -> Node3D:
	var objeto := Node3D.new()
	objeto.position = punto
	padre.add_child(objeto)
	return objeto

func acabado(color: Color, emisivo := false) -> StandardMaterial3D:
	var clave := [color, emisivo]
	if not materiales.has(clave):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.82 if color != BRONCE else 0.58
		if emisivo:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 0.60
		materiales[clave] = mat
	return materiales[clave]

func pieza(padre: Node3D, malla: Mesh, punto: Vector3, mat: Material) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	objeto.mesh = malla
	objeto.material_override = mat
	objeto.position = punto
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(objeto)
	return objeto

func caja(padre: Node3D, punto: Vector3, dimensiones: Vector3, color: Color) -> MeshInstance3D:
	var clave := ["caja", dimensiones]
	if not mallas.has(clave):
		var malla := BoxMesh.new()
		malla.size = dimensiones
		mallas[clave] = malla
	return pieza(padre, mallas[clave], punto, acabado(color))

func esfera(padre: Node3D, punto: Vector3, dimensiones: Vector3, color: Color, brillo := false) -> MeshInstance3D:
	var clave := ["esfera"]
	if not mallas.has(clave):
		var malla := SphereMesh.new()
		malla.radius = 0.5
		malla.height = 1.0
		malla.rings = 6
		malla.radial_segments = 10
		mallas[clave] = malla
	var objeto := pieza(padre, mallas[clave], punto, acabado(color, brillo))
	objeto.scale = dimensiones
	return objeto

func cono(padre: Node3D, punto: Vector3, radio_arriba: float, radio_abajo: float, altura: float, color: Color, lados: int) -> MeshInstance3D:
	var clave := ["cono", radio_arriba, radio_abajo, altura, lados]
	if not mallas.has(clave):
		var malla := CylinderMesh.new()
		malla.top_radius = radio_arriba
		malla.bottom_radius = radio_abajo
		malla.height = altura
		malla.radial_segments = lados
		malla.rings = 0
		mallas[clave] = malla
	return pieza(padre, mallas[clave], punto, acabado(color))

func viga(padre: Node3D, desde: Vector3, hasta: Vector3, diametro: float, color: Color) -> void:
	var direccion := hasta - desde
	var objeto := cono(padre, (desde + hasta) * 0.5, diametro * 0.42, diametro * 0.5, direccion.length(), color, 7)
	objeto.basis = Basis(Quaternion(Vector3.UP, direccion.normalized()))
