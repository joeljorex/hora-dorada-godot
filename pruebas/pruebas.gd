extends Node
## Pruebas automáticas de la beta. Se corren con:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --pruebas
## Usan una partida aparte (user://partida_pruebas.json) y escriben pruebas/resultados.json y .md.

var resultados: Array = []
var _grupo := ""
var _senales := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	print("\n=== Pruebas de Hora Dorada (beta) ===")
	_unitarias_sombras()
	_unitarias_puntaje()
	_unitarias_niveles()
	_unitarias_transacciones()
	await _integracion()
	_escribir()
	var fallos := resultados.filter(func(r): return not r["ok"]).size()
	print("\nTotal: %d pruebas, %d fallas" % [resultados.size(), fallos])
	get_tree().quit(1 if fallos > 0 else 0)


func grupo(nombre: String) -> void:
	_grupo = nombre
	print("\n[%s]" % nombre)


func ok(cond: bool, nombre: String, detalle := "") -> void:
	resultados.append({"grupo": _grupo, "prueba": nombre, "ok": cond, "detalle": detalle})
	print("  %s  %s %s" % ["OK   " if cond else "FALLA", nombre, ("(" + detalle + ")") if detalle != "" else ""])


# ---------------- Unitarias ----------------

func _unitarias_sombras() -> void:
	grupo("Sol y sombra")
	var m := Sombras.sol(0.0)
	ok(m["dir"].distance_to(Vector2(-1, 0)) < 0.001, "Al amanecer la sombra apunta al oeste")
	var n := Sombras.sol(0.5)
	ok(n["dir"].distance_to(Vector2(0, -1)) < 0.001, "Al mediodía la sombra apunta al norte")
	var largo_manana: float = Sombras.segmento(Vector2.ZERO, 0, 1.4, 0.06, 0)["largo"]
	var largo_mediodia: float = Sombras.segmento(Vector2.ZERO, 0, 1.4, 0.5, 0)["largo"]
	ok(largo_manana > largo_mediodia * 3.0, "La sombra de la mañana es mucho más larga que la del mediodía", "%.2f vs %.2f" % [largo_manana, largo_mediodia])
	ok(largo_manana <= Sombras.SOMBRA_MAX + 0.001, "La sombra nunca pasa del máximo (12 casillas)")
	var alto: float = Sombras.segmento(Vector2.ZERO, 1.6, 1.4, 0.3, 0)["largo"]
	var piso: float = Sombras.segmento(Vector2.ZERO, 0.0, 1.4, 0.3, 0)["largo"]
	ok(Sombras.segmento(Vector2.ZERO, 1.6, 1.4, 0.3, 0)["origen"].length() > 0.5, "Desde lo alto la sombra empieza más lejos", "alto %.2f / piso %.2f" % [alto, piso])
	var seg := Sombras.segmento(Vector2(5, 5), 0, 1.4, 0.5, 0)
	ok(Sombras.cubre(seg, Vector2(5, 4.6), 0.38), "La sombra cubre un punto que está en su camino", "largo al mediodía %.2f" % seg["largo"])
	var seg_m := Sombras.segmento(Vector2(5, 5), 0, 1.4, 0.06, 0)
	ok(Sombras.cubre(seg_m, Vector2(5, 5) + seg_m["dir"] * 4.0, 0.38), "En la mañana la sombra larga alcanza 4 casillas (hacia el oeste)", "largo %.2f" % seg_m["largo"])
	ok(not Sombras.cubre(seg, Vector2(5, 6.0), 0.38), "La sombra no cubre un punto detrás de Gno")
	ok(not Sombras.cubre(seg, Vector2(7, 4.0), 0.38), "La sombra no cubre un punto a un lado")
	ok(not Sombras.cubre({}, Vector2.ZERO, 1.0), "Sin sombra (bajo una nube) no cubre nada")
	for k in 4:
		var d := Vector2(0.6, -0.8)
		ok(Sombras.dir_a_vista(Sombras.dir_a_mapa(d, k), k).distance_to(d) < 0.001, "Girar la cámara y regresar da la misma dirección (vista %d)" % k)
	ok(Sombras.dir_a_mapa(Vector2(-1, 0), 1).distance_to(Vector2(0, 1)) < 0.001, "Con un giro, la sombra de la mañana cae al sur (GDD)")
	ok(Sombras.hora_texto(0.0) == "6:00 a.m." and Sombras.hora_texto(1.0) == "7:00 p.m.", "Hora del reloj: 6:00 a.m. a 7:00 p.m.")


func _unitarias_puntaje() -> void:
	grupo("Puntaje")
	var r := Puntaje.calcular_final({"base": 500, "corazones": 3, "arena": 75, "arena_max": 150, "segundos": 100,
		"reto_ok": true, "reto_bono": 300, "mult": 1.0})
	ok(r["corazones"] == 300, "Bono de corazones: 100 por corazón")
	ok(r["arena"] == 250, "Bono de arena: 5 por cada 1 % que sobra", str(r["arena"]))
	ok(r["rapidez"] == 160, "Bono de rapidez: 2 por segundo debajo de 180", str(r["rapidez"]))
	ok(r["total"] == 500 + 300 + 250 + 160 + 300, "El total suma todos los bonos", str(r["total"]))
	var r2 := Puntaje.calcular_final({"base": 500, "corazones": 0, "arena": 0, "arena_max": 150, "segundos": 999, "reto_ok": false, "reto_bono": 300, "mult": 1.5})
	ok(r2["total"] == 750, "El evento Día veloz multiplica ×1.5", str(r2["total"]))
	ok(r2["reto"] == 0, "Si el reto no se cumple no da bono")
	ok(Puntaje.calcular_final({"base": -300})["total"] == 0, "El puntaje nunca es negativo")
	ok(Puntaje.estrellas(100, [1000, 1500]) == 1 and Puntaje.estrellas(1200, [1000, 1500]) == 2 and Puntaje.estrellas(1500, [1000, 1500]) == 3, "Estrellas según los umbrales del nivel")


func _unitarias_niveles() -> void:
	grupo("Niveles")
	for i in Niveles.cantidad():
		var def := Niveles.obtener(i)
		var mapa: Array = def["mapa"]
		var medidas_ok := mapa.size() == Niveles.ALTO and mapa.all(func(f): return String(f).length() == Niveles.ANCHO)
		ok(medidas_ok, "Nivel %d (%s): mide 24 × 13" % [i + 1, def["nombre"]])
		var texto := "".join(mapa)
		ok(texto.count("P") == 1 and texto.count("X") == 1, "Nivel %d: un inicio y una salida" % [i + 1])
		ok(texto.count("F") >= 1, "Nivel %d: tiene flores (%d)" % [i + 1, texto.count("F")])
		var con_borde := Niveles.mapa_con_borde(def)
		var inicio := _buscar(con_borde, "P")
		var salida := _buscar(con_borde, "X")
		ok(_alcanzable(con_borde, inicio, salida), "Nivel %d: se puede llegar del inicio a la salida (con puertas abiertas)" % [i + 1])


func _buscar(filas: Array, ch: String) -> Vector2i:
	for j in filas.size():
		var k := String(filas[j]).find(ch)
		if k >= 0:
			return Vector2i(k, j)
	return Vector2i(-1, -1)


func _alcanzable(filas: Array, a: Vector2i, b: Vector2i) -> bool:
	var pasables := ".pP X$Chaqkudvszw"
	var visto := {a: true}
	var cola: Array = [a]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		if c == b:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.y < 0 or n.y >= filas.size() or n.x < 0 or n.x >= String(filas[0]).length() or visto.has(n):
				continue
			var ch := String(filas[n.y])[n.x]
			if pasables.contains(ch) or ch == "A" or ch == "B":
				visto[n] = true
				cola.append(n)
	return false


func _unitarias_transacciones() -> void:
	grupo("Transacciones del Mercado")
	Juego.borrar_datos()
	_escuchar(Eventos.transaccion, "transaccion")
	_escuchar(Eventos.compra_rechazada, "rechazo")
	var r := Juego.comprar("escudo_inicial")
	ok(not r["ok"] and Juego.monedas == 0, "Sin monedas la compra se rechaza", r["mensaje"])
	ok(_senales.get("rechazo", 0) == 1, "Se avisa el rechazo por el bus de eventos")
	ok(Juego.depositar(100, "Prueba: depósito"), "Se depositan 100 monedas")
	ok(Juego.monedas == 100 and Juego.historial.size() == 1, "El depósito queda en el historial")
	r = Juego.comprar("escudo_inicial")
	ok(r["ok"] and Juego.monedas == 80, "Comprar escudo (20) deja 80", r["mensaje"])
	ok(int(Juego.inventario["escudo_inicial"]) == 1, "El escudo queda en el inventario")
	r = Juego.comprar("traje_sombrero")
	ok(r["ok"] and Juego.monedas == 0 and Juego.disfraz == "traje_sombrero", "Comprar disfraz (80) lo pone de una vez")
	r = Juego.comprar("traje_sombrero")
	ok(not r["ok"], "No se puede comprar dos veces el mismo disfraz", r["mensaje"])
	ok(Juego.saldo_calculado() == Juego.monedas, "El saldo coincide con la suma del historial", "%d = %d" % [Juego.saldo_calculado(), Juego.monedas])
	Juego.depositar(200, "Prueba: segundo depósito")
	for k in 3:
		Juego.comprar("arena_extra")
	r = Juego.comprar("arena_extra")
	ok(not r["ok"] and int(Juego.inventario["arena_extra"]) == 3, "Máximo 3 consumibles del mismo tipo", r["mensaje"])
	r = Juego.comprar("intento_extra")
	ok(not r["ok"], "La oportunidad extra solo se compra en una partida", r["mensaje"])
	Juego.nueva_partida()
	r = Juego.comprar("intento_extra")
	ok(r["ok"] and Juego.intentos() == 4, "Comprar oportunidad extra suma un intento", str(Juego.intentos()))
	ok(Juego.historial.all(func(t): return t.has("id") and t.has("fecha") and t.has("saldo")), "Cada transacción tiene folio, fecha y saldo")
	# Guardar y volver a cargar
	var antes := Juego.a_diccionario()
	Juego.monedas = 99999
	Juego.cargar()
	ok(Juego.monedas == int(antes["monedas"]) and Juego.historial.size() == antes["historial"].size(), "Guardar y cargar conserva saldo e historial")
	# Archivo dañado
	var f := FileAccess.open(Juego.ruta, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	Juego.borrar_datos()
	f = FileAccess.open(Juego.ruta, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	Juego.cargar()
	ok(Juego.ultimo_error != "" and FileAccess.file_exists(Juego.ruta + ".danado"), "Un archivo dañado se respalda y no truena el juego")
	Juego.ultimo_error = ""
	Juego.borrar_datos()
	# Consumibles
	Juego.depositar(100, "Prueba")
	Juego.comprar("corazon_extra")
	var usados := Juego.usar_consumibles()
	ok(usados.has("corazon_extra") and int(Juego.inventario["corazon_extra"]) == 0, "Los consumibles se usan solos al empezar el nivel")
	# Intentos
	Juego.nueva_partida()
	ok(Juego.intentos() == 3, "Una partida nueva empieza con 3 oportunidades")
	ok(Juego.perder_intento() and Juego.intentos() == 2, "Perder un nivel cuesta una oportunidad")
	Juego.perder_intento()
	ok(not Juego.perder_intento() and Juego.intentos() == 0, "Con 0 oportunidades se acaba la partida")


func _escuchar(s: Signal, nombre: String) -> void:
	s.connect(func(_a): _senales[nombre] = int(_senales.get(nombre, 0)) + 1)


# ---------------- Integración (el juego real corriendo) ----------------

func _cargar_nivel(indice: int, demo: bool) -> Node:
	Engine.time_scale = 1.0
	Juego.demo = demo
	if not demo:
		Juego.nueva_partida()
		Juego.partida["nivel"] = indice
	var actual := get_tree().current_scene
	if actual != null:
		actual.queue_free()
	await get_tree().process_frame
	var nivel: Node = load("res://escenas/nivel.tscn").instantiate()
	get_tree().root.add_child(nivel)
	get_tree().current_scene = nivel
	await get_tree().physics_frame
	await get_tree().physics_frame
	return nivel


func _esperar_fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _integracion() -> void:
	grupo("Integración: demo (piloto automático)")
	var ganado := {"si": false, "res": {}}
	var cb := func(res):
		ganado["si"] = true
		ganado["res"] = res
	Eventos.nivel_ganado.connect(cb)
	var flores_abiertas := {"n": 0}
	var cb2 := func(_p): flores_abiertas["n"] += 1
	Eventos.flor_abierta.connect(cb2)
	var monedas_antes := Juego.monedas
	var nivel := await _cargar_nivel(0, true)
	Engine.physics_ticks_per_second = 360
	Engine.max_physics_steps_per_frame = 16
	Engine.time_scale = 6.0
	var limite := Time.get_ticks_msec() + 90000
	while not ganado["si"] and Time.get_ticks_msec() < limite and is_instance_valid(nivel):
		await get_tree().process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var total_flores: int = nivel.mundo.flores.size() if is_instance_valid(nivel) else -1
	ok(flores_abiertas["n"] == total_flores, "La demo abre todas las flores del nivel 1 con la sombra", "%d de %d" % [flores_abiertas["n"], total_flores])
	ok(ganado["si"], "La demo llega al reloj de sol y gana el nivel 1", "%.1f s de juego" % (nivel.tiempo if is_instance_valid(nivel) else -1.0))
	Eventos.nivel_ganado.disconnect(cb)
	Eventos.flor_abierta.disconnect(cb2)
	if is_instance_valid(nivel):
		ok(nivel.puntos_base >= 100 * total_flores, "Los puntos de las flores se suman (100 por flor)", str(nivel.puntos_base))
	ok(Juego.monedas == monedas_antes, "La demo no guarda monedas ni puntaje", "%d = %d" % [Juego.monedas, monedas_antes])

	grupo("Integración: colisiones y comportamientos (nivel 5, Destellos)")
	Juego.borrar_datos()
	nivel = await _cargar_nivel(4, false)
	nivel._empezar()
	ok(nivel.enemigos.size() == 4, "El nivel 5 tiene 4 destellos", str(nivel.enemigos.size()))
	var d: Enemigo = nivel.enemigos[0]
	d.vel = 0.0
	var corazones_antes: int = nivel.gno.corazones
	nivel.gno.global_position = d.global_position + Vector3(0.1, 0, 0)
	await _esperar_fisica(6)
	ok(nivel.gno.corazones == corazones_antes - 1, "Chocar con un destello quita un corazón (Area3D)", "%d → %d" % [corazones_antes, nivel.gno.corazones])
	ok(nivel.gno.invuln > 0.0, "Después del golpe Gno es invulnerable un momento")
	await _esperar_fisica(4)
	ok(nivel.gno.corazones == corazones_antes - 1, "Mientras es invulnerable no recibe otro golpe")
	# La sombra apaga a otro destello
	var d2: Enemigo = nivel.enemigos[1]
	d2.vel = 0.0
	nivel.efectos["escudo"] = 30.0
	var seg := Sombras.segmento(Vector2.ZERO, 0, Sombras.H_JUGADOR, nivel.t, nivel.vista)
	var atras: Vector2 = d2.pos_mapa() - seg["dir"] * minf(1.2, float(seg["largo"]) * 0.6)
	nivel.gno.global_position = Vector3(atras.x, 0, atras.y)
	nivel.gno.velocity = Vector3.ZERO
	await _esperar_fisica(50)
	ok(d2.muerto, "Cubrir un destello con la sombra medio segundo lo apaga", "apagado %.2f" % d2.apagado)
	ok(nivel.enemigos_apagados >= 1, "El nivel cuenta los enemigos apagados (evento del bus)")
	# Moneda (colisión con Area3D)
	var moneda: Dictionary = {}
	for o in nivel.mundo.objetos:
		if o["tipo"] == "moneda":
			moneda = o
			break
	var antes_m: int = nivel.monedas_nivel
	nivel.gno.global_position = Mundo.centro(moneda["celda"])
	await _esperar_fisica(6)
	ok(nivel.monedas_nivel == antes_m + 1, "Tocar una moneda la recoge (Area3D.body_entered)", "%d → %d" % [antes_m, nivel.monedas_nivel])
	# Muro: Gno no lo atraviesa
	var muro := Vector2i(-1, -1)
	for c in nivel.mundo.solidos.keys():
		if nivel.mundo.caracter(c) == "#" and c.x > 3 and c.y > 1 and not nivel.mundo.es_solido(c + Vector2i(0, 1)):
			muro = c
			break
	nivel.gno.global_position = Mundo.centro(muro + Vector2i(0, 1))
	for i in 40:
		nivel.gno.mover(1.0 / 60.0, Vector2(0, -1), Vector2(0, -1), 1.0, false, 1.0)
		await get_tree().physics_frame
	ok(nivel.gno.global_position.z > muro.y + 1.0 - 0.05, "Los muros detienen a Gno (CharacterBody3D contra StaticBody3D)", "z = %.2f, muro en %d" % [nivel.gno.global_position.z, muro.y])

	grupo("Integración: arena, intentos y victoria")
	nivel.arena = 0.01
	await _esperar_fisica(3)
	ok(nivel.estado == "perdido", "Si se acaba la arena se pierde el nivel")
	ok(Juego.intentos() == 2, "Perder cuesta una oportunidad (3 → 2)", str(Juego.intentos()))
	nivel = await _cargar_nivel(0, false)
	nivel._empezar()
	nivel.monedas_nivel = 7
	nivel.todas_abiertas = true
	var antes_saldo := Juego.monedas
	nivel._ganar()
	ok(nivel.estado == "ganado", "Llegar al reloj con las flores abiertas gana el nivel")
	ok(Juego.monedas == antes_saldo + 7, "Al ganar se depositan las monedas del nivel", "%d → %d" % [antes_saldo, Juego.monedas])
	ok(String(Juego.historial[-1]["tipo"]) == "ingreso", "El depósito queda como transacción de ingreso")
	ok(Juego.nivel_max >= 1 and Juego.nivel_actual() == 1, "Ganar desbloquea el siguiente nivel")

	grupo("Integración: serpientes y lagartija (nivel 6)")
	nivel = await _cargar_nivel(5, false)
	nivel._empezar()
	var serp: Serpiente = null
	var lag: Lagartija = null
	for e in nivel.enemigos:
		if e is Serpiente and serp == null:
			serp = e
		if e is Lagartija:
			lag = e
	ok(serp != null and lag != null, "El nivel 6 tiene serpientes y una lagartija")
	nivel.efectos["escudo"] = 60.0
	nivel.gno.global_position = serp.global_position + Vector3(2.5, 0, 0)
	await _esperar_fisica(30)
	ok(serp.estado == "perseguir", "La serpiente persigue a Gno cuando está cerca", serp.estado)
	var fila: Vector2i = lag.celda()
	var libre := fila
	for k in range(1, 6):
		var c := fila + Vector2i(-k, 0)
		if nivel.mundo.es_solido(c):
			break
		libre = c
	nivel.gno.global_position = Mundo.centro(libre)
	await _esperar_fisica(40)
	ok(lag.estado in ["preparar", "embestir", "cansada"], "La lagartija embiste si Gno queda en su fila", lag.estado)
	Juego.demo = false
	nivel.queue_free()
	Juego.borrar_datos()


func _escribir() -> void:
	var fallos := resultados.filter(func(r): return not r["ok"]).size()
	var datos := {"fecha": Time.get_datetime_string_from_system(false, true), "version": Juego.VERSION,
		"godot": Engine.get_version_info()["string"], "total": resultados.size(), "fallas": fallos, "resultados": resultados}
	var base := ProjectSettings.globalize_path("res://pruebas/")
	var f := FileAccess.open(base + "resultados.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(datos, "\t"))
		f.close()
	var md := "# Resultados de las pruebas automáticas\n\nFecha: %s · Versión %s · %s\n\n**%d pruebas, %d fallas**\n\n| Grupo | Prueba | Resultado | Detalle |\n|---|---|---|---|\n" % [datos["fecha"], datos["version"], datos["godot"], datos["total"], fallos]
	for r in resultados:
		md += "| %s | %s | %s | %s |\n" % [r["grupo"], r["prueba"], "✅ Pasa" if r["ok"] else "❌ Falla", String(r["detalle"]).replace("|", "/")]
	f = FileAccess.open(base + "resultados.md", FileAccess.WRITE)
	if f:
		f.store_string(md)
		f.close()
