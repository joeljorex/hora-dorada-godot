class_name Mundo
extends Node3D
## Arma el desierto en 3D a partir del mapa de texto de un nivel: suelo y muros (mallas hechas con
## SurfaceTool), colisiones, adornos, flores, placas, puertas, salida y objetos que se recogen.
## Cada casilla mide 1 unidad. La casilla (i, j) tiene su centro en (i + 0.5, 0, j + 0.5).

const T_SUELO := "res://assets/sprites/tiles/suelo.png"
const T_RELIEVE := "res://assets/sprites/tiles/relieve.png"
const T_NATURALEZA := "res://assets/sprites/tiles/naturaleza.png"
const T_DESIERTO := "res://assets/sprites/tiles/desierto.png"
const T_MAZMORRA := "res://assets/sprites/tiles/mazmorra.png"
const T_ELEMENTOS := "res://assets/sprites/tiles/elementos.png"
const T_LOGICA := "res://assets/sprites/tiles/logica.png"

const R_ARENA := Rect2(16, 16, 16, 16)
const R_ARENA_VAR := [Rect2(128, 16, 16, 16), Rect2(80, 64, 16, 16), Rect2(96, 64, 16, 16), Rect2(128, 32, 16, 16),
	Rect2(144, 32, 16, 16), Rect2(160, 32, 16, 16), Rect2(144, 48, 16, 16), Rect2(160, 48, 16, 16)]
const R_CAMINO := Rect2(0, 80, 16, 16)
const R_MURO_ARRIBA := Rect2(32, 96, 16, 16)
const R_MURO_CARA := Rect2(80, 96, 16, 16)
const R_PLACA := Rect2(0, 16, 16, 16)
const R_PLACA_ACTIVA := Rect2(16, 16, 16, 16)
const R_PEDESTAL := Rect2(80, 32, 16, 16)
const R_PEDESTAL_ACTIVO := Rect2(32, 32, 16, 16)
const R_REJA := Rect2(80, 176, 16, 16)
const R_BOTON_FLOR := Rect2(16, 160, 16, 16)
const R_LETRA := {"A": Rect2(0, 96, 16, 16), "B": Rect2(64, 112, 16, 16)}

const ALTO_MURO := 1.0
const TINTE_ADOBE := Color("e9a57c")

## Obstáculos que se dibujan con sprite: hoja, recorte, sólido, radio
const PROPS := {
	"c": [T_NATURALEZA, Rect2(176, 128, 16, 32), true, 0.32],
	"b": [T_NATURALEZA, Rect2(160, 128, 16, 16), true, 0.35],
	"g": [T_NATURALEZA, Rect2(128, 160, 16, 16), true, 0.35],
	"r": [T_NATURALEZA, Rect2(272, 208, 16, 16), true, 0.38],
	"k": [T_DESIERTO, Rect2(256, 176, 16, 16), false, 0.0],
}

var filas: Array = []
var ancho := 0
var alto := 0
var solidos := {}            # Vector2i -> true (muros, plantas, rocas, flores)
var inicio := Vector2i.ZERO
var salida := {}             # {celda, sprite, circulo, area, activa}
var flores: Array = []       # {celda, pos, sprite, p, abierta}
var placas: Array = []       # {celda, pos, letra, mesh, activa}
var puertas: Array = []      # {celda, letra, nodo, cuerpo, abierta}
var objetos: Array = []      # {tipo, celda, nodo, area}
var enemigos_def: Array = [] # {tipo, celda, eje}
var rodadoras: Array = []
var astar := AStarGrid2D.new()

var _cuerpo: StaticBody3D
var _azar := RandomNumberGenerator.new()


func construir(def: Dictionary, semilla := 0) -> void:
	_azar.seed = semilla if semilla != 0 else hash(def["nombre"])
	filas = Niveles.mapa_con_borde(def)
	alto = filas.size()
	ancho = String(filas[0]).length()
	_cuerpo = StaticBody3D.new()
	_cuerpo.name = "Solidos"
	_cuerpo.collision_layer = 1
	_cuerpo.collision_mask = 0
	add_child(_cuerpo)
	_suelo_infinito()
	_construir_suelo()
	_construir_muros()
	for j in alto:
		for i in ancho:
			_colocar(String(filas[j])[i], Vector2i(i, j))
	_preparar_astar()


func celda_de(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x)), int(floor(p.z)))


static func centro(c: Vector2i, y := 0.0) -> Vector3:
	return Vector3(c.x + 0.5, y, c.y + 0.5)


func caracter(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= ancho or c.y >= alto:
		return "#"
	return String(filas[c.y])[c.x]


func es_solido(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= ancho or c.y >= alto:
		return true
	if solidos.has(c):
		return true
	for p in puertas:
		if p["celda"] == c and not p["abierta"]:
			return true
	return false


func celdas_libres() -> Array:
	var r: Array = []
	for j in range(1, alto - 1):
		for i in range(1, ancho - 1):
			var c := Vector2i(i, j)
			var ch := caracter(c)
			if (ch == "." or ch == "p") and not es_solido(c):
				r.append(c)
	return r


# ---------------- Suelo ----------------

func _suelo_infinito() -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(160, 160)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("d9b27c")
	m.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = plano
	mi.material_override = m
	mi.position = Vector3(ancho / 2.0, -0.02, alto / 2.0)
	add_child(mi)
	# El suelo físico: un plano infinito en y = 0
	var cs := CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	_cuerpo.add_child(cs)


func _uv(region: Rect2, tam: Vector2) -> Array:
	var a := region.position / tam
	var b := (region.position + region.size) / tam
	return [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(b.x, b.y), Vector2(a.x, b.y)]


## Agrega un cuadro con 4 esquinas (en orden) y su recorte del atlas.
func _quad(st: SurfaceTool, v: Array, uv: Array, n: Vector3) -> void:
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[k])
		st.add_vertex(v[k])


func _construir_suelo() -> void:
	var tex: Texture2D = load(T_SUELO)
	var tam := Vector2(tex.get_width(), tex.get_height())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in alto:
		for i in ancho:
			var ch := String(filas[j])[i]
			var region: Rect2 = R_ARENA
			if ch == "p":
				region = R_CAMINO
			elif _azar.randf() < 0.18:
				region = R_ARENA_VAR[_azar.randi() % R_ARENA_VAR.size()]
			var v := [Vector3(i, 0, j), Vector3(i + 1, 0, j), Vector3(i + 1, 0, j + 1), Vector3(i, 0, j + 1)]
			_quad(st, v, _uv(region, tam), Vector3.UP)
	var mi := MeshInstance3D.new()
	mi.name = "Suelo"
	mi.mesh = st.commit()
	mi.material_override = Efectos.material_atlas(T_SUELO)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _es_muro(i: int, j: int) -> bool:
	if i < 0 or j < 0 or i >= ancho or j >= alto:
		return false
	return String(filas[j])[i] == "#"


func _construir_muros() -> void:
	var tex: Texture2D = load(T_RELIEVE)
	var tam := Vector2(tex.get_width(), tex.get_height())
	var uv_arriba := _uv(R_MURO_ARRIBA, tam)
	var uv_cara := _uv(R_MURO_CARA, tam)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := ALTO_MURO
	for j in alto:
		for i in ancho:
			if not _es_muro(i, j):
				continue
			solidos[Vector2i(i, j)] = true
			_quad(st, [Vector3(i, h, j), Vector3(i + 1, h, j), Vector3(i + 1, h, j + 1), Vector3(i, h, j + 1)], uv_arriba, Vector3.UP)
			if not _es_muro(i, j + 1):   # cara sur
				_quad(st, [Vector3(i, h, j + 1), Vector3(i + 1, h, j + 1), Vector3(i + 1, 0, j + 1), Vector3(i, 0, j + 1)], uv_cara, Vector3.BACK)
			if not _es_muro(i, j - 1):   # cara norte
				_quad(st, [Vector3(i + 1, h, j), Vector3(i, h, j), Vector3(i, 0, j), Vector3(i + 1, 0, j)], uv_cara, Vector3.FORWARD)
			if not _es_muro(i + 1, j):   # cara este
				_quad(st, [Vector3(i + 1, h, j + 1), Vector3(i + 1, h, j), Vector3(i + 1, 0, j), Vector3(i + 1, 0, j + 1)], uv_cara, Vector3.RIGHT)
			if not _es_muro(i - 1, j):   # cara oeste
				_quad(st, [Vector3(i, h, j), Vector3(i, h, j + 1), Vector3(i, 0, j + 1), Vector3(i, 0, j)], uv_cara, Vector3.LEFT)
			var cs := CollisionShape3D.new()
			var caja := BoxShape3D.new()
			caja.size = Vector3(1, 2.5, 1)
			cs.shape = caja
			cs.position = Vector3(i + 0.5, 1.25, j + 0.5)
			_cuerpo.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "Muros"
	mi.mesh = st.commit()
	mi.material_override = Efectos.material_atlas(T_RELIEVE, TINTE_ADOBE)
	add_child(mi)


func _colision_cilindro(c: Vector2i, radio: float) -> void:
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = radio
	cil.height = 2.5
	cs.shape = cil
	cs.position = centro(c, 1.25)
	_cuerpo.add_child(cs)


# ---------------- Objetos del mapa ----------------

func _colocar(ch: String, c: Vector2i) -> void:
	var pos := centro(c)
	if PROPS.has(ch):
		var d: Array = PROPS[ch]
		var s := Efectos.sprite(d[0], d[1])
		Efectos.apoyar(s)
		s.position += pos
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(s)
		if d[2]:
			solidos[c] = true
			_colision_cilindro(c, d[3])
		return
	match ch:
		"P":
			inicio = c
		"X":
			var s := Efectos.sprite(T_MAZMORRA, R_PEDESTAL)
			Efectos.apoyar(s)
			s.position += pos
			add_child(s)
			var circulo := Efectos.sprite("res://assets/sprites/fx/circulo.png", Rect2(), 1.0 / 20.0, BaseMaterial3D.BILLBOARD_DISABLED)
			circulo.hframes = 4
			circulo.rotation_degrees.x = -90
			circulo.position = pos + Vector3(0, 0.03, 0)
			circulo.visible = false
			add_child(circulo)
			salida = {"celda": c, "sprite": s, "circulo": circulo, "area": _area(pos, 0.45), "activa": false}
		"F":
			var s := Efectos.sprite(T_NATURALEZA, R_BOTON_FLOR)
			s.modulate = Color(0.78, 0.6, 1.0)
			Efectos.apoyar(s)
			s.position += pos
			add_child(s)
			solidos[c] = true
			_colision_cilindro(c, 0.3)
			flores.append({"celda": c, "pos": Vector2(pos.x, pos.z), "sprite": s, "p": 0.0, "abierta": false, "t_anim": 0.0})
		"a", "q":
			var letra := "A" if ch == "a" else "B"
			var m := Efectos.calcomania(T_MAZMORRA, R_PLACA, 0.95)
			m.position += pos
			add_child(m)
			var icono := Efectos.sprite(T_LOGICA, R_LETRA[letra], 1.0 / 32.0)
			icono.position = pos + Vector3(0, 0.35, 0)
			add_child(icono)
			placas.append({"celda": c, "pos": Vector2(pos.x, pos.z), "letra": letra, "mesh": m, "activa": false})
		"A", "B":
			var nodo := Node3D.new()
			nodo.position = pos
			add_child(nodo)
			var reja := Efectos.sprite(T_ELEMENTOS, R_REJA)
			Efectos.apoyar(reja)
			reja.scale = Vector3(1.0, 1.4, 1.0)
			reja.position.y *= 1.4
			reja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			nodo.add_child(reja)
			var letra_s := Efectos.sprite(T_LOGICA, R_LETRA[ch], 1.0 / 28.0)
			letra_s.position.y = 1.65
			nodo.add_child(letra_s)
			var cuerpo := StaticBody3D.new()
			cuerpo.collision_layer = 1
			var cs := CollisionShape3D.new()
			var caja := BoxShape3D.new()
			caja.size = Vector3(1, 2.5, 1)
			cs.shape = caja
			cs.position.y = 1.25
			cuerpo.add_child(cs)
			nodo.add_child(cuerpo)
			puertas.append({"celda": c, "letra": ch, "nodo": nodo, "reja": reja, "cuerpo": cuerpo, "forma": cs, "abierta": false})
		"$":
			_objeto("moneda", c)
		"C":
			_objeto("cofre", c)
		"h":
			_objeto("reloj", c)
		"u":
			var s := Efectos.sprite(T_DESIERTO, Rect2(128, 144, 16, 16), 1.0 / 20.0, BaseMaterial3D.BILLBOARD_ENABLED)
			s.position = pos + Vector3(0, 0.4, 0)
			add_child(s)
			rodadoras.append({"nodo": s, "vel": 1.2 + _azar.randf() * 0.8})
		"d", "v":
			enemigos_def.append({"tipo": "destello", "celda": c, "eje": "h" if ch == "d" else "v"})
		"s":
			enemigos_def.append({"tipo": "serpiente", "celda": c})
		"z":
			enemigos_def.append({"tipo": "lagartija", "celda": c})


## Zona de colisión que detecta a Gno (capa 2).
func _area(pos: Vector3, radio: float) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.monitorable = false
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = radio
	cs.shape = esfera
	cs.position.y = 0.5
	a.add_child(cs)
	a.position = pos
	add_child(a)
	return a


## Moneda, cofre, reloj de arena o ventaja.
func _objeto(tipo: String, c: Vector2i, ventaja := "") -> Dictionary:
	var pos := centro(c)
	var s: Sprite3D
	match tipo:
		"moneda":
			s = Efectos.sprite("res://assets/sprites/objetos/monedas_giro.png", Rect2(), 1.0 / 22.0)
			s.hframes = 4
		"cofre":
			s = Efectos.sprite("res://assets/sprites/objetos/cofre.png", Rect2(), 1.0 / 18.0)
			s.hframes = 2
		"reloj":
			s = Efectos.sprite("res://assets/sprites/objetos/reloj_arena.png", Rect2(), 1.0 / 22.0)
		"ventaja":
			s = Efectos.sprite("res://assets/sprites/ventajas/%s.png" % ventaja, Rect2(), 1.0 / 18.0)
	s.position = pos + Vector3(0, 0.45, 0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	var o := {"tipo": tipo, "celda": c, "nodo": s, "area": _area(pos, 0.45), "ventaja": ventaja, "tomado": false,
			  "fase": _azar.randf() * TAU}
	objetos.append(o)
	return o


func agregar_objeto(tipo: String, c: Vector2i, ventaja := "") -> Dictionary:
	return _objeto(tipo, c, ventaja)


func _preparar_astar() -> void:
	astar.region = Rect2i(0, 0, ancho, alto)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	actualizar_astar()


func actualizar_astar() -> void:
	for j in alto:
		for i in ancho:
			astar.set_point_solid(Vector2i(i, j), es_solido(Vector2i(i, j)))


func camino(desde: Vector2i, hasta: Vector2i) -> Array:
	if not astar.is_in_boundsv(desde) or not astar.is_in_boundsv(hasta):
		return []
	return astar.get_id_path(desde, hasta, true)


## ¿Hay línea recta libre entre dos casillas de la misma fila o columna?
func linea_libre(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x and a.y != b.y:
		return false
	var paso := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var c := a + paso
	while c != b:
		if es_solido(c):
			return false
		c += paso
	return true
