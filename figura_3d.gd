extends Node3D

const MODELO = preload("res://modelos_sequito.gd")
const ROLES_3D := ["player", "sabueso", "ballestero", "guardian", "minero", "acechador", "reanimado", "capataz", "enterrador", "corista", "verdugo", "campanero"]
var modelo: MODELO
var cuerpo: Sprite3D
var sombra: MeshInstance3D
var proyectar_sombra := false

func _ready() -> void:
	sombra = MeshInstance3D.new()
	sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sombra)

func crear_sprite() -> void:
	cuerpo = Sprite3D.new()
	cuerpo.centered = true
	cuerpo.shaded = true
	cuerpo.double_sided = true
	cuerpo.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	cuerpo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cuerpo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cuerpo)

func actualizar(pies: Vector3, camara: Camera3D, imagen: Texture2D, altura: float, ancho_sombra: float, direccion: bool, tinte: Color, fase: float, marcha: bool, escala: float, malla_sombra: Mesh, ataque := 0.0, rol := "", aspecto := 0, delta := 0.0167, rumbo := Vector2(0.25, 1.0)) -> void:
	position = pies
	if rol in ROLES_3D:
		if modelo == null:
			modelo = MODELO.new()
			add_child(modelo)
			modelo.montar(rol, proyectar_sombra)
		modelo.posar(rumbo, fase, marcha, ataque, tinte, altura, escala, aspecto, delta)
	else:
		if cuerpo == null:
			crear_sprite()
		if cuerpo.texture != imagen:
			cuerpo.texture = imagen
		var tamano := altura / imagen.get_height()
		cuerpo.pixel_size = tamano / escala
		cuerpo.flip_h = direccion
		cuerpo.modulate = tinte
		var pulso := sin(fase)
		var ascenso := absf(pulso) * 2.4 if marcha else (pulso + 1.0) * 0.35
		var inclinacion := pulso * (0.042 if marcha else 0.009) + ataque * (-0.115 if direccion else 0.115)
		var orientacion := camara.basis.rotated(camara.basis.z, inclinacion)
		var proporcion := 1.0 - absf(pulso) * 0.025 if marcha else 1.0
		cuerpo.basis = orientacion.scaled(Vector3(1.0 + (1.0 - proporcion) * 0.45, proporcion, 1.0))
		cuerpo.position = (orientacion.y * (altura * proporcion * 0.5 + ascenso) + camara.basis.x * ataque * (4.0 if direccion else -4.0)) / escala
	if sombra.mesh == null:
		sombra.mesh = malla_sombra
	sombra.position = Vector3(-0.07, 0.014, -0.04)
	sombra.scale = Vector3(ancho_sombra * 2 / escala, 1, ancho_sombra * 1.64 / escala)
