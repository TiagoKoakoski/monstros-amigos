class_name Rolagem
extends RefCounted
## Como os planetinhas rolam: um empurrão (com ajuda na mira pro ninho),
## rolar perdendo força, quicar nos limites (nunca saem deles) e cair no ninho.

const EMPURRAO := 520.0
## px/s² de atrito
const ATRITO := 450.0
const QUIQUE := 0.7
## empurrão até esse tanto torto em relação ao ninho vai reto pro ninho
const MIRA := deg_to_rad(60.0)
## perto assim do ninho da cor dele, o planetinha cai nele
const PUXA := 110.0
## criança perto assim encosta no planetinha
const TOQUE := 95.0
## quanto atrás da bola a criança fica pra empurrar
const ATRAS := 130.0
const DESVIO := 220.0
## a criança anda até esse tanto fora dos limites dos planetinhas
const ALCANCE := 105.0
## só desvia se a criança está claramente do lado do ninho (senão, chegando no
## desvio, ela ficaria desviando pra sempre)
const LADO_DO_NINHO := 60.0


## Velocidade depois do empurrão: na direção criança→bola, ou reto pro ninho
## se estiver quase lá.
static func empurrao(bola: Vector2, crianca: Vector2, ninho: Vector2) -> Vector2:
	var dir := (bola - crianca).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var pro_ninho := (ninho - bola).normalized()
	if pro_ninho != Vector2.ZERO and absf(dir.angle_to(pro_ninho)) <= MIRA:
		dir = pro_ninho
	return dir * EMPURRAO


## Um quadro: anda, perde força, quica nos limites. Devolve [pos, vel].
static func rolar(pos: Vector2, vel: Vector2, delta: float, limites: Rect2) -> Array:
	var v := vel.length()
	if v <= 0.0:
		return [pos.clamp(limites.position, limites.end), Vector2.ZERO]
	pos += vel * delta
	vel = vel.normalized() * maxf(0.0, v - ATRITO * delta)
	if pos.x < limites.position.x or pos.x > limites.end.x:
		pos.x = clampf(pos.x, limites.position.x, limites.end.x)
		vel.x = -vel.x * QUIQUE
	if pos.y < limites.position.y or pos.y > limites.end.y:
		pos.y = clampf(pos.y, limites.position.y, limites.end.y)
		vel.y = -vel.y * QUIQUE
	return [pos, vel]


static func encaixa(bola: Vector2, ninho: Vector2) -> bool:
	return bola.distance_to(ninho) < PUXA


## Onde a criança deve ficar pra empurrar a bola pro ninho: atrás dela (do
## lado oposto ao ninho). Se a criança está do lado do ninho, perto da bola,
## primeiro dá a volta por um lado (pra não empurrar pro lado errado).
static func ponto_de_empurrar(bola: Vector2, ninho: Vector2, crianca: Vector2, limites: Rect2) -> Vector2:
	var anda := limites.grow(ALCANCE)
	var pro_ninho := (ninho - bola).normalized()
	var de_la := crianca - bola
	if de_la.dot(pro_ninho) > LADO_DO_NINHO and de_la.length() < 260.0:
		var lado := pro_ninho.orthogonal()
		var sinal := 1.0 if lado.dot(de_la) >= 0.0 else -1.0
		var p := (bola + lado * sinal * DESVIO).clamp(anda.position, anda.end)
		if p.distance_to(bola) < 150.0:  # parede desse lado: vai pelo outro
			p = (bola - lado * sinal * DESVIO).clamp(anda.position, anda.end)
		return p
	return (bola - pro_ninho * ATRAS).clamp(anda.position, anda.end)
