extends Node
## Estado global de Hora Dorada: partida en curso (intentos y puntaje), billetera de monedas de sol,
## inventario, disfraces, récords, transacciones de la tienda y guardado en disco.

const VERSION := "0.9.0-beta"
const RUTA_PARTIDA := "user://partida.json"
const INTENTOS_INICIALES := 3
const MAX_CONSUMIBLE := 3

## Catálogo del Mercado del reloj. tipo: consumible (se usa al empezar el siguiente nivel),
## intento (una oportunidad más en la partida) o disfraz (se queda para siempre).
const CATALOGO := {
	"corazon_extra": {"nombre": "Corazón extra", "desc": "Empiezas el siguiente nivel con 4 corazones.", "precio": 30, "tipo": "consumible", "icono": "res://assets/sprites/ventajas/corazon.png"},
	"arena_extra": {"nombre": "Arena extra", "desc": "+30 segundos de arena en el siguiente nivel.", "precio": 25, "tipo": "consumible", "icono": "res://assets/sprites/objetos/reloj_arena.png"},
	"escudo_inicial": {"nombre": "Escudo de luz", "desc": "Empiezas con escudo (10 s): nada te daña.", "precio": 20, "tipo": "consumible", "icono": "res://assets/sprites/ventajas/escudo.png"},
	"sombra_inicial": {"nombre": "Sombra larga", "desc": "Empiezas con la sombra 50 % más larga (15 s).", "precio": 20, "tipo": "consumible", "icono": "res://assets/sprites/ventajas/sombraLarga.png"},
	"intento_extra": {"nombre": "Oportunidad extra", "desc": "+1 intento en la partida actual.", "precio": 60, "tipo": "intento", "icono": "res://assets/sprites/personajes/flam_cara.png"},
	"traje_sombrero": {"nombre": "Sombrero de palma", "desc": "Disfraz para Gno (también se ve en su sombra).", "precio": 80, "tipo": "disfraz", "hoja": "samurai", "icono": "res://assets/sprites/personajes/samurai_cara.png"},
	"traje_paliacate": {"nombre": "Paliacate", "desc": "Disfraz rojo para cruzar el desierto.", "precio": 100, "tipo": "disfraz", "hoja": "ninjared", "icono": "res://assets/sprites/personajes/ninjared_cara.png"},
	"traje_flor": {"nombre": "Flor en el pelo", "desc": "Una flor de luna de adorno.", "precio": 120, "tipo": "disfraz", "hoja": "princess", "icono": "res://assets/sprites/personajes/princess_cara.png"},
	"traje_espiritu": {"nombre": "Espíritu de luz", "desc": "Brilla aunque sea de noche.", "precio": 150, "tipo": "disfraz", "hoja": "spirit", "icono": "res://assets/sprites/personajes/spirit_cara.png"},
}

var ruta := RUTA_PARTIDA        # las pruebas usan otra ruta para no tocar la partida real

# --- Datos que se guardan ---
var monedas := 0
var historial: Array = []        # transacciones: {id, fecha, tipo, concepto, monto, saldo}
var inventario := {"corazon_extra": 0, "arena_extra": 0, "escudo_inicial": 0, "sombra_inicial": 0}
var disfraces: Array = ["hoja"]
var disfraz := "hoja"
var nivel_max := 0               # último nivel desbloqueado (índice)
var records := {}                # "0": {"puntos": int, "estrellas": int}
var opciones := {"musica": 0.7, "efectos": 0.9, "voz": true, "pantalla_completa": false}
var partida := {}                # partida en curso: {nivel, intentos, puntaje}

# --- Estado de la sesión (no se guarda) ---
var demo := false
var volver_a := ""               # a dónde regresa el Mercado
var ultimo_error := ""


func _ready() -> void:
	configurar_controles()
	var args := OS.get_cmdline_user_args()
	# Herramientas del equipo: pruebas automáticas y capturas de pantalla (no afectan la partida real)
	if "--pruebas" in args or "--capturas" in args:
		ruta = "user://partida_pruebas.json"
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ruta)
		var herramienta := "res://pruebas/pruebas.gd" if "--pruebas" in args else "res://herramientas/capturador.gd"
		var nodo: Node = load(herramienta).new()
		get_tree().root.add_child.call_deferred(nodo)
	cargar()
	aplicar_opciones()


# ---------------- Partida: intentos (oportunidades) y puntaje ----------------

func nueva_partida() -> void:
	partida = {"nivel": 0, "intentos": INTENTOS_INICIALES, "puntaje": 0}
	demo = false
	guardar()


func hay_partida() -> bool:
	return partida.has("nivel") and int(partida.get("intentos", 0)) > 0


func nivel_actual() -> int:
	return int(partida.get("nivel", 0))


func intentos() -> int:
	return int(partida.get("intentos", 0))


func puntaje_partida() -> int:
	return int(partida.get("puntaje", 0))


## Se perdió un nivel: cuesta una oportunidad. Devuelve true si todavía quedan.
func perder_intento() -> bool:
	if demo:
		return true
	partida["intentos"] = max(0, intentos() - 1)
	guardar()
	return intentos() > 0


func terminar_partida() -> void:
	partida = {}
	guardar()


## Nivel superado: suma puntaje, guarda récord, desbloquea el siguiente y deposita las monedas.
func registrar_victoria(indice: int, puntos: int, estrellas: int, monedas_ganadas: int) -> void:
	if demo:
		return
	partida["puntaje"] = puntaje_partida() + puntos
	partida["nivel"] = indice + 1
	var r: Dictionary = records.get(str(indice), {"puntos": 0, "estrellas": 0})
	records[str(indice)] = {"puntos": max(int(r["puntos"]), puntos), "estrellas": max(int(r["estrellas"]), estrellas)}
	nivel_max = max(nivel_max, indice + 1)
	if monedas_ganadas > 0:
		depositar(monedas_ganadas, "Monedas de sol del nivel %d" % (indice + 1))
	else:
		guardar()


# ---------------- Transacciones del Mercado del reloj ----------------

func saldo_calculado() -> int:
	var s := 0
	for t in historial:
		s += int(t["monto"])
	return s


func _registrar(tipo: String, concepto: String, monto: int) -> Dictionary:
	var reg := {
		"id": historial.size() + 1,
		"fecha": Time.get_datetime_string_from_system(false, true),
		"tipo": tipo,
		"concepto": concepto,
		"monto": monto,
		"saldo": monedas,
	}
	historial.append(reg)
	return reg


## Ingreso de monedas (al ganar un nivel). Queda en el historial.
func depositar(cantidad: int, concepto: String) -> bool:
	if cantidad <= 0:
		return false
	var copia := _foto()
	monedas += cantidad
	var reg := _registrar("ingreso", concepto, cantidad)
	if not guardar():
		_restaurar(copia)
		return false
	Eventos.transaccion.emit(reg)
	return true


## Motivo por el que no se puede comprar (vacío si sí se puede).
func motivo_no_compra(id: String) -> String:
	if not CATALOGO.has(id):
		return "Ese artículo no existe."
	var art: Dictionary = CATALOGO[id]
	if art["tipo"] == "disfraz" and disfraces.has(id):
		return "Ya tienes ese disfraz."
	if art["tipo"] == "consumible" and int(inventario.get(id, 0)) >= MAX_CONSUMIBLE:
		return "Solo puedes guardar %d de este artículo." % MAX_CONSUMIBLE
	if art["tipo"] == "intento" and not hay_partida():
		return "Las oportunidades se compran durante una partida."
	if monedas < int(art["precio"]):
		return "No te alcanza: cuesta %d y tienes %d." % [art["precio"], monedas]
	return ""


## Compra un artículo. Es atómica: valida, descuenta, entrega, registra y guarda;
## si el guardado falla, todo regresa a como estaba.
func comprar(id: String) -> Dictionary:
	var motivo := motivo_no_compra(id)
	if motivo != "":
		Eventos.compra_rechazada.emit(motivo)
		return {"ok": false, "mensaje": motivo}
	var art: Dictionary = CATALOGO[id]
	var copia := _foto()
	monedas -= int(art["precio"])
	match String(art["tipo"]):
		"consumible":
			inventario[id] = int(inventario.get(id, 0)) + 1
		"intento":
			partida["intentos"] = intentos() + 1
		"disfraz":
			disfraces.append(id)
			disfraz = id
	var reg := _registrar("compra", art["nombre"], -int(art["precio"]))
	if not guardar():
		_restaurar(copia)
		var msg := "No se pudo guardar la compra; no se cobró nada."
		Eventos.compra_rechazada.emit(msg)
		return {"ok": false, "mensaje": msg}
	Eventos.transaccion.emit(reg)
	return {"ok": true, "mensaje": "Compraste: %s" % art["nombre"], "registro": reg}


## Los consumibles se usan solos al empezar un nivel (uno de cada uno).
func usar_consumibles() -> Array:
	var usados: Array = []
	if demo:
		return usados
	for id in inventario.keys():
		if int(inventario[id]) > 0:
			inventario[id] = int(inventario[id]) - 1
			usados.append(id)
	if not usados.is_empty():
		guardar()
	return usados


func equipar(id: String) -> bool:
	if id == "hoja" or disfraces.has(id):
		disfraz = id
		guardar()
		return true
	return false


func hoja_disfraz() -> String:
	if disfraz == "hoja" or not CATALOGO.has(disfraz):
		return "flam"
	return String(CATALOGO[disfraz]["hoja"])


func _foto() -> Dictionary:
	return {"monedas": monedas, "historial": historial.duplicate(true), "inventario": inventario.duplicate(),
			"disfraces": disfraces.duplicate(), "disfraz": disfraz, "partida": partida.duplicate()}


func _restaurar(f: Dictionary) -> void:
	monedas = f["monedas"]
	historial = f["historial"]
	inventario = f["inventario"]
	disfraces = f["disfraces"]
	disfraz = f["disfraz"]
	partida = f["partida"]


# ---------------- Guardado ----------------

func a_diccionario() -> Dictionary:
	return {"version": VERSION, "monedas": monedas, "historial": historial, "inventario": inventario,
			"disfraces": disfraces, "disfraz": disfraz, "nivel_max": nivel_max, "records": records,
			"opciones": opciones, "partida": partida}


## Escribe primero un archivo temporal y luego lo renombra, para no dejar la partida a medias.
func guardar() -> bool:
	var tmp := ruta + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		ultimo_error = "No se pudo abrir %s (%s)" % [tmp, error_string(FileAccess.get_open_error())]
		return false
	f.store_string(JSON.stringify(a_diccionario(), "\t"))
	f.close()
	var err := DirAccess.rename_absolute(tmp, ruta)
	if err != OK:
		ultimo_error = "No se pudo renombrar la partida (%s)" % error_string(err)
		return false
	return true


func cargar() -> void:
	if not FileAccess.file_exists(ruta):
		return
	var texto := FileAccess.get_file_as_string(ruta)
	var datos = JSON.parse_string(texto)
	if typeof(datos) != TYPE_DICTIONARY:
		# Archivo dañado: se respalda y se empieza de cero.
		DirAccess.rename_absolute(ruta, ruta + ".danado")
		ultimo_error = "La partida guardada estaba dañada; se empezó una nueva."
		return
	monedas = max(0, int(datos.get("monedas", 0)))
	historial = datos.get("historial", []) if typeof(datos.get("historial")) == TYPE_ARRAY else []
	var inv = datos.get("inventario", {})
	if typeof(inv) == TYPE_DICTIONARY:
		for k in inventario.keys():
			inventario[k] = clampi(int(inv.get(k, 0)), 0, MAX_CONSUMIBLE)
	var dis = datos.get("disfraces", ["hoja"])
	disfraces = dis if typeof(dis) == TYPE_ARRAY else ["hoja"]
	if not disfraces.has("hoja"):
		disfraces.insert(0, "hoja")
	disfraz = String(datos.get("disfraz", "hoja"))
	if not disfraces.has(disfraz):
		disfraz = "hoja"
	nivel_max = int(datos.get("nivel_max", 0))
	var rec = datos.get("records", {})
	records = rec if typeof(rec) == TYPE_DICTIONARY else {}
	var op = datos.get("opciones", {})
	if typeof(op) == TYPE_DICTIONARY:
		for k in op.keys():
			opciones[k] = op[k]
	var p = datos.get("partida", {})
	partida = p if typeof(p) == TYPE_DICTIONARY else {}
	# Si el saldo no cuadra con el historial, manda el historial (es el registro de cada transacción).
	if not historial.is_empty() and saldo_calculado() != monedas:
		monedas = max(0, saldo_calculado())


func borrar_datos() -> void:
	monedas = 0
	historial = []
	inventario = {"corazon_extra": 0, "arena_extra": 0, "escudo_inicial": 0, "sombra_inicial": 0}
	disfraces = ["hoja"]
	disfraz = "hoja"
	nivel_max = 0
	records = {}
	partida = {}
	guardar()


func aplicar_opciones() -> void:
	if bool(opciones.get("pantalla_completa", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# ---------------- Controles (InputMap) ----------------

const TECLAS := {
	"arriba": [KEY_W, KEY_UP], "abajo": [KEY_S, KEY_DOWN], "izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT],
	"sol_atras": [KEY_Q], "sol_adelante": [KEY_E], "estirar": [KEY_SPACE], "saltar": [KEY_J, KEY_SHIFT],
	"girar_izq": [KEY_Z], "girar_der": [KEY_X], "camara": [KEY_C], "pausa": [KEY_ESCAPE, KEY_P],
	"reiniciar": [KEY_R], "aceptar": [KEY_ENTER, KEY_KP_ENTER], "pantalla": [KEY_F11],
}
const BOTONES := {
	"saltar": [JOY_BUTTON_A], "estirar": [JOY_BUTTON_X], "pausa": [JOY_BUTTON_START],
	"sol_atras": [JOY_BUTTON_LEFT_SHOULDER], "sol_adelante": [JOY_BUTTON_RIGHT_SHOULDER],
	"girar_izq": [JOY_BUTTON_DPAD_LEFT], "girar_der": [JOY_BUTTON_DPAD_RIGHT], "aceptar": [JOY_BUTTON_A],
}


func configurar_controles() -> void:
	for accion in TECLAS.keys():
		if not InputMap.has_action(accion):
			InputMap.add_action(accion, 0.3)
		for k in TECLAS[accion]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(accion, ev)
	for accion in BOTONES.keys():
		for b in BOTONES[accion]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = b
			InputMap.action_add_event(accion, ev)
	var ejes := {"izquierda": [JOY_AXIS_LEFT_X, -1.0], "derecha": [JOY_AXIS_LEFT_X, 1.0],
				 "arriba": [JOY_AXIS_LEFT_Y, -1.0], "abajo": [JOY_AXIS_LEFT_Y, 1.0]}
	for accion in ejes.keys():
		var ev := InputEventJoypadMotion.new()
		ev.axis = ejes[accion][0]
		ev.axis_value = ejes[accion][1]
		InputMap.action_add_event(accion, ev)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pantalla"):
		var completa := DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if completa else DisplayServer.WINDOW_MODE_WINDOWED)
		opciones["pantalla_completa"] = completa
		guardar()


# ---------------- Cambio de escena ----------------

func ir_a(escena: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(escena)


func jugar_nivel(indice: int) -> void:
	partida["nivel"] = indice
	ir_a("res://escenas/nivel.tscn")


func iniciar_demo() -> void:
	demo = true
	ir_a("res://escenas/nivel.tscn")
