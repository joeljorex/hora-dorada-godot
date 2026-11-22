class_name Hud
extends CanvasLayer
## Interfaz del nivel: corazones, oportunidades, monedas, puntaje, reloj de arena, evento, reto,
## ventajas activas, pista del narrador, avisos, pausa y pantallas de victoria y derrota.
## Los tamaños de letra son múltiplos de 9 porque la fuente pixel está dibujada en una rejilla de 9.

const VENTAJAS := {
	"sombraLarga": "Sombra larga", "prisa": "Prisa", "solQuieto": "Tiempo quieto", "saltoAlto": "Salto alto",
	"escudo": "Escudo", "corazon": "Corazón", "doblePuntos": "Doble puntos", "florRapida": "Semilla mágica",
}

var nivel: Node
var _raiz: Control
var _corazones: HBoxContainer
var _intentos: HBoxContainer
var _monedas: Label
var _puntos: Label
var _hora: Label
var _sol_icono: TextureRect
var _arena: ProgressBar
var _arena_txt: Label
var _titulo: Label
var _evento: Label
var _reto: Label
var _flores: Label
var _ventajas: HBoxContainer
var _nube: Label
var _dialogo: TextureRect
var _cara: TextureRect
var _dialogo_txt: Label
var _aviso: Label
var _velo: ColorRect
var _panel: PanelContainer
var _demo: Label
var _cache_corazones := -1
var _cache_intentos := -1
var _cache_ventajas := ""


static func anclar(c: Control, preset: int, izq: float, arriba: float, der: float, abajo: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = izq
	c.offset_top = arriba
	c.offset_right = der
	c.offset_bottom = abajo


func configurar(n: Node) -> void:
	nivel = n
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.theme = Tema.crear()
	add_child(_raiz)
	_armar_izquierda()
	_armar_centro()
	_armar_derecha()
	_armar_abajo()
	_aviso = Tema.etiqueta("", 36, Tema.DORADO)
	anclar(_aviso, Control.PRESET_CENTER_TOP, -560, 150, 560, 260)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.add_theme_constant_override("outline_size", 10)
	_aviso.modulate.a = 0.0
	_raiz.add_child(_aviso)
	_demo = Tema.etiqueta("DEMO · el juego se juega solo · presiona cualquier tecla para salir", 27, Tema.DORADO)
	anclar(_demo, Control.PRESET_CENTER_BOTTOM, -600, -60, 600, -20)
	_demo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_demo.visible = false
	_raiz.add_child(_demo)
	_velo = ColorRect.new()
	_velo.color = Color(0.05, 0.02, 0.02, 0.6)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.visible = false
	_raiz.add_child(_velo)
	Eventos.puntos.connect(_on_puntos)
	Eventos.evento_de_nivel.connect(func(_i, nom, desc): aviso("Evento: %s\n%s" % [nom, desc], Tema.DORADO, 3.5))
	Eventos.reto_cumplido.connect(func(nom): aviso("¡Reto cumplido! %s" % nom, Tema.VERDE, 2.5))
	Eventos.todas_las_flores.connect(func(): aviso("¡Todas las flores abrieron! Ve al reloj de sol", Tema.DORADO, 3.0))
	Eventos.ventaja_tomada.connect(func(t): aviso("¡%s!" % VENTAJAS.get(t, t), Tema.VERDE, 1.6))
	Eventos.aviso_arena.connect(func(): aviso("¡Se acaba la arena!", Tema.ROJO, 2.0))
	Eventos.enemigo_asustado.connect(_on_asustado)
	Eventos.jugador_golpeado.connect(func(c): aviso("¡Auch! Te quedan %d %s" % [c, "corazón" if c == 1 else "corazones"], Tema.ROJO, 1.2))


func _on_asustado(tipo: String) -> void:
	if tipo == "embestida":
		aviso("¡Cuidado! La lagartija embiste", Tema.ROJO, 1.2)


func _panel_hud() -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.modulate = Color(1, 1, 1, 0.95)
	return p


func _armar_izquierda() -> void:
	var p := _panel_hud()
	anclar(p, Control.PRESET_TOP_LEFT, 12, 10, 300, 10)
	_raiz.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	_corazones = HBoxContainer.new()
	_corazones.add_theme_constant_override("separation", 4)
	v.add_child(_corazones)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	v.add_child(fila)
	_intentos = HBoxContainer.new()
	_intentos.add_theme_constant_override("separation", 2)
	fila.add_child(_intentos)
	var moneda := TextureRect.new()
	moneda.texture = Tema.textura("res://assets/sprites/objetos/moneda.png", 4)
	moneda.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	fila.add_child(moneda)
	_monedas = Tema.etiqueta("0", 18, Tema.DORADO)
	fila.add_child(_monedas)
	_puntos = Tema.etiqueta("0 pts", 27)
	v.add_child(_puntos)


func _armar_centro() -> void:
	var p := _panel_hud()
	anclar(p, Control.PRESET_CENTER_TOP, -200, 10, 200, 10)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_raiz.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	v.add_child(fila)
	_sol_icono = TextureRect.new()
	_sol_icono.texture = load("res://assets/sprites/ui/sol.png")
	_sol_icono.custom_minimum_size = Vector2(36, 36)
	_sol_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sol_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(_sol_icono)
	_hora = Tema.etiqueta("6:00 a.m.", 27, Tema.DORADO)
	fila.add_child(_hora)
	var reloj := TextureRect.new()
	reloj.texture = Tema.textura("res://assets/sprites/objetos/reloj_arena.png", 2)
	reloj.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	fila.add_child(reloj)
	_arena_txt = Tema.etiqueta("150 s", 27)
	fila.add_child(_arena_txt)
	_arena = ProgressBar.new()
	_arena.custom_minimum_size = Vector2(360, 18)
	_arena.show_percentage = false
	_arena.max_value = 1.0
	_arena.step = 0.001
	v.add_child(_arena)
	_nube = Tema.etiqueta("Bajo una nube: no tienes sombra", 18, Color("cfe3ff"))
	_nube.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nube.visible = false
	v.add_child(_nube)


func _armar_derecha() -> void:
	var p := _panel_hud()
	anclar(p, Control.PRESET_TOP_RIGHT, -372, 10, -12, 10)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_raiz.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	_titulo = Tema.etiqueta("Nivel 1", 18, Tema.DORADO)
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_titulo)
	_flores = Tema.etiqueta("Flores 0/0", 18)
	v.add_child(_flores)
	_evento = Tema.etiqueta("", 18, Color("ffe3b0"))
	_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_evento)
	_reto = Tema.etiqueta("", 18, Color("d9f5c8"))
	_reto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_reto)
	_ventajas = HBoxContainer.new()
	_ventajas.add_theme_constant_override("separation", 8)
	v.add_child(_ventajas)


func _armar_abajo() -> void:
	var teclas := Tema.etiqueta("WASD mover · Q/E sol · Espacio estirar · J saltar · Z/X girar · C cámara · Esc pausa", 18, Color(1, 0.95, 0.85, 0.9))
	anclar(teclas, Control.PRESET_BOTTOM_LEFT, 14, -34, 1200, -8)
	_raiz.add_child(teclas)
	# Cuadro de diálogo del narrador (sprite del paquete, ampliado 3×)
	_dialogo = TextureRect.new()
	_dialogo.texture = Tema.textura("res://assets/ui/dialogo.png", 3)
	anclar(_dialogo, Control.PRESET_CENTER_BOTTOM, -450, -230, 450, -56)
	_dialogo.visible = false
	_raiz.add_child(_dialogo)
	_cara = TextureRect.new()
	_cara.texture = Tema.textura("res://assets/sprites/personajes/estatua_cara.png", 3)
	_cara.position = Vector2(27, 30)
	_dialogo.add_child(_cara)
	_dialogo_txt = Tema.etiqueta("", 27, Tema.CAFE)
	_dialogo_txt.add_theme_constant_override("outline_size", 0)
	_dialogo_txt.position = Vector2(186, 22)
	_dialogo_txt.size = Vector2(690, 128)
	_dialogo_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogo_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogo.add_child(_dialogo_txt)


func mostrar_pista(texto: String, cara := "res://assets/sprites/personajes/estatua_cara.png") -> void:
	_cara.texture = Tema.textura(cara, 3)
	_dialogo_txt.text = texto
	_dialogo.visible = true
	_dialogo.modulate.a = 1.0


func ocultar_pista() -> void:
	if not _dialogo.visible:
		return
	var tw := create_tween()
	tw.tween_property(_dialogo, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _dialogo.visible = false)


func mostrar_demo(si: bool) -> void:
	_demo.visible = si


func aviso(texto: String, color := Tema.DORADO, dur := 2.0) -> void:
	_aviso.text = texto
	_aviso.add_theme_color_override("font_color", color)
	var tw := _aviso.create_tween()
	tw.tween_property(_aviso, "modulate:a", 1.0, 0.15)
	tw.tween_interval(dur)
	tw.tween_property(_aviso, "modulate:a", 0.0, 0.5)


func _on_puntos(delta: int, _motivo: String, _pos: Vector3) -> void:
	_puntos.add_theme_color_override("font_color", Tema.VERDE if delta > 0 else Tema.ROJO)
	var tw := _puntos.create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func(): _puntos.add_theme_color_override("font_color", Tema.CREMA))


func _unhandled_input(event: InputEvent) -> void:
	# El nivel está en pausa (no recibe teclas): aquí se quita la pausa con Esc.
	if get_tree().paused and event.is_action_pressed("pausa"):
		nivel.pausar(false)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if nivel == null or nivel.gno == null:
		return
	var g: Gno = nivel.gno
	if _cache_corazones != g.corazones * 10 + g.corazones_max:
		_cache_corazones = g.corazones * 10 + g.corazones_max
		for c in _corazones.get_children():
			c.queue_free()
		for i in g.corazones_max:
			var r := TextureRect.new()
			r.texture = Tema.cuadro("res://assets/ui/corazones.png", Rect2(64 if i < g.corazones else 0, 0, 16, 16), 3)
			_corazones.add_child(r)
	var quedan := Juego.intentos() if not Juego.demo else 3
	if _cache_intentos != quedan:
		_cache_intentos = quedan
		for c in _intentos.get_children():
			c.queue_free()
		for i in quedan:
			var r := TextureRect.new()
			r.texture = load("res://assets/sprites/personajes/flam_cara.png")
			r.custom_minimum_size = Vector2(28, 28)
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			r.tooltip_text = "Oportunidades que quedan"
			_intentos.add_child(r)
	_monedas.text = "%d (+%d)" % [Juego.monedas, nivel.monedas_nivel]
	_puntos.text = "%d pts" % (Juego.puntaje_partida() + nivel.puntos_base)
	_hora.text = Sombras.hora_texto(nivel.t)
	_arena.value = nivel.arena / maxf(1.0, nivel.arena_max)
	_arena.modulate = Color(1, 0.55, 0.45) if nivel.arena < 10.0 else Color.WHITE
	_arena_txt.text = "%d s" % ceili(nivel.arena)
	var alto_sol := sin(PI * clampf(nivel.t, 0.0, 1.0))
	_sol_icono.modulate = Color(1, 0.75 + 0.25 * alto_sol, 0.6 + 0.4 * alto_sol)
	_titulo.text = "Nivel %d · %s" % [nivel.indice + 1, nivel.def["nombre"]]
	var abiertas := 0
	for f in nivel.mundo.flores:
		if f["abierta"]:
			abiertas += 1
	_flores.text = "Flores de luna: %d / %d" % [abiertas, nivel.mundo.flores.size()]
	_evento.text = ("Evento: " + String(Puntaje.EVENTOS[nivel.evento]["nombre"])) if nivel.evento != "" else ""
	_reto.text = ("Reto: %s %s" % [Puntaje.RETOS[nivel.reto]["nombre"], "✔" if nivel.reto_logrado() else ""]) if nivel.reto != "" else ""
	_nube.visible = nivel.bajo_nube_gno
	_actualizar_ventajas()


func _actualizar_ventajas() -> void:
	var activos: Array = []
	for k in nivel.efectos.keys():
		if float(nivel.efectos[k]) > 0.0:
			activos.append(k)
	var clave := ",".join(activos)
	if clave != _cache_ventajas:
		_cache_ventajas = clave
		for c in _ventajas.get_children():
			c.queue_free()
		for k in activos:
			var r := TextureRect.new()
			r.texture = Tema.textura("res://assets/sprites/ventajas/%s.png" % k, 3)
			r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			r.tooltip_text = VENTAJAS.get(k, k)
			_ventajas.add_child(r)
			var l := Tema.etiqueta("", 18)
			l.name = k
			_ventajas.add_child(l)
	for k in activos:
		var l := _ventajas.get_node_or_null(NodePath(k))
		if l != null:
			(l as Label).text = "%ds" % ceili(float(nivel.efectos[k]))


# ---------------- Paneles (pausa, victoria, derrota) ----------------

func _limpiar_panel() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null


func _nuevo_panel(titulo: String, color := Tema.DORADO) -> VBoxContainer:
	_limpiar_panel()
	_velo.visible = true
	_panel = PanelContainer.new()
	_raiz.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(560, 0)
	_panel.add_child(v)
	var t := Tema.etiqueta(titulo, 45, color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(HSeparator.new())
	_panel.resized.connect(_centrar_panel)
	_centrar_panel.call_deferred()
	return v


func _centrar_panel() -> void:
	if _panel != null:
		if _panel.size.y > _panel.get_combined_minimum_size().y + 1.0:
			_panel.reset_size()
		_panel.position = ((_raiz.size - _panel.size) / 2.0).floor()


func _botones(v: VBoxContainer, lista: Array) -> void:
	var primero: Button = null
	for b in lista:
		var boton := Tema.boton(b[0], b[1], 27)
		v.add_child(boton)
		if primero == null:
			primero = boton
	if primero != null:
		primero.call_deferred("grab_focus")


func cerrar_paneles() -> void:
	_limpiar_panel()
	_velo.visible = false


func mostrar_pausa() -> void:
	var v := _nuevo_panel("Pausa")
	v.add_child(Tema.etiqueta("Nivel %d · %s" % [nivel.indice + 1, nivel.def["nombre"]], 27))
	var pista := Tema.etiqueta(nivel.def["pista"], 18, Color(1, 0.95, 0.85))
	pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pista.custom_minimum_size = Vector2(540, 0)
	v.add_child(pista)
	_botones(v, [
		["Continuar", func(): nivel.pausar(false)],
		["Reiniciar el nivel", func(): nivel.reiniciar()],
		["Salir al menú", func(): Juego.ir_a("res://escenas/menu.tscn")],
	])


func mostrar_resultado(r: Dictionary) -> void:
	var v := _nuevo_panel("¡Terminaste la beta!" if r.get("final", false) else "¡Nivel superado!")
	var estrellas := HBoxContainer.new()
	estrellas.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var e := TextureRect.new()
		e.texture = load("res://assets/sprites/ui/sol.png")
		e.custom_minimum_size = Vector2(54, 54)
		e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.modulate = Color.WHITE if i < int(r["estrellas"]) else Color(0.2, 0.15, 0.15, 0.6)
		estrellas.add_child(e)
	v.add_child(estrellas)
	var d: Dictionary = r["desglose"]
	var lineas := [
		["Puntos del nivel", d["base"]],
		["Corazones (%d × 100)" % r["corazones"], d["corazones"]],
		["Arena que sobró", d["arena"]],
		["Rapidez", d["rapidez"]],
		["Reto: %s" % r["reto_nombre"], d["reto"]],
	]
	for l in lineas:
		var fila := HBoxContainer.new()
		var a := Tema.etiqueta(String(l[0]), 18)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(a)
		fila.add_child(Tema.etiqueta("+%d" % int(l[1]), 18, Tema.VERDE if int(l[1]) > 0 else Color(0.8, 0.8, 0.8)))
		v.add_child(fila)
	if float(d["mult"]) != 1.0:
		v.add_child(Tema.etiqueta("Multiplicador del evento: ×%.1f" % d["mult"], 18, Tema.DORADO))
	v.add_child(HSeparator.new())
	v.add_child(Tema.etiqueta("Total: %d puntos" % int(d["total"]), 36, Tema.DORADO))
	v.add_child(Tema.etiqueta("Monedas de sol ganadas: %d" % int(r["monedas"]), 18, Tema.DORADO))
	if Juego.demo:
		v.add_child(Tema.etiqueta("(Demo: no se guarda nada)", 18))
		return
	var botones: Array = []
	if not r.get("final", false):
		botones.append(["Siguiente nivel", func(): Juego.jugar_nivel(nivel.indice + 1)])
		botones.append(["Mercado del reloj", _ir_mercado])
		botones.append(["Repetir este nivel", func(): Juego.jugar_nivel(nivel.indice)])
	else:
		v.add_child(Tema.etiqueta("Puntaje de la partida: %d" % int(r["puntaje_partida"]), 27))
	botones.append(["Menú principal", func(): Juego.ir_a("res://escenas/menu.tscn")])
	_botones(v, botones)


func mostrar_derrota(motivo: String, quedan: int, fin: bool, puntaje_final: int) -> void:
	var v := _nuevo_panel("Fin del juego" if fin else "¡Oh, no!", Tema.ROJO)
	var m := Tema.etiqueta(motivo, 27)
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.custom_minimum_size = Vector2(540, 0)
	v.add_child(m)
	if Juego.demo:
		return
	if fin:
		v.add_child(Tema.etiqueta("Se acabaron tus oportunidades.", 18, Tema.ROJO))
		v.add_child(Tema.etiqueta("Puntaje final: %d" % puntaje_final, 36, Tema.DORADO))
		_botones(v, [
			["Nueva partida", _nueva_partida],
			["Menú principal", func(): Juego.ir_a("res://escenas/menu.tscn")],
		])
	else:
		v.add_child(Tema.etiqueta("Te quedan %d %s." % [quedan, "oportunidad" if quedan == 1 else "oportunidades"], 18))
		_botones(v, [
			["Reintentar", func(): Juego.jugar_nivel(nivel.indice)],
			["Mercado del reloj", _ir_mercado],
			["Menú principal", func(): Juego.ir_a("res://escenas/menu.tscn")],
		])


func _ir_mercado() -> void:
	Juego.volver_a = "nivel"
	Juego.ir_a("res://escenas/mercado.tscn")


func _nueva_partida() -> void:
	Juego.nueva_partida()
	Juego.jugar_nivel(0)
