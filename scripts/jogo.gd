extends Node
## Maestro do jogo (autoload "Jogo"): troca de fase com fade e guarda o
## progresso que atravessa partidas (a porta do castelo aberta).
##
## Argumentos (depois de "--"):
##   --autoplay            joga sozinho (teste) — usa um progresso de teste separado
##   --capturas=/pasta     salva fotos dos momentos do teste
##   --fase=castelo        começa direto no castelo
##   --manter-progresso    não apaga o progresso de teste no começo

const JARDIM := "res://scenes/jardim.tscn"
const CASTELO := "res://scenes/castelo.tscn"
const PROGRESSO_REAL := "user://progresso.cfg"
const PROGRESSO_TESTE := "user://progresso_teste.cfg"

var auto := false
var pasta_capturas := ""
var progresso: Progresso
## Sobrevive à troca de fase (o teste de ponta a ponta usa pra lembrar onde está).
var marcos_globais: Dictionary = {}
var ja_iniciou := false

var _fase_inicial := JARDIM
var _cortina: ColorRect
var _trocando := false
var _fotos := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	auto = args.has("--autoplay")
	for a: String in args:
		if a.begins_with("--capturas="):
			pasta_capturas = a.split("=", true, 1)[1]
		if a == "--fase=castelo":
			_fase_inicial = CASTELO
	progresso = Progresso.new(PROGRESSO_TESTE if auto else PROGRESSO_REAL)
	if auto and not args.has("--manter-progresso"):
		progresso.apagar()
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	_cortina = ColorRect.new()
	_cortina.color = Color(0.05, 0.04, 0.12, 0.0)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(_cortina)


func fase_inicial() -> String:
	return _fase_inicial


func trocando() -> bool:
	return _trocando


func trocar_fase(cena: String) -> void:
	if _trocando:
		return
	_trocando = true
	var t := create_tween()
	t.tween_property(_cortina, "color:a", 1.0, 0.4)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(cena))
	t.tween_interval(0.2)
	t.tween_property(_cortina, "color:a", 0.0, 0.4)
	t.tween_callback(func() -> void: _trocando = false)


## Número da próxima foto do teste (continua contando entre as fases).
func proxima_foto() -> int:
	_fotos += 1
	return _fotos
