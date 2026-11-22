# godot --headless --path . --script res://tests/teste_controle_real.gd
# Manda eventos de controle e teclado pelo caminho de entrada real do Godot
# (não pelo modo automático), no controle 0 e no 1.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	for dev: int in [0, 1]:
		_eixo(dev, JOY_AXIS_LEFT_X, 1.0)
		igual(_vetor().x > 0.9, true, "controle %d: analógico pra direita anda" % dev)
		_eixo(dev, JOY_AXIS_LEFT_X, 0.2)
		igual(_vetor(), Vector2.ZERO, "controle %d: analógico de leve (0,2) fica parado — zona morta" % dev)
		_eixo(dev, JOY_AXIS_LEFT_X, 0.0)
		_eixo(dev, JOY_AXIS_LEFT_Y, -1.0)
		igual(_vetor().y < -0.9, true, "controle %d: analógico pra cima anda" % dev)
		_eixo(dev, JOY_AXIS_LEFT_Y, 0.0)
		_botao(dev, JOY_BUTTON_DPAD_UP, true)
		igual(Input.is_action_pressed("mover_cima"), true, "controle %d: seta de cima do controle" % dev)
		_botao(dev, JOY_BUTTON_DPAD_UP, false)
		for b: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]:
			_botao(dev, b, true)
			igual(Input.is_action_pressed("acao"), true, "controle %d: botão %d faz a ação" % [dev, b])
			_botao(dev, b, false)
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_LEFT
	tecla.pressed = true
	Input.parse_input_event(tecla)
	Input.flush_buffered_events()
	igual(Input.is_action_pressed("mover_esquerda"), true, "teclado: seta esquerda")
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func _vetor() -> Vector2:
	return Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")


func _eixo(dev: int, eixo: JoyAxis, valor: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = dev
	e.axis = eixo
	e.axis_value = valor
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _botao(dev: int, botao: JoyButton, apertado: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = dev
	e.button_index = botao
	e.pressed = apertado
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func igual(atual: Variant, esperado: Variant, rotulo: String) -> void:
	if atual == esperado:
		passou += 1
	else:
		falhou += 1
		print("FALHOU: %s (esperado %s, veio %s)" % [rotulo, esperado, atual])
