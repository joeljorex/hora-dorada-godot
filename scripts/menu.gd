extends Control
## Menú principal. De fondo se ve el desierto del nivel 1 en 3D con el sol dando vueltas.
## Si nadie toca nada en 25 segundos empieza la DEMO (el juego se juega solo).

const ESPERA_DEMO := 25.0

var _fondo: Node3D
var _pivote: Node3D
var _luz: DirectionalLight3D
var _t := 0.1
var _inactivo := 0.0
var _caja: VBoxContainer
var _panel: PanelContainer
var _gno: Sprite3D


func _ready() -> void:
	Juego.demo = false
	theme = Tema.crear()
	_armar_fondo()
	_armar_menu()
	Sonido.musica("titulo")
	if Juego.ultimo_error != "":
		_mensaje("Aviso", Juego.ultimo_error)
		Juego.ultimo_error = ""


func _armar_fondo() -> void:
	_fondo = Node3D.new()
	add_child(_fondo)
	var mundo := Mundo.new()
	_fondo.add_child(mundo)
	mundo.construir(Niveles.obtener(0), 7)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var cielo := ProceduralSkyMaterial.new()
	cielo.sky_top_color = Color(0.32, 0.45, 0.85)
	cielo.sky_horizon_color = Color(1.0, 0.72, 0.5)
	cielo.ground_bottom_color = Color("b48a5a")
	cielo.ground_horizon_color = Color("e5c89a")
	var sky := Sky.new()
	sky.sky_material = cielo
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.9, 0.82)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.6
	var we := WorldEnvironment.new()
	we.environment = env
	_fondo.add_child(we)
	_luz = DirectionalLight3D.new()
	_luz.shadow_enabled = true
	_luz.light_energy = 0.65
	_luz.light_color = Color(1.0, 0.9, 0.78)
	_luz.directional_shadow_max_distance = 60.0
	_fondo.add_child(_luz)
	_pivote = Node3D.new()
	_pivote.position = Vector3(mundo.ancho / 2.0, 0, mundo.alto / 2.0)
	_fondo.add_child(_pivote)
	var cam := Camera3D.new()
	cam.fov = 40
	cam.position = Vector3(0, 11, 17)
	cam.rotation_degrees = Vector3(-34, 0, 0)
	_pivote.add_child(cam)
	cam.current = true
	_gno = Efectos.sprite("res://assets/sprites/personajes/%s_walk.png" % Juego.hoja_disfraz(), Rect2(), 1.4 / 16.0)
	_gno.hframes = 4
	_gno.vframes = 4
	_gno.position = Mundo.centro(mundo.inicio, 0.7)
	_gno.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_fondo.add_child(_gno)


func _armar_menu() -> void:
	var velo := ColorRect.new()
	velo.color = Color(0.1, 0.05, 0.03, 0.35)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	var titulo := Tema.etiqueta("HORA DORADA", 81, Tema.DORADO)
	titulo.add_theme_constant_override("outline_size", 18)
	Hud.anclar(titulo, Control.PRESET_TOP_LEFT, 70, 50, 900, 150)
	add_child(titulo)
	var sub := Tema.etiqueta("Mueve el sol. Mueve tu sombra.", 27)
	Hud.anclar(sub, Control.PRESET_TOP_LEFT, 76, 140, 900, 180)
	add_child(sub)
	var version := Tema.etiqueta("Versión beta %s · Godot 4.7 · UTH IDGS 8-2" % Juego.VERSION, 18, Color(1, 0.92, 0.8, 0.9))
	Hud.anclar(version, Control.PRESET_BOTTOM_LEFT, 20, -36, 900, -10)
	add_child(version)
	var p := PanelContainer.new()
	Hud.anclar(p, Control.PRESET_TOP_LEFT, 70, 210, 470, 210)
	add_child(p)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", 8)
	p.add_child(_caja)
	var botones: Array = [["Nueva partida", _nueva]]
	if Juego.hay_partida() and Juego.nivel_actual() < Niveles.cantidad():
		botones.insert(0, ["Continuar · nivel %d (%d %s)" % [Juego.nivel_actual() + 1, Juego.intentos(), "intento" if Juego.intentos() == 1 else "intentos"], _continuar])
	botones.append_array([
		["Elegir nivel", _elegir_nivel],
		["Mercado del reloj", _mercado],
		["Ver la demo", func(): Juego.iniciar_demo()],
		["Cómo jugar", _como_jugar],
		["Créditos", _creditos],
		["Salir", func(): get_tree().quit()],
	])
	for b in botones:
		_caja.add_child(Tema.boton(b[0], b[1]))
	(_caja.get_child(0) as Button).call_deferred("grab_focus")
	var info := PanelContainer.new()
	Hud.anclar(info, Control.PRESET_TOP_RIGHT, -330, 210, -40, 210)
	info.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(info)
	var vi := VBoxContainer.new()
	info.add_child(vi)
	vi.add_child(Tema.etiqueta("Monedas de sol: %d" % Juego.monedas, 18, Tema.DORADO))
	var estrellas := 0
	for k in Juego.records.keys():
		estrellas += int(Juego.records[k]["estrellas"])
	vi.add_child(Tema.etiqueta("Estrellas: %d / %d" % [estrellas, Niveles.cantidad() * 3], 18))
	vi.add_child(Tema.etiqueta("Niveles abiertos: %d / %d" % [mini(Juego.nivel_max + 1, Niveles.cantidad()), Niveles.cantidad()], 18))
	vi.add_child(Tema.etiqueta("Disfraz: %s" % ("Gno de fuego" if Juego.disfraz == "hoja" else Juego.CATALOGO[Juego.disfraz]["nombre"]), 18))


func _mercado() -> void:
	Juego.volver_a = "menu"
	Juego.ir_a("res://escenas/mercado.tscn")


func _jugar_desde(i: int) -> void:
	if not Juego.hay_partida():
		Juego.nueva_partida()
	Juego.jugar_nivel(i)


func _nueva() -> void:
	Juego.nueva_partida()
	Juego.jugar_nivel(0)


func _continuar() -> void:
	Juego.jugar_nivel(Juego.nivel_actual())


func _elegir_nivel() -> void:
	var v := _abrir_panel("Elegir nivel")
	for i in Niveles.cantidad():
		var def := Niveles.obtener(i)
		var rec: Dictionary = Juego.records.get(str(i), {"puntos": 0, "estrellas": 0})
		var texto := "%d. %s   %s   %d pts" % [i + 1, def["nombre"], "✔".repeat(int(rec["estrellas"])) if int(rec["estrellas"]) > 0 else "—", int(rec["puntos"])]
		var b := Tema.boton(texto, _jugar_desde.bind(i), 18)
		b.disabled = i > Juego.nivel_max
		if b.disabled:
			b.text = "%d. (bloqueado)" % (i + 1)
		v.add_child(b)
	v.add_child(Tema.boton("Cerrar", _cerrar_panel))


func _como_jugar() -> void:
	var v := _abrir_panel("Cómo jugar")
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.custom_minimum_size = Vector2(760, 0)
	texto.text = """[color=#ffd36b]Objetivo:[/color] abre todas las [color=#e3c8ff]flores de luna[/color] tocándolas con tu sombra y llega al reloj de sol.

[color=#ffd36b]Controles[/color]
WASD / flechas: caminar        Q / E: regresar / adelantar el sol
Espacio: estirarse (sombra más larga)   J o Shift: saltar
Z / X: girar la cámara 90°      C: cámara alta
Esc / P: pausa                  R: reiniciar    F11: pantalla completa
(También funciona con control de Xbox.)

[color=#ffd36b]Reglas[/color]
· La arena del reloj es tu tiempo: baja sola y mover el sol la gasta al triple.
· Si cae la noche o se acaba la arena, pierdes una oportunidad.
· Tienes 3 corazones por nivel y 3 oportunidades por partida.
· Destellos: apágalos con tu sombra. Serpientes: espántalas con tu sombra.
· Lagartija: embiste en línea recta; cuando se cansa, cúbrela con tu sombra.
· Monedas de sol: se guardan al ganar y se gastan en el Mercado del reloj."""
	v.add_child(texto)
	v.add_child(Tema.boton("Cerrar", _cerrar_panel))


func _creditos() -> void:
	var v := _abrir_panel("Créditos")
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.custom_minimum_size = Vector2(760, 0)
	texto.text = """[color=#ffd36b]Equipo (UTH, IDGS 8-2)[/color]
Joel Armando Ibarra Rubalcava · Jorge Humberto Martínez Delgado

[color=#ffd36b]Motor[/color]  Godot Engine 4.7 (licencia MIT)

[color=#ffd36b]Arte, música y efectos[/color]
Ninja Adventure Asset Pack, de Pixel-boy y AAA (CC0)
Sol y fondos: OpenGameArt (CC0)
Voces del narrador y de Gno: generadas con Piper

La lista completa está en assets/CREDITOS.md"""
	v.add_child(texto)
	v.add_child(Tema.boton("Cerrar", _cerrar_panel))


func _mensaje(titulo: String, texto: String) -> void:
	var v := _abrir_panel(titulo)
	var l := Tema.etiqueta(texto, 18)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	v.add_child(l)
	v.add_child(Tema.boton("Aceptar", _cerrar_panel))


func _abrir_panel(titulo: String) -> VBoxContainer:
	_cerrar_panel()
	_panel = PanelContainer.new()
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	var t := Tema.etiqueta(titulo, 36, Tema.DORADO)
	v.add_child(t)
	v.add_child(HSeparator.new())
	_panel.resized.connect(_centrar_panel)
	_enfocar_ultimo.call_deferred(v)
	return v


func _centrar_panel() -> void:
	if _panel != null:
		if _panel.size.y > _panel.get_combined_minimum_size().y + 1.0:
			_panel.reset_size()
		_panel.position = ((size - _panel.size) / 2.0).floor()


func _enfocar_ultimo(v: VBoxContainer) -> void:
	if is_instance_valid(v) and v.get_child_count() > 0:
		var ultimo := v.get_child(v.get_child_count() - 1)
		if ultimo is Button:
			(ultimo as Button).grab_focus()


func _cerrar_panel() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null
		if _caja.get_child_count() > 0:
			(_caja.get_child(0) as Button).grab_focus()


func _process(delta: float) -> void:
	_t = fmod(_t + delta / 40.0, 1.0)
	var s := Sombras.sol(0.15 + _t * 0.7)
	var d: Vector2 = s["dir"]
	var e: float = s["elev"]
	_luz.global_transform.basis = Basis.looking_at(Vector3(d.x * cos(e), -sin(e), d.y * cos(e)).normalized(), Vector3.UP)
	_pivote.rotation_degrees.y += delta * 4.0
	_gno.frame_coords = Vector2i(0, int(Time.get_ticks_msec() / 160.0) % 4)
	_inactivo += delta
	if _inactivo > ESPERA_DEMO and _panel == null:
		Juego.iniciar_demo()


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventJoypadButton:
		_inactivo = 0.0
