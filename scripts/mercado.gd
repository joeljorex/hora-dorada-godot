extends Control
## Mercado del reloj: tienda donde se gastan las monedas de sol. Cada compra es una transacción
## (se valida, se descuenta, se entrega, se registra en el historial y se guarda; si algo falla, se revierte).

var _saldo: Label
var _mensaje: Label
var _rejilla: GridContainer
var _historial: RichTextLabel
var _inventario: Label


func _ready() -> void:
	theme = Tema.crear()
	Sonido.musica("tienda")
	var fondo := TextureRect.new()
	fondo.texture = load("res://assets/sprites/fondos/desierto_lejos.png")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(fondo)
	var velo := ColorRect.new()
	velo.color = Color(0.12, 0.06, 0.03, 0.55)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)

	var raiz := VBoxContainer.new()
	Hud.anclar(raiz, Control.PRESET_FULL_RECT, 30, 20, -30, -20)
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 16)
	raiz.add_child(cabecera)
	var titulo := Tema.etiqueta("Mercado del reloj", 45, Tema.DORADO)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	var moneda := TextureRect.new()
	moneda.texture = Tema.textura("res://assets/sprites/objetos/moneda.png", 6)
	moneda.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	cabecera.add_child(moneda)
	_saldo = Tema.etiqueta("", 36, Tema.DORADO)
	cabecera.add_child(_saldo)

	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	raiz.add_child(cuerpo)

	var izquierda := ScrollContainer.new()
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izquierda.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cuerpo.add_child(izquierda)
	_rejilla = GridContainer.new()
	_rejilla.columns = 3
	_rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rejilla.add_theme_constant_override("h_separation", 10)
	_rejilla.add_theme_constant_override("v_separation", 10)
	izquierda.add_child(_rejilla)

	var derecha := PanelContainer.new()
	derecha.custom_minimum_size = Vector2(340, 0)
	cuerpo.add_child(derecha)
	var vd := VBoxContainer.new()
	derecha.add_child(vd)
	vd.add_child(Tema.etiqueta("Historial de transacciones", 27, Tema.DORADO))
	vd.add_child(HSeparator.new())
	_historial = RichTextLabel.new()
	_historial.bbcode_enabled = true
	_historial.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_historial.scroll_following = false
	vd.add_child(_historial)

	_inventario = Tema.etiqueta("", 18)
	_inventario.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_inventario)
	_mensaje = Tema.etiqueta("Elige un artículo.", 27)
	raiz.add_child(_mensaje)

	var abajo := HBoxContainer.new()
	abajo.add_theme_constant_override("separation", 12)
	raiz.add_child(abajo)
	if Juego.volver_a == "nivel" and Juego.hay_partida() and Juego.nivel_actual() < Niveles.cantidad():
		abajo.add_child(Tema.boton("Jugar el nivel %d" % (Juego.nivel_actual() + 1), func(): Juego.jugar_nivel(Juego.nivel_actual())))
	abajo.add_child(Tema.boton("Volver al menú", func(): Juego.ir_a("res://escenas/menu.tscn")))

	Eventos.transaccion.connect(_on_transaccion)
	Eventos.compra_rechazada.connect(_on_rechazo)
	_refrescar()
	(abajo.get_child(0) as Button).call_deferred("grab_focus")


func _tarjeta(id: String) -> PanelContainer:
	var art: Dictionary = Juego.CATALOGO[id]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(230, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	v.add_child(fila)
	var icono := TextureRect.new()
	var tex: Texture2D = load(art["icono"])
	var escala := maxi(1, int(40.0 / maxf(tex.get_width(), tex.get_height())))
	icono.texture = Tema.textura(art["icono"], escala)
	icono.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icono.custom_minimum_size = Vector2(44, 44)
	fila.add_child(icono)
	var nombre := Tema.etiqueta(art["nombre"], 18, Tema.DORADO)
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var desc := Tema.etiqueta(art["desc"], 18, Color(1, 0.95, 0.85))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(200, 0)
	v.add_child(desc)
	var precio := Tema.etiqueta("Precio: %d monedas" % art["precio"], 18, Tema.DORADO)
	precio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(precio)
	var b: Button
	if art["tipo"] == "disfraz" and Juego.disfraces.has(id):
		if Juego.disfraz == id:
			b = Tema.boton("Puesto", func(): pass, 18)
			b.disabled = true
		else:
			b = Tema.boton("Ponérmelo", _equipar.bind(id), 18)
	else:
		b = Tema.boton("Comprar", _comprar.bind(id), 18)
		var motivo := Juego.motivo_no_compra(id)
		if motivo != "":
			b.tooltip_text = motivo
			b.modulate = Color(1, 1, 1, 0.6)
		if art["tipo"] == "consumible":
			precio.text += "
Tienes: %d" % int(Juego.inventario.get(id, 0))
	v.add_child(b)
	return p


func _comprar(id: String) -> void:
	var r := Juego.comprar(id)
	_mensaje.text = r["mensaje"]
	_mensaje.add_theme_color_override("font_color", Tema.VERDE if r["ok"] else Tema.ROJO)
	_refrescar()


func _equipar(id: String) -> void:
	Juego.equipar(id)
	_mensaje.text = "Gno ahora usa: %s" % Juego.CATALOGO[id]["nombre"]
	_mensaje.add_theme_color_override("font_color", Tema.VERDE)
	_refrescar()


func _on_transaccion(_r: Dictionary) -> void:
	_refrescar()


func _on_rechazo(motivo: String) -> void:
	_mensaje.text = motivo
	_mensaje.add_theme_color_override("font_color", Tema.ROJO)


func _refrescar() -> void:
	_saldo.text = str(Juego.monedas)
	for c in _rejilla.get_children():
		c.queue_free()
	for id in Juego.CATALOGO.keys():
		_rejilla.add_child(_tarjeta(id))
	var lineas: Array = []
	var lista := Juego.historial.duplicate()
	lista.reverse()
	for r in lista.slice(0, 40):
		var color := "#9be37a" if int(r["monto"]) > 0 else "#ff8a6b"
		var fecha := String(r["fecha"]).substr(5, 11).replace("T", " ")
		lineas.append("[color=#d9c3a5]#%d %s[/color]\n%s [color=%s]%+d[/color]  saldo %d" % [r["id"], fecha, r["concepto"], color, int(r["monto"]), int(r["saldo"])])
	_historial.text = "\n".join(lineas) if not lineas.is_empty() else "Todavía no hay movimientos.\nGana niveles para juntar monedas de sol."
	var inv: Array = []
	for k in Juego.inventario.keys():
		if int(Juego.inventario[k]) > 0:
			inv.append("%s ×%d" % [Juego.CATALOGO[k]["nombre"], Juego.inventario[k]])
	var partida := ("Oportunidades en la partida: %d" % Juego.intentos()) if Juego.hay_partida() else "Sin partida en curso"
	_inventario.text = "Para el siguiente nivel: %s   ·   %s" % [", ".join(inv) if not inv.is_empty() else "nada", partida]
