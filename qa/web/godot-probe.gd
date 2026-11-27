extends Node

# QA copia este autoload solo al proyecto temporal. Publica estado de solo lectura.
var ultima_muestra := ""

func _process(_delta: float) -> void:
	var plaza := get_tree().current_scene
	if plaza == null or not plaza.has_method("descend"):
		return
	var mina: Node = plaza.battle
	var muestra := JSON.stringify({
		"zona": "mina" if is_instance_valid(mina) else "valdebronce",
		"planta": mina.planta if is_instance_valid(mina) else 0,
		"panel": plaza.panel,
		"ritual": mina.ritual if is_instance_valid(mina) else false,
		"silencio": plaza.ambiente.silenciado,
		"posicion": [snappedf(plaza.at.x, 0.5), snappedf(plaza.at.y, 0.5)],
	})
	if muestra == ultima_muestra:
		return
	ultima_muestra = muestra
	JavaScriptBridge.eval("document.documentElement.dataset.umbralQa = %s" % JSON.stringify(muestra), true)
