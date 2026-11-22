extends Node
## Mapa de controles do jogo, montado em código para ficar num lugar só.
##
## Pensado para uma criança de 5 anos no controle: analógico ou setas para andar,
## e TODOS os botões de face fazem a mesma coisa. Sair do jogo fica só no
## teclado (Esc), com o adulto — a criança não fecha o jogo sem querer.

const ZONA_MORTA := 0.25

const ACOES_MOVIMENTO := ["mover_esquerda", "mover_direita", "mover_cima", "mover_baixo"]

## Evento criado por código nasce preso ao controle nº 0; -1 = qualquer controle.
## Sem isso, um controle reconhecido como nº 1 (receptor sem fio, outro pad
## virtual no PC) não faria nada — pego pelo tests/teste_controle_real.gd.
const QUALQUER_CONTROLE := -1


func _enter_tree() -> void:
	configurar()


static func configurar() -> void:
	_acao_movimento("mover_esquerda", [KEY_LEFT, KEY_A], JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT)
	_acao_movimento("mover_direita", [KEY_RIGHT, KEY_D], JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT)
	_acao_movimento("mover_cima", [KEY_UP, KEY_W], JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP)
	_acao_movimento("mover_baixo", [KEY_DOWN, KEY_S], JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN)

	_recriar("acao", 0.5)
	for tecla: Key in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_tecla("acao", tecla)
	for botao: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y,
			JOY_BUTTON_START, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		var ev := InputEventJoypadButton.new()
		ev.device = QUALQUER_CONTROLE
		ev.button_index = botao
		InputMap.action_add_event("acao", ev)

	_recriar("sair", 0.5)
	_tecla("sair", KEY_ESCAPE)


static func _acao_movimento(nome: String, teclas: Array, eixo: JoyAxis, sentido: float, dpad: JoyButton) -> void:
	_recriar(nome, ZONA_MORTA)
	for tecla: Key in teclas:
		_tecla(nome, tecla)
	var analogico := InputEventJoypadMotion.new()
	analogico.device = QUALQUER_CONTROLE
	analogico.axis = eixo
	analogico.axis_value = sentido
	InputMap.action_add_event(nome, analogico)
	var cruz := InputEventJoypadButton.new()
	cruz.device = QUALQUER_CONTROLE
	cruz.button_index = dpad
	InputMap.action_add_event(nome, cruz)


static func _recriar(nome: String, zona: float) -> void:
	if InputMap.has_action(nome):
		InputMap.erase_action(nome)
	InputMap.add_action(nome, zona)


static func _tecla(acao: String, tecla: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = tecla
	InputMap.action_add_event(acao, ev)
