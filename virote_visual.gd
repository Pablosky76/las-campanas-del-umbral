extends Node3D

static var astil: CylinderMesh
static var punta: CylinderMesh
static var pluma: BoxMesh
static var puntas: Dictionary[Color, StandardMaterial3D] = {}

func montar(madera: StandardMaterial3D, color_punta: Color) -> void:
	if astil == null:
		astil = CylinderMesh.new()
		astil.top_radius = 0.026
		astil.bottom_radius = 0.026
		astil.height = 0.37
		astil.radial_segments = 6
		astil.rings = 0
		punta = CylinderMesh.new()
		punta.top_radius = 0.0
		punta.bottom_radius = 0.060
		punta.height = 0.14
		punta.radial_segments = 4
		punta.rings = 0
		pluma = BoxMesh.new()
		pluma.size = Vector3(0.024, 0.097, 0.135)
	if not puntas.has(color_punta):
		var acabado := StandardMaterial3D.new()
		acabado.albedo_color = color_punta
		acabado.emission_enabled = true
		acabado.emission = color_punta
		acabado.emission_energy_multiplier = 0.58
		acabado.roughness = 0.63
		puntas[color_punta] = acabado
	pieza(astil, Vector3(0, 0, -0.24), madera).rotation.x = PI * 0.5
	pieza(punta, Vector3(0, 0, -0.065), puntas[color_punta]).rotation.x = PI * 0.5
	pieza(pluma, Vector3(0, 0, -0.43), puntas[color_punta])
	pieza(pluma, Vector3(0, 0, -0.43), puntas[color_punta]).rotation.z = PI * 0.5

func actualizar(posicion: Vector2, direccion: Vector2, nivel: float) -> void:
	position = Vector3(posicion.x, nivel + 1.13, posicion.y)
	rotation.y = atan2(direccion.x, direccion.y)

func pieza(malla: Mesh, centro: Vector3, acabado: Material) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	objeto.mesh = malla
	objeto.position = centro
	objeto.material_override = acabado
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(objeto)
	return objeto
