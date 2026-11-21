extends Node3D
## Un nivel de Hora Dorada. Arma el mundo, a Gno y a los enemigos; mueve el sol, la cámara y la sombra;
## aplica las reglas (flores, placas, puertas, ventajas, eventos, retos, puntaje, corazones e intentos)
## y avisa todo por el bus de Eventos.

const RITMO_RELOJ := 0.22                  # cuánto día se mueve por segundo con Q/E
const PITCH_NORMAL := 52.0
const PITCH_ALTA := 74.0
const DIST_NORMAL := 21.5
const DIST_ALTA := 22.0
const DUR_VENTAJAS := {"sombraLarga": 15.0, "prisa": 12.0, "solQuieto": 12.0, "saltoAlto": 15.0, "escudo": 10.0,
	"doblePuntos": 20.0, "florRapida": 15.0}
const TIPOS_VENTAJA := ["sombraLarga", "prisa", "solQuieto", "saltoAlto", "escudo", "corazon", "doblePuntos", "florRapida"]

var indice := 0
var def: Dictionary
var mundo: Mundo
var gno: Gno
var hud: Hud
var piloto: Piloto
var enemigos: Array = []

var camara_pivote: Node3D
var camara: Camera3D
var sol_luz: DirectionalLight3D
var cielo: ProceduralSkyMaterial
var entorno: Environment
var sombra_pivote: Node3D
var sombra_mesh: MeshInstance3D
var sombra_mat: StandardMaterial3D
var nubes: Array = []

var t := 0.0
var vista := 0
var camara_alta := false
var _yaw := 0.0
var arena := 0.0
var arena_max := 0.0
var ritmo_dia := 1.0
var estado := "intro"
var tiempo := 0.0
var t_intro := 0.0
var puntos_base := 0
var monedas_nivel := 0
var golpes := 0
var ventajas_tomadas := 0
var enemigos_apagados := 0
var efectos := {}
var evento := ""
var reto := ""
var _reto_avisado := false
var mult_puntos := 1.0
var mult_enemigos := 1.0
var todas_abiertas := false
var seg_sombra := {}
var bajo_nube_gno := false
var _aviso_arena := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	indice = 0 if Juego.demo else clampi(Juego.nivel_actual(), 0, Niveles.cantidad() - 1)
	def = Niveles.obtener(indice)
	mundo = Mundo.new()
	mundo.name = "Mundo"
	add_child(mundo)
	mundo.construir(def)
	_crear_luz_y_cielo()
	_crear_camara()
	_crear_gno()
	_crear_sombra()
	_crear_enemigos()
	t = float(def["t0"])
	arena_max = float(def["tiempo"])
	_elegir_evento_y_reto()
	_colocar_ventajas(4 if evento == "lluvia" else 2)
	_usar_consumibles()
	arena = arena_max
	for o in mundo.objetos:
		o["area"].body_entered.connect(_on_objeto.bind(o))
	Eventos.enemigo_apagado.connect(_on_enemigo_apagado)
	hud = Hud.new()
	add_child(hud)
	hud.configurar(self)
	hud.mostrar_demo(Juego.demo)
	hud.mostrar_pista(String(def["pista"]))
	if Juego.demo:
		piloto = Piloto.new(self)
	elif String(def["voz"]) != "":
		Sonido.voz(String(def["voz"]))
	Sonido.musica(String(def["musica"]))
	_actualizar_sol()
	Eventos.nivel_iniciado.emit(indice)


# ---------------- Construcción ----------------

func _crear_luz_y_cielo() -> void:
	entorno = Environment.new()
	entorno.background_mode = Environment.BG_SKY
	cielo = ProceduralSkyMaterial.new()
	cielo.sun_angle_max = 20.0
	cielo.ground_bottom_color = Color("b48a5a")
	cielo.ground_horizon_color = Color("e5c89a")
	var sky := Sky.new()
	sky.sky_material = cielo
	entorno.sky = sky
	# Luz ambiental de un color fijo (la del cielo aclaraba demasiado la arena)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(1.0, 0.9, 0.82)
	entorno.ambient_light_energy = 0.4
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	entorno.tonemap_white = 1.6
	var we := WorldEnvironment.new()
	we.environment = entorno
	add_child(we)
	sol_luz = DirectionalLight3D.new()
	sol_luz.shadow_enabled = true
	sol_luz.shadow_blur = 0.6
	sol_luz.directional_shadow_max_distance = 70.0
	sol_luz.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sol_luz)


func _crear_camara() -> void:
	camara_pivote = Node3D.new()
	camara_pivote.position = Vector3(mundo.ancho / 2.0, 0, mundo.alto / 2.0 + 0.6)
	add_child(camara_pivote)
	camara = Camera3D.new()
	camara.fov = 42.0
	camara_pivote.add_child(camara)
	_poner_camara(PITCH_NORMAL, DIST_NORMAL)
	camara.current = true


func _poner_camara(pitch: float, dist: float) -> void:
	var p := deg_to_rad(pitch)
	camara.position = Vector3(0, sin(p) * dist, cos(p) * dist)
	camara.rotation = Vector3(-p, 0, 0)


func _crear_gno() -> void:
	gno = Gno.new()
	gno.hoja = "flam" if Juego.demo else Juego.hoja_disfraz()
	gno.name = "Gno"
	add_child(gno)
	gno.global_position = Mundo.centro(mundo.inicio)


func _crear_sombra() -> void:
	sombra_pivote = Node3D.new()
	add_child(sombra_pivote)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.orientation = PlaneMesh.FACE_Y
	sombra_mesh = MeshInstance3D.new()
	sombra_mesh.mesh = q
	sombra_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sombra_mat = StandardMaterial3D.new()
	sombra_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sombra_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sombra_mat.albedo_color = Color(0.08, 0.03, 0.16, 0.6)
	sombra_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sombra_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sombra_mat.render_priority = -1
	sombra_mesh.material_override = sombra_mat
	sombra_pivote.add_child(sombra_mesh)


func _crear_enemigos() -> void:
	for e in mundo.enemigos_def:
		var en: Enemigo
		match String(e["tipo"]):
			"destello":
				en = Destello.new()
			"serpiente":
				en = Serpiente.new()
			"lagartija":
				en = Lagartija.new()
		en.name = "%s_%d" % [e["tipo"], enemigos.size()]
		add_child(en)
		en.global_position = Mundo.centro(e["celda"])
		if en is Destello:
			(en as Destello).iniciar(self, e["eje"])
		elif en is Serpiente:
			(en as Serpiente).iniciar(self)
		elif en is Lagartija:
			(en as Lagartija).iniciar(self)
		enemigos.append(en)


func _elegir_evento_y_reto() -> void:
	if Juego.demo or indice == 0:
		evento = ""
	else:
		var posibles := ["brisa", "dia_veloz", "lluvia", "tesoro"]
		if not mundo.enemigos_def.is_empty():
			posibles.append("inquietos")
		evento = posibles[_rng.randi() % posibles.size()]
	match evento:
		"brisa":
			for k in 2:
				_crear_nube(3.0 + k * 6.0 + _rng.randf() * 2.0, 2.4 + _rng.randf() * 0.8, 1.6, 0.9 + _rng.randf() * 0.5, k * 13.0)
		"dia_veloz":
			ritmo_dia = 1.6
			mult_puntos = 1.5
		"tesoro":
			var libres := _libres_lejos_de_inicio()
			for k in 4:
				if libres.is_empty():
					break
				mundo.agregar_objeto("moneda" if k < 3 else "reloj", libres.pop_back())
		"inquietos":
			mult_enemigos = 1.4
	var retos := ["sin_golpes", "ventajas2", "arena", "rapido"]
	if not mundo.enemigos_def.is_empty():
		retos.append("enemigos")
	reto = "" if Juego.demo else retos[_rng.randi() % retos.size()]


func _libres_lejos_de_inicio() -> Array:
	var libres: Array = []
	for c in mundo.celdas_libres():
		var ocupada := false
		for o in mundo.objetos:
			if o["celda"] == c:
				ocupada = true
		if not ocupada and Vector2(c).distance_to(Vector2(mundo.inicio)) > 2.5 and c != mundo.salida.get("celda", Vector2i(-1, -1)):
			libres.append(c)
	# Mezcla con el generador del nivel
	for i in range(libres.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = libres[i]
		libres[i] = libres[j]
		libres[j] = tmp
	return libres


func _colocar_ventajas(n: int) -> void:
	var libres := _libres_lejos_de_inicio()
	for k in n:
		if libres.is_empty():
			return
		var tipo: String = TIPOS_VENTAJA[_rng.randi() % TIPOS_VENTAJA.size()]
		mundo.agregar_objeto("ventaja", libres.pop_back(), tipo)


func _usar_consumibles() -> void:
	var usados := Juego.usar_consumibles()
	for id in usados:
		match String(id):
			"corazon_extra":
				gno.corazones_max = 4
				gno.corazones = 4
			"arena_extra":
				arena_max += 30.0
			"escudo_inicial":
				efectos["escudo"] = 10.0
			"sombra_inicial":
				efectos["sombraLarga"] = 15.0
	if not usados.is_empty():
		var nombres: Array = []
		for id in usados:
			nombres.append(Juego.CATALOGO[id]["nombre"])
		call_deferred("_avisar", "Usaste: " + ", ".join(nombres), Tema.VERDE)


func _avisar(texto: String, color: Color) -> void:
	if hud:
		hud.aviso(texto, color, 2.5)


func _crear_nube(fila: float, ancho: float, alto: float, vel: float, x0: float) -> void:
	var s := Efectos.sprite("res://assets/sprites/objetos/nube.png", Rect2(), ancho * 2.0 / 80.0, BaseMaterial3D.BILLBOARD_ENABLED)
	s.modulate = Color(1, 1, 1, 0.9)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(s)
	var sombra := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.orientation = PlaneMesh.FACE_Y
	q.size = Vector2(ancho * 2.0, alto * 2.0)
	sombra.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.05, 0.05, 0.12, 0.38))
	grad.set_color(1, Color(0.05, 0.05, 0.12, 0.0))
	g.gradient = grad
	m.albedo_texture = g
	sombra.material_override = m
	sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sombra)
	nubes.append({"nodo": s, "sombra": sombra, "fila": fila, "ancho": ancho, "alto": alto, "vel": vel, "x0": x0, "x": 0.0})


# ---------------- Bucle del juego ----------------

func _physics_process(delta: float) -> void:
	_mover_nubes_y_adornos(delta)
	if estado == "intro":
		t_intro += delta
		gno.mover(delta, Vector2.ZERO, Vector2.ZERO, 1.0, false, 1.0)
		if t_intro > (1.5 if Juego.demo else 5.0):
			_empezar()
		_actualizar_sombra()
		return
	if estado != "jugando":
		gno.mover(delta, Vector2.ZERO, Vector2.ZERO, 1.0, false, 1.0)
		return
	tiempo += delta
	_actualizar_tiempo(delta)
	if estado != "jugando":
		return
	_mover_gno(delta)
	_actualizar_sombra()
	_actualizar_flores(delta)
	_actualizar_placas_y_puertas()
	for e in enemigos:
		(e as Enemigo).paso(delta)
	_actualizar_objetos(delta)
	_actualizar_efectos(delta)
	_revisar_reto()
	if todas_abiertas and mundo.salida["area"].has_overlapping_bodies():
		_ganar()


func _process(delta: float) -> void:
	_actualizar_sol()
	if mundo.salida.has("circulo") and mundo.salida["circulo"].visible:
		mundo.salida["circulo"].frame = int(Time.get_ticks_msec() / 120.0) % 4


func _empezar() -> void:
	if estado != "intro":
		return
	estado = "jugando"
	hud.ocultar_pista()
	if evento != "":
		var ev: Dictionary = Puntaje.EVENTOS[evento]
		Eventos.evento_de_nivel.emit(evento, ev["nombre"], ev["desc"])


func _actualizar_tiempo(delta: float) -> void:
	var quieto := float(efectos.get("solQuieto", 0.0)) > 0.0
	if not quieto:
		t += delta / float(def["dia"]) * ritmo_dia
		if not Juego.demo:
			arena -= delta
	var dir_sol := 0
	if not Juego.demo:
		dir_sol = int(Input.is_action_pressed("sol_adelante")) - int(Input.is_action_pressed("sol_atras"))
	if dir_sol != 0 and arena > 0.0:
		t += dir_sol * RITMO_RELOJ * delta
		arena -= delta * 2.0
	arena = maxf(0.0, arena)
	t = maxf(0.0, t)
	if Juego.demo:
		t = fmod(t, 0.97)
	if not _aviso_arena and arena < 10.0 and not Juego.demo:
		_aviso_arena = true
		Eventos.aviso_arena.emit()
	if arena <= 0.0 and not Juego.demo:
		perder("¡Se acabó la arena del reloj!")
	elif t >= 1.0:
		t = 1.0
		perder("Se hizo de noche antes de abrir todas las flores.")


func _mover_gno(delta: float) -> void:
	var pantalla := Vector2.ZERO
	var mapa := Vector2.ZERO
	var saltar := false
	if Juego.demo:
		mapa = piloto.decidir(delta)
		pantalla = mapa_a_pantalla(mapa)
		gno.estirado = false
	else:
		pantalla = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
		mapa = Sombras.dir_a_mapa(pantalla, vista)
		gno.estirado = Input.is_action_pressed("estirar") and gno.is_on_floor()
		saltar = Input.is_action_just_pressed("saltar")
	var mult_vel := 1.5 if float(efectos.get("prisa", 0.0)) > 0.0 else 1.0
	var mult_salto := 1.25 if float(efectos.get("saltoAlto", 0.0)) > 0.0 else 1.0
	gno.mover(delta, mapa, pantalla, mult_vel, saltar, mult_salto)


func mapa_a_pantalla(d: Vector2) -> Vector2:
	return Sombras.dir_a_vista(d, vista)


# ---------------- Sombra ----------------

func _actualizar_sombra() -> void:
	bajo_nube_gno = bajo_nube(gno.pos_mapa())
	if bajo_nube_gno or t <= 0.0 or t >= 1.0:
		seg_sombra = {}
		sombra_pivote.visible = false
		return
	var h := Sombras.H_ESTIRADO if gno.estirado else Sombras.H_JUGADOR
	if float(efectos.get("sombraLarga", 0.0)) > 0.0:
		h *= 1.5
	seg_sombra = Sombras.segmento(gno.pos_mapa(), gno.altura(), h, t, vista)
	var d: Vector2 = seg_sombra["dir"]
	var largo: float = seg_sombra["largo"]
	var origen: Vector2 = seg_sombra["origen"]
	sombra_pivote.visible = largo > 0.05
	sombra_pivote.position = Vector3(origen.x, 0.03, origen.y)
	sombra_pivote.rotation = Vector3(0, atan2(-d.x, -d.y), 0)
	sombra_mesh.position = Vector3(0, 0, -largo / 2.0)
	sombra_mesh.scale = Vector3(0.95, 1.0, maxf(largo, 0.05))
	var c := gno.cuadro_actual()
	sombra_mat.albedo_texture = c["textura"]
	sombra_mat.uv1_scale = Vector3(1.0 / c["hframes"], 1.0 / c["vframes"], 1)
	var coords: Vector2i = c["coords"]
	sombra_mat.uv1_offset = Vector3(float(coords.x) / c["hframes"], float(coords.y) / c["vframes"], 0)


## ¿La sombra de Gno cubre este punto del mapa? (la usan flores, placas y enemigos)
func sombra_cubre(p: Vector2, r: float) -> bool:
	return Sombras.cubre(seg_sombra, p, r)


func bajo_nube(p: Vector2) -> bool:
	for n in nubes:
		var dx: float = (p.x - n["x"]) / n["ancho"]
		var dy: float = (p.y - n["fila"]) / n["alto"]
		if dx * dx + dy * dy <= 1.0:
			return true
	return false


func _actualizar_sol() -> void:
	var s := Sombras.sol(t)
	var d := Sombras.dir_a_mapa(s["dir"], vista)
	var e: float = s["elev"]
	var luz := Vector3(d.x * cos(e), -sin(e), d.y * cos(e)).normalized()
	sol_luz.global_transform.basis = Basis.looking_at(luz, Vector3.UP)
	var alto_sol := sin(PI * clampf(t, 0.0, 1.0))
	sol_luz.light_energy = 0.62 + 0.1 * (1.0 - alto_sol)
	sol_luz.light_color = Color(1.0, 0.62, 0.42).lerp(Color(1.0, 0.97, 0.9), sqrt(alto_sol))
	cielo.sky_top_color = Color(0.36, 0.38, 0.66).lerp(Color(0.25, 0.5, 0.92), alto_sol)
	cielo.sky_horizon_color = Color(1.0, 0.6, 0.45).lerp(Color(0.78, 0.86, 0.95), alto_sol)
	entorno.ambient_light_energy = 0.45 - 0.12 * alto_sol


# ---------------- Reglas ----------------

func _actualizar_flores(delta: float) -> void:
	var abiertas := 0
	for f in mundo.flores:
		var s: Sprite3D = f["sprite"]
		if f["abierta"]:
			abiertas += 1
			f["t_anim"] += delta
			s.frame = int(f["t_anim"] * 4.0) % 4
			continue
		if sombra_cubre(f["pos"], 0.38):
			f["p"] += delta / 0.8 * (2.0 if float(efectos.get("florRapida", 0.0)) > 0.0 else 1.0)
			Eventos.flor_creciendo.emit(s.global_position)
			if f["p"] >= 1.0:
				_abrir_flor(f)
				abiertas += 1
		else:
			f["p"] = maxf(0.0, f["p"] - delta * 0.6)
		var p: float = f["p"]
		s.scale = Vector3.ONE * (1.0 + p * 0.3)
		s.modulate = Color(0.78, 0.6, 1.0).lerp(Color(1, 1, 1), p)
	if not todas_abiertas and abiertas == mundo.flores.size() and abiertas > 0:
		todas_abiertas = true
		_activar_salida()


func _abrir_flor(f: Dictionary) -> void:
	f["abierta"] = true
	f["p"] = 1.0
	var s: Sprite3D = f["sprite"]
	s.texture = load("res://assets/sprites/objetos/flor.png")
	s.region_enabled = false
	s.hframes = 4
	s.scale = Vector3.ONE
	s.modulate = Color.WHITE
	Efectos.apoyar(s)
	s.position.y = 0.5
	var pos := s.global_position
	Efectos.animacion(self, "res://assets/sprites/fx/chispa_magica.png", 9, pos + Vector3(0, 0.3, 0), 16.0, 1.0 / 26.0)
	sumar("flor", pos)
	Eventos.flor_abierta.emit(pos)


func _activar_salida() -> void:
	if mundo.salida.is_empty():
		return
	mundo.salida["activa"] = true
	var s: Sprite3D = mundo.salida["sprite"]
	s.region_rect = Mundo.R_PEDESTAL_ACTIVO
	mundo.salida["circulo"].visible = true
	Eventos.todas_las_flores.emit()


func _actualizar_placas_y_puertas() -> void:
	var cambio := false
	for p in mundo.placas:
		var activa := sombra_cubre(p["pos"], 0.42)
		if activa != p["activa"]:
			p["activa"] = activa
			Efectos.cambiar_region(p["mesh"], Mundo.R_PLACA_ACTIVA if activa else Mundo.R_PLACA)
			Eventos.placa_cambio.emit(p["letra"], activa)
	var cg := mundo.celda_de(gno.global_position)
	for pu in mundo.puertas:
		var suyas := mundo.placas.filter(func(p): return p["letra"] == pu["letra"])
		var todas := not suyas.is_empty() and suyas.all(func(p): return p["activa"])
		# Si Gno (o un enemigo) está en la puerta, no se cierra encima de él
		var abierta: bool = todas or (pu["abierta"] and _alguien_en(pu["celda"], cg))
		if abierta != pu["abierta"]:
			pu["abierta"] = abierta
			cambio = true
			pu["forma"].set_deferred("disabled", abierta)
			var tw := create_tween()
			tw.tween_property(pu["reja"], "position:y", -1.4 if abierta else 0.7, 0.25)
			Eventos.puerta_cambio.emit(pu["letra"], abierta)
	if cambio:
		mundo.actualizar_astar()


func _alguien_en(celda: Vector2i, cg: Vector2i) -> bool:
	if cg == celda:
		return true
	for e in enemigos:
		if not e.muerto and e.celda() == celda:
			return true
	return false


func _actualizar_objetos(delta: float) -> void:
	var seg := Time.get_ticks_msec() / 1000.0
	for o in mundo.objetos:
		if o["tomado"]:
			continue
		var s: Sprite3D = o["nodo"]
		s.position.y = 0.45 + sin(seg * 3.0 + o["fase"]) * 0.08
		if o["tipo"] == "moneda":
			s.frame = int(seg * 8.0 + o["fase"]) % 4


func _on_objeto(body: Node3D, o: Dictionary) -> void:
	if body != gno or o["tomado"] or estado != "jugando":
		return
	o["tomado"] = true
	o["area"].set_deferred("monitoring", false)
	var s: Sprite3D = o["nodo"]
	var pos := s.global_position
	match String(o["tipo"]):
		"moneda":
			monedas_nivel += 1
			sumar("moneda", pos)
			Eventos.moneda_tomada.emit(1, pos)
		"cofre":
			s.frame = 1
			monedas_nivel += 5
			sumar("cofre", pos)
			Eventos.cofre_abierto.emit(5, pos)
			Efectos.texto(self, "+5 monedas", pos + Vector3(0, 0.6, 0), Tema.DORADO, 40)
		"reloj":
			arena = minf(arena_max + 30.0, arena + 15.0)
			sumar("reloj", pos)
			Eventos.reloj_tomado.emit(15.0)
			Efectos.texto(self, "+15 s", pos + Vector3(0, 0.6, 0), Color("bfe6ff"), 40)
		"ventaja":
			_activar_ventaja(String(o["ventaja"]))
			sumar("ventaja", pos)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE * (1.0 if o["tipo"] == "cofre" else 1.8), 0.3)
	tw.tween_property(s, "modulate:a", 0.0, 0.5).set_delay(0.3 if o["tipo"] == "cofre" else 0.0)


func _activar_ventaja(tipo: String) -> void:
	ventajas_tomadas += 1
	if tipo == "corazon":
		gno.corazones = mini(gno.corazones + 1, 4)
		gno.corazones_max = maxi(gno.corazones_max, gno.corazones)
	else:
		efectos[tipo] = DUR_VENTAJAS.get(tipo, 10.0)
	Eventos.ventaja_tomada.emit(tipo)


func _actualizar_efectos(delta: float) -> void:
	for k in efectos.keys():
		var antes := float(efectos[k])
		efectos[k] = maxf(0.0, antes - delta)
		if antes > 0.0 and efectos[k] <= 0.0:
			Eventos.ventaja_terminada.emit(k)


func _mover_nubes_y_adornos(delta: float) -> void:
	var seg := Time.get_ticks_msec() / 1000.0
	for n in nubes:
		var periodo: float = mundo.ancho + n["ancho"] * 2.0
		n["x"] = fposmod(n["x0"] + n["vel"] * seg, periodo) - n["ancho"]
		n["nodo"].position = Vector3(n["x"], 4.5, n["fila"])
		n["sombra"].position = Vector3(n["x"], 0.04, n["fila"])
	for r in mundo.rodadoras:
		var nodo: Sprite3D = r["nodo"]
		nodo.position.x += r["vel"] * delta
		if nodo.position.x > mundo.ancho - 1.2:
			nodo.position.x = 1.2
		nodo.position.y = 0.35 + absf(sin(nodo.position.x * 2.5)) * 0.25


# ---------------- Puntos, daño, victoria y derrota ----------------

func sumar(motivo: String, pos: Vector3) -> void:
	var p := int(Puntaje.PUNTOS.get(motivo, 0))
	if motivo in ["destello", "serpiente", "lagartija"] and evento == "inquietos":
		p *= 2
	if p > 0 and float(efectos.get("doblePuntos", 0.0)) > 0.0:
		p *= 2
	puntos_base += p
	Eventos.puntos.emit(p, motivo, pos)
	Efectos.texto(self, ("+%d" % p) if p >= 0 else str(p), pos + Vector3(0, 0.9, 0), Tema.DORADO if p >= 0 else Tema.ROJO)


func _on_enemigo_apagado(tipo: String, pos: Vector3) -> void:
	enemigos_apagados += 1
	sumar(tipo, pos)
	Efectos.animacion(self, "res://assets/sprites/fx/humo_circular.png", 10, pos + Vector3(0, 0.4, 0), 18.0, 1.0 / 16.0)


func golpear_jugador(enemigo: Enemigo) -> void:
	if estado != "jugando" or Juego.demo:
		return
	if gno.invuln > 0.0 or float(efectos.get("escudo", 0.0)) > 0.0 or gno.altura() > 0.5:
		return
	gno.golpear(enemigo.global_position)
	golpes += 1
	sumar("golpe", gno.global_position)
	Eventos.jugador_golpeado.emit(gno.corazones)
	if gno.corazones <= 0:
		perder("Te quedaste sin corazones.")


func reto_logrado() -> bool:
	match reto:
		"sin_golpes":
			return golpes == 0
		"ventajas2":
			return ventajas_tomadas >= 2
		"enemigos":
			return enemigos.size() > 0 and enemigos_apagados >= enemigos.size()
		"arena":
			return arena >= arena_max * 0.5
		"rapido":
			return tiempo < 120.0
	return false


func _revisar_reto() -> void:
	if _reto_avisado or reto == "":
		return
	if (reto == "ventajas2" or reto == "enemigos") and reto_logrado():
		_reto_avisado = true
		Eventos.reto_cumplido.emit(Puntaje.RETOS[reto]["nombre"])


func _ganar() -> void:
	if estado != "jugando":
		return
	estado = "ganado"
	gno.estirado = true   # levanta los brazos
	var desglose := Puntaje.calcular_final({
		"base": puntos_base, "corazones": gno.corazones, "arena": arena, "arena_max": arena_max,
		"segundos": tiempo, "reto_ok": reto_logrado(), "reto_bono": Puntaje.RETOS[reto]["bono"] if reto != "" else 0,
		"mult": mult_puntos})
	var total := int(desglose["total"])
	var estrellas := Puntaje.estrellas(total, def["estrellas"])
	var final := indice >= Niveles.cantidad() - 1
	Juego.registrar_victoria(indice, total, estrellas, monedas_nivel)
	var res := {"nivel": indice, "nombre": def["nombre"], "desglose": desglose, "total": total, "estrellas": estrellas,
		"monedas": monedas_nivel, "corazones": gno.corazones, "tiempo": tiempo, "evento": evento,
		"reto_nombre": Puntaje.RETOS[reto]["nombre"] if reto != "" else "—", "reto_ok": reto_logrado(),
		"final": final, "puntaje_partida": Juego.puntaje_partida()}
	if final and not Juego.demo:
		Juego.terminar_partida()
	Eventos.nivel_ganado.emit(res)
	Sonido.voz("gano3" if estrellas == 3 else "gano")
	hud.mostrar_resultado(res)
	if Juego.demo:
		get_tree().create_timer(4.0).timeout.connect(_volver_al_menu)


func perder(motivo: String) -> void:
	if estado == "ganado" or estado == "perdido":
		return
	estado = "perdido"
	gno.muerto = true
	var quedan := Juego.perder_intento()
	var puntaje_final := Juego.puntaje_partida()
	if not quedan:
		Juego.terminar_partida()
	Eventos.nivel_perdido.emit(motivo)
	Sonido.voz("perdio")
	hud.mostrar_derrota(motivo, Juego.intentos(), not quedan, puntaje_final)
	if Juego.demo:
		get_tree().create_timer(3.0).timeout.connect(_volver_al_menu)


# ---------------- Controles que no son de movimiento ----------------

func _unhandled_input(event: InputEvent) -> void:
	if Juego.demo:
		if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
			Juego.demo = false
			Juego.ir_a("res://escenas/menu.tscn")
		return
	if estado == "intro":
		if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo():
			_empezar()
		return
	if estado != "jugando":
		return
	if event.is_action_pressed("pausa"):
		pausar(true)
	elif event.is_action_pressed("girar_izq"):
		girar(-1)
	elif event.is_action_pressed("girar_der"):
		girar(1)
	elif event.is_action_pressed("camara"):
		var p0 := PITCH_ALTA if camara_alta else PITCH_NORMAL
		var d0 := DIST_ALTA if camara_alta else DIST_NORMAL
		camara_alta = not camara_alta
		var p1 := PITCH_ALTA if camara_alta else PITCH_NORMAL
		var d1 := DIST_ALTA if camara_alta else DIST_NORMAL
		var tw := create_tween().set_trans(Tween.TRANS_SINE)
		tw.tween_method(func(k: float): _poner_camara(lerpf(p0, p1, k), lerpf(d0, d1, k)), 0.0, 1.0, 0.35)
	elif event.is_action_pressed("reiniciar"):
		reiniciar()


func girar(d: int) -> void:
	vista = (vista + d + 4) % 4
	_yaw += d * 90.0
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camara_pivote, "rotation_degrees:y", _yaw, 0.35)
	Eventos.camara_girada.emit(vista)


func pausar(si: bool) -> void:
	get_tree().paused = si
	if si:
		hud.mostrar_pausa()
	else:
		hud.cerrar_paneles()


func _volver_al_menu() -> void:
	if is_inside_tree() and Juego.demo:
		Juego.ir_a("res://escenas/menu.tscn")


func reiniciar() -> void:
	Juego.jugar_nivel(indice)
