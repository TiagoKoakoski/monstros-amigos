class_name Progresso
extends RefCounted
## O que atravessa partidas: as fases que a criança já alcançou
## ("castelo", "laboratorio", ...). Cada uma deixa a passagem dela aberta.

var _caminho := ""
var _cfg := ConfigFile.new()


func _init(caminho: String) -> void:
	_caminho = caminho
	_cfg.load(_caminho)  # arquivo ainda não existe = tudo fechado


func alcancou(fase: String) -> bool:
	if bool(_cfg.get_value("fases", fase, false)):
		return true
	# formato antigo (antes do laboratório): só sabia do castelo
	return fase == "castelo" and bool(_cfg.get_value("jogo", "castelo_aberto", false))


func marcar(fase: String) -> void:
	_cfg.set_value("fases", fase, true)
	_cfg.save(_caminho)


func castelo_aberto() -> bool:
	return alcancou("castelo")


func marcar_castelo_aberto() -> void:
	marcar("castelo")


func apagar() -> void:
	_cfg = ConfigFile.new()
	if FileAccess.file_exists(_caminho):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_caminho))
