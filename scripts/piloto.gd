class_name Piloto
extends RefCounted
## Piloto automático del modo DEMO ("animatronic"): el juego se juega solo para mostrar cómo funciona.
## Para cada flor calcula en qué casilla pararse para que su sombra la toque, llega con A* y espera
## a que abra. Al final camina al reloj de sol.

var nivel: Node
var objetivo := Vector2i(-1, -1)
var flor_actual := -1
var espera := 0.0
var _ruta: Array = []
var _t_ruta := 0.0


func _init(n: Node) -> void:
	nivel = n


## Devuelve la dirección en el mapa hacia donde moverse este cuadro.
func decidir(delta: float) -> Vector2:
	var mundo: Mundo = nivel.mundo
	var gno: Gno = nivel.gno
	var aqui := Vector2i(int(floor(gno.global_position.x)), int(floor(gno.global_position.z)))
	if nivel.todas_abiertas and not mundo.salida.is_empty():
		objetivo = mundo.salida["celda"]
	else:
		if flor_actual < 0 or mundo.flores[flor_actual]["abierta"]:
			flor_actual = _flor_mas_cercana(gno.pos_mapa())
			objetivo = Vector2i(-1, -1)
		if flor_actual < 0:
			return Vector2.ZERO
		_t_ruta -= delta
		if objetivo.x < 0 or _t_ruta <= 0.0:
			objetivo = _lugar_para_sombra(mundo.flores[flor_actual]["pos"])
			_t_ruta = 1.5
	if objetivo.x < 0:
		return Vector2.ZERO
	var destino := Vector2(objetivo.x + 0.5, objetivo.y + 0.5)
	if aqui == objetivo and gno.pos_mapa().distance_to(destino) < 0.2:
		return Vector2.ZERO
	_ruta = mundo.camino(aqui, objetivo)
	if _ruta.size() >= 2:
		var sig: Vector2i = _ruta[1]
		return (Vector2(sig.x + 0.5, sig.y + 0.5) - gno.pos_mapa()).normalized()
	return (destino - gno.pos_mapa()).normalized()


func _flor_mas_cercana(p: Vector2) -> int:
	var mejor := -1
	var dist := INF
	for i in nivel.mundo.flores.size():
		var f: Dictionary = nivel.mundo.flores[i]
		if f["abierta"]:
			continue
		var d := p.distance_to(f["pos"])
		if d < dist:
			dist = d
			mejor = i
	return mejor


## Casilla libre más cercana al punto ideal: la flor menos 70 % del largo de la sombra.
func _lugar_para_sombra(flor: Vector2) -> Vector2i:
	var seg := Sombras.segmento(Vector2.ZERO, 0.0, Sombras.H_JUGADOR, nivel.t, nivel.vista)
	var ideal: Vector2 = flor - seg["dir"] * clampf(float(seg["largo"]) * 0.7, 0.9, 6.0)
	var mejor := Vector2i(-1, -1)
	var dist := INF
	for c in nivel.mundo.celdas_libres():
		var centro := Vector2(c.x + 0.5, c.y + 0.5)
		var prueba := Sombras.segmento(centro, 0.0, Sombras.H_JUGADOR, nivel.t, nivel.vista)
		if not Sombras.cubre(prueba, flor, 0.38):
			continue
		var d := centro.distance_to(ideal)
		if d < dist:
			dist = d
			mejor = c
	return mejor
