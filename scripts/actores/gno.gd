class_name Gno
extends CharacterBody3D
## Gno, el espíritu del reloj de sol. Camina, salta y se estira. Su origen está en los pies,
## así que global_position.y es la altura (z del GDD).

const VEL := 3.6
const SALTO := 5.4
const GRAVEDAD := 15.0
const ALTO_SPRITE := 1.4
const COLUMNA := {"abajo": 0, "arriba": 1, "izquierda": 2, "derecha": 3}

var hoja := "flam"
var corazones := 3
var corazones_max := 3
var invuln := 0.0
var estirado := false
var empuje := Vector2.ZERO
var columna := 0           # dirección a la que mira (en pantalla)
var _paso := 0.0
var _en_aire_antes := false
var muerto := false

var sprite: Sprite3D
var _tex := {}


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 0.9
	cs.shape = cap
	cs.position.y = 0.45
	add_child(cs)
	for an in ["walk", "idle", "item", "dead", "jump"]:
		_tex[an] = load("res://assets/sprites/personajes/%s_%s.png" % [hoja, an])
	sprite = Efectos.sprite("res://assets/sprites/personajes/%s_walk.png" % hoja, Rect2(), ALTO_SPRITE / 16.0)
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.position.y = ALTO_SPRITE / 2.0
	# La sombra de Gno la dibuja el nivel (sigue la regla del juego), así que el sprite no proyecta otra.
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)


func altura() -> float:
	return maxf(0.0, global_position.y)


func pos_mapa() -> Vector2:
	return Vector2(global_position.x, global_position.z)


## dir_mapa: hacia dónde caminar en el mapa; dir_pantalla: la misma dirección en pantalla (para el sprite).
func mover(delta: float, dir_mapa: Vector2, dir_pantalla: Vector2, mult_vel: float, saltar: bool, mult_salto: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	if muerto:
		dir_mapa = Vector2.ZERO
	var largo := dir_mapa.length()
	if largo > 1.0:
		dir_mapa /= largo
	if estirado:
		dir_mapa = Vector2.ZERO
	var v := dir_mapa * VEL * mult_vel + empuje
	empuje *= exp(-delta * 8.0)
	if empuje.length() < 0.05:
		empuje = Vector2.ZERO
	velocity.x = v.x
	velocity.z = v.y
	if saltar and is_on_floor() and not estirado and not muerto:
		velocity.y = SALTO * mult_salto
		Eventos.jugador_salto.emit()
	velocity.y -= GRAVEDAD * delta
	move_and_slide()
	if dir_pantalla.length() > 0.1:
		if absf(dir_pantalla.x) > absf(dir_pantalla.y):
			columna = COLUMNA["derecha"] if dir_pantalla.x > 0 else COLUMNA["izquierda"]
		else:
			columna = COLUMNA["abajo"] if dir_pantalla.y > 0 else COLUMNA["arriba"]
	_animar(delta, largo > 0.1 and not estirado)


func _animar(delta: float, caminando: bool) -> void:
	var en_aire := not is_on_floor()
	if muerto:
		_usar("dead", 1, 1)
		sprite.frame = 0
	elif estirado:
		_usar("item", 1, 1)
		sprite.frame = 0
	elif en_aire:
		_usar("jump", 4, 1)
		sprite.frame = columna
	elif caminando:
		_usar("walk", 4, 4)
		_paso += delta * 8.0
		sprite.frame_coords = Vector2i(columna, int(_paso) % 4)
	else:
		_usar("idle", 4, 1)
		sprite.frame = columna
	# Parpadeo mientras es invulnerable
	sprite.visible = invuln <= 0.0 or int(invuln * 12.0) % 2 == 0
	_en_aire_antes = en_aire


func _usar(an: String, h: int, v: int) -> void:
	var t: Texture2D = _tex[an]
	if sprite.texture != t:
		sprite.texture = t
		sprite.hframes = h
		sprite.vframes = v


## Textura y cuadro actuales (la sombra los usa para dibujar la silueta).
func cuadro_actual() -> Dictionary:
	return {"textura": sprite.texture, "hframes": sprite.hframes, "vframes": sprite.vframes, "coords": sprite.frame_coords}


func golpear(desde: Vector3) -> void:
	corazones -= 1
	invuln = 1.3
	var d := Vector2(global_position.x - desde.x, global_position.z - desde.z)
	empuje = d.normalized() * 3.0 if d.length() > 0.01 else Vector2(0, 3)
