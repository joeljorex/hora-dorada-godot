class_name Sombras
extends RefCounted
## Matemáticas del sol y de la sombra (GDD §4.9). Coordenadas del mapa: x = este, y = sur (en 3D, y del mapa = z).
## t = hora del día: 0 = amanecer (6:00 a. m.), 1 = anochecer (7:00 p. m.).

const H_JUGADOR := 1.4
const H_ESTIRADO := 1.95
const SOMBRA_MAX := 12.0
const MEDIODIA := Vector2(0.4, 0.6)


## Hacia dónde cae la sombra en la pantalla y qué tan alto está el sol.
static func sol(t: float) -> Dictionary:
	var a := PI * clampf(t, 0.0, 1.0)
	var elev := maxf(0.02, sin(a)) * 1.25
	return {"dir": Vector2(-cos(a), -sin(a)), "elev": elev, "tan_e": tan(elev)}


## La cámara gira en pasos de 90° (k). El sol está fijo respecto a la cámara, así que una dirección
## de la pantalla se convierte en otra dirección del mapa.
static func dir_a_mapa(d: Vector2, k: int) -> Vector2:
	match k & 3:
		1: return Vector2(d.y, -d.x)
		2: return Vector2(-d.x, -d.y)
		3: return Vector2(-d.y, d.x)
	return d


## Lo contrario: una dirección del mapa vista en la pantalla (para orientar sprites).
static func dir_a_vista(d: Vector2, k: int) -> Vector2:
	match k & 3:
		1: return Vector2(-d.y, d.x)
		2: return Vector2(-d.x, -d.y)
		3: return Vector2(d.y, -d.x)
	return d


## Sombra de Gno como segmento: origen, dirección y largo. z = altura de sus pies.
static func segmento(pos: Vector2, z: float, altura: float, t: float, vista: int) -> Dictionary:
	var s := sol(t)
	var d := dir_a_mapa(s["dir"], vista)
	var total := minf(SOMBRA_MAX, (altura + z) / float(s["tan_e"]))
	var inicio := minf(total, z / float(s["tan_e"]))
	return {"origen": pos + d * inicio, "dir": d, "largo": total - inicio, "elev": s["elev"]}


## ¿La sombra cubre el punto p (con radio r)? La sombra es un poco más angosta en la punta (la cabeza).
static func cubre(seg: Dictionary, p: Vector2, r: float) -> bool:
	if seg.is_empty():
		return false
	var q: Vector2 = p - seg["origen"]
	var d: Vector2 = seg["dir"]
	var largo: float = seg["largo"]
	var a := q.dot(d)
	if a < 0.25 or a > largo + 0.2:
		return false
	var perp := absf(q.x * d.y - q.y * d.x)
	var ancho := 0.3 - 0.08 * minf(1.0, a / maxf(largo, 0.001))
	return perp <= ancho + r


static func hora_texto(t: float) -> String:
	var minutos := int(round(6 * 60 + clampf(t, 0.0, 1.0) * 13 * 60))
	var h := minutos / 60
	var m := minutos % 60
	var h12 := ((h + 11) % 12) + 1
	return "%d:%02d %s" % [h12, m, "a.m." if h < 12 else "p.m."]


static func es_mediodia(t: float) -> bool:
	return t >= MEDIODIA.x and t <= MEDIODIA.y
