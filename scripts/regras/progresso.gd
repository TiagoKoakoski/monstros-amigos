class_name Progresso
extends RefCounted
## O que atravessa partidas: se a criança já chegou no castelo alguma vez.

var _caminho := ""
var _cfg := ConfigFile.new()


func _init(caminho: String) -> void:
	_caminho = caminho
	_cfg.load(_caminho)  # arquivo ainda não existe = tudo fechado


func castelo_aberto() -> bool:
	return bool(_cfg.get_value("jogo", "castelo_aberto", false))


func marcar_castelo_aberto() -> void:
	_cfg.set_value("jogo", "castelo_aberto", true)
	_cfg.save(_caminho)


func apagar() -> void:
	_cfg = ConfigFile.new()
	if FileAccess.file_exists(_caminho):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_caminho))
