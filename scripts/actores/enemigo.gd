class_name Enemigo
extends CharacterBody3D
## Base de los enemigos: cuerpo con colisión contra el mundo, sprite de 4 direcciones × 4 cuadros,
## zona que detecta el choque con Gno y una pequeña máquina de estados que cada tipo completa.

var tipo := "enemigo"
var nivel: Node            # el nivel (da la sombra, el mapa y a Gno)
var vel := 1.5
var dir := Vector2.ZERO    # dirección en el mapa
var estado := ""
var t_estado := 0.0
var apagado := 0.0         # 0..1: cuánto lo ha cubierto la sombra
var muerto := false
var dania := true          # si tocarlo quita un corazón
var mult_vel := 1.0

var sprite: Sprite3D
var zona: Area3D
var _paso := 0.0
var _columna := 0


func configurar(n: Node, hoja: String, alto_sprite := 1.0) -> void:
	nivel = n
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.3
	cs.shape = esfera
	cs.position.y = 0.32
	add_child(cs)
	sprite = Efectos.sprite(hoja, Rect2(), alto_sprite / 16.0)
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.position.y = alto_sprite / 2.0
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(sprite)
	zona = Area3D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2
	zona.monitorable = false
	var cz := CollisionShape3D.new()
	var ez := SphereShape3D.new()
	ez.radius = 0.42
	cz.shape = ez
	cz.position.y = 0.4
	zona.add_child(cz)
	add_child(zona)


func pos_mapa() -> Vector2:
	return Vector2(global_position.x, global_position.z)


func celda() -> Vector2i:
	return Vector2i(int(floor(global_position.x)), int(floor(global_position.z)))


func cambiar(nuevo: String) -> void:
	estado = nuevo
	t_estado = 0.0


## Lo llama el nivel en cada cuadro de física.
func paso(delta: float) -> void:
	if muerto:
		return
	t_estado += delta
	pensar(delta)
	if muerto:   # la sombra lo pudo apagar mientras pensaba
		return
	var v := dir * vel * mult_vel
	velocity = Vector3(v.x, -1.0, v.y)
	move_and_slide()
	_animar(delta)
	# Colisión con Gno (zona de choque de Godot)
	if dania and zona.has_overlapping_bodies():
		nivel.golpear_jugador(self)


## Cada tipo decide aquí hacia dónde moverse.
func pensar(_delta: float) -> void:
	pass


func choco() -> bool:
	for i in get_slide_collision_count():
		var n := get_slide_collision(i).get_normal()
		if absf(n.y) < 0.5:
			return true
	return false


func _animar(delta: float) -> void:
	if dir.length() > 0.05:
		var dp: Vector2 = nivel.mapa_a_pantalla(dir)
		if absf(dp.x) > absf(dp.y):
			_columna = 3 if dp.x > 0 else 2
		else:
			_columna = 0 if dp.y > 0 else 1
		_paso += delta * 7.0 * mult_vel
	sprite.frame_coords = Vector2i(_columna, int(_paso) % 4)


## Lo apaga la sombra o lo vence el jugador.
func apagar() -> void:
	if muerto:
		return
	muerto = true
	collision_layer = 0
	zona.monitoring = false
	Eventos.enemigo_apagado.emit(tipo, global_position)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tw.tween_property(sprite, "scale", Vector3(1.4, 0.2, 1.0), 0.5)
	tw.chain().tween_callback(func(): visible = false)


## Dirección cardinal libre al azar (para deambular).
func dir_libre_al_azar() -> Vector2:
	var opciones: Array = []
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var c := celda() + Vector2i(int(d.x), int(d.y))
		if not nivel.mundo.es_solido(c):
			opciones.append(d)
	if opciones.is_empty():
		return Vector2.ZERO
	return opciones[randi() % opciones.size()]


## Sigue un camino de A* hacia una casilla.
func seguir_camino(destino: Vector2i) -> void:
	var ruta: Array = nivel.mundo.camino(celda(), destino)
	if ruta.size() >= 2:
		var siguiente: Vector2i = ruta[1]
		var objetivo := Vector2(siguiente.x + 0.5, siguiente.y + 0.5)
		dir = (objetivo - pos_mapa()).normalized()
	elif ruta.size() == 1:
		var objetivo2 := Vector2(destino.x + 0.5, destino.y + 0.5)
		var d := objetivo2 - pos_mapa()
		dir = d.normalized() if d.length() > 0.1 else Vector2.ZERO
	else:
		dir = Vector2.ZERO
