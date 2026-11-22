class_name Visual
extends RefCounted
## Texturas e efeitos montados em código, reaproveitados pelas outras peças.

static var _brilho: GradientTexture2D
static var _confete: ImageTexture


## Mancha de luz redonda e macia (vaga-lumes, postes, brilho dos itens).
static func textura_brilho() -> GradientTexture2D:
	if _brilho == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		_brilho = GradientTexture2D.new()
		_brilho.gradient = g
		_brilho.fill = GradientTexture2D.FILL_RADIAL
		_brilho.fill_from = Vector2(0.5, 0.5)
		_brilho.fill_to = Vector2(0.5, 0.0)
		_brilho.width = 128
		_brilho.height = 128
	return _brilho


static func textura_confete() -> ImageTexture:
	if _confete == null:
		var img := Image.create(14, 9, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_confete = ImageTexture.create_from_image(img)
	return _confete


## Luz aditiva: soma brilho sem escurecer nada (nada de canto escuro).
static func luz(cor: Color, tamanho: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura_brilho()
	s.modulate = cor
	s.scale = Vector2.ONE * (tamanho / 128.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	return s


## Sombra oval no chão, embaixo dos pés.
static func sombra(largura: float) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * largura * 0.5, sin(a) * largura * 0.16))
	p.polygon = pts
	p.color = Color(0.08, 0.06, 0.16, 0.35)
	return p


## Sprite com os pés na origem (pra ordenar por altura na tela).
static func sprite_em_pe(textura: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.offset = Vector2(0, -textura.get_height() * 0.5)
	return s


## Explosão de confete colorido, uma vez só.
static func confete(quantidade: int, forca: float) -> CPUParticles2D:
	var c := CPUParticles2D.new()
	c.texture = textura_confete()
	c.amount = quantidade
	c.one_shot = true
	c.explosiveness = 0.95
	c.lifetime = 1.6
	c.direction = Vector2(0, -1)
	c.spread = 75.0
	c.initial_velocity_min = forca * 0.6
	c.initial_velocity_max = forca
	c.gravity = Vector2(0, 700)
	c.angular_velocity_min = -360.0
	c.angular_velocity_max = 360.0
	c.angle_min = 0.0
	c.angle_max = 360.0
	c.scale_amount_min = 0.8
	c.scale_amount_max = 1.4
	c.color_initial_ramp = gradiente_festa()
	c.emitting = false
	c.z_index = 30
	return c


static func gradiente_festa() -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.set_color(0, Color("#ff6f91"))
	g.set_offset(1, 0.2)
	g.set_color(1, Color("#ffd23f"))
	g.add_point(0.4, Color("#4aa3ff"))
	g.add_point(0.6, Color("#5bd17a"))
	g.add_point(0.8, Color("#b07cff"))
	return g
