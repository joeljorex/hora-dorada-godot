class_name Tema
extends RefCounted
## Tema de la interfaz armado con las piezas de madera y la fuente pixel del paquete Ninja Adventure.
## Las texturas se amplían 3× con "vecino más cercano" para que el pixel art se vea nítido.

const ESCALA := 3
const CREMA := Color("fff4dd")
const CAFE := Color("3b1f12")
const DORADO := Color("ffd36b")
const ROJO := Color("ff8a6b")
const VERDE := Color("9be37a")

static var _tema: Theme
static var _fuente: FontFile
static var _texturas := {}


static func fuente() -> FontFile:
	if _fuente == null:
		_fuente = load("res://assets/ui/fuente.ttf")
		_fuente.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_fuente.hinting = TextServer.HINTING_NONE
		_fuente.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _fuente


## Textura ampliada (se guarda en caché).
static func textura(ruta: String, escala := ESCALA) -> Texture2D:
	var clave := "%s@%d" % [ruta, escala]
	if _texturas.has(clave):
		return _texturas[clave]
	var t: Texture2D = load(ruta)
	if escala != 1 and t != null:
		var img := t.get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(img.get_width() * escala, img.get_height() * escala, Image.INTERPOLATE_NEAREST)
		t = ImageTexture.create_from_image(img)
	_texturas[clave] = t
	return t


## Un cuadro de una hoja de sprites (para íconos de la interfaz).
static func cuadro(ruta: String, region: Rect2, escala := ESCALA) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = textura(ruta, escala)
	a.region = Rect2(region.position * escala, region.size * escala)
	return a


## margen: un número (igual en los 4 lados) o [izq, arriba, der, abajo] en pixeles de la textura original.
static func caja(ruta: String, margen, contenido_h := 14, contenido_v := 10) -> StyleBoxTexture:
	var m: Array = margen if margen is Array else [margen, margen, margen, margen]
	var s := StyleBoxTexture.new()
	s.texture = textura(ruta)
	s.texture_margin_left = m[0] * ESCALA
	s.texture_margin_top = m[1] * ESCALA
	s.texture_margin_right = m[2] * ESCALA
	s.texture_margin_bottom = m[3] * ESCALA
	s.content_margin_left = contenido_h
	s.content_margin_right = contenido_h
	s.content_margin_top = contenido_v
	s.content_margin_bottom = contenido_v
	return s


static func crear() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	t.default_font = fuente()
	t.default_font_size = 18

	t.set_color("font_color", "Label", CREMA)
	t.set_color("font_outline_color", "Label", Color(0.12, 0.06, 0.03))
	t.set_constant("outline_size", "Label", 6)
	t.set_constant("line_spacing", "Label", 4)

	# El panel de madera tiene una "ventana" interior: se corta en 6/6/5/5 para que el centro sea de un solo color.
	t.set_stylebox("panel", "Panel", caja("res://assets/ui/panel.png", [6, 6, 5, 5]))
	t.set_stylebox("panel", "PanelContainer", caja("res://assets/ui/panel.png", [6, 6, 5, 5], 12, 8))

	var normal := caja("res://assets/ui/boton.png", 3, 18, 8)
	var hover := caja("res://assets/ui/boton_hover.png", 3, 18, 8)
	var pressed := caja("res://assets/ui/boton_pressed.png", 3, 18, 8)
	var disabled := caja("res://assets/ui/boton_disabled.png", 3, 18, 8)
	var foco := caja("res://assets/ui/foco.png", 3, 18, 8)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", foco)
	t.set_color("font_color", "Button", CAFE)
	t.set_color("font_hover_color", "Button", Color("2a120a"))
	t.set_color("font_pressed_color", "Button", CREMA)
	t.set_color("font_focus_color", "Button", CAFE)
	t.set_color("font_disabled_color", "Button", Color(0.35, 0.25, 0.2, 0.8))
	t.set_font_size("font_size", "Button", 27)

	var fondo_barra := caja("res://assets/ui/panel_interior.png", 3, 0, 0)
	var relleno := caja("res://assets/ui/barra.png", 4, 0, 0)
	t.set_stylebox("background", "ProgressBar", fondo_barra)
	t.set_stylebox("fill", "ProgressBar", relleno)
	t.set_color("font_color", "ProgressBar", CREMA)

	t.set_color("default_color", "RichTextLabel", CREMA)
	t.set_color("font_outline_color", "RichTextLabel", Color(0.12, 0.06, 0.03))
	t.set_constant("outline_size", "RichTextLabel", 4)
	t.set_font("normal_font", "RichTextLabel", fuente())
	t.set_font_size("normal_font_size", "RichTextLabel", 18)

	t.set_stylebox("panel", "TooltipPanel", caja("res://assets/ui/panel_2.png", [6, 6, 5, 5], 10, 6))
	t.set_color("font_color", "TooltipLabel", CREMA)

	var sep := StyleBoxLine.new()
	sep.color = Color(1, 0.9, 0.7, 0.35)
	sep.thickness = 3
	t.set_stylebox("separator", "HSeparator", sep)
	_tema = t
	return t


## Etiqueta con tamaño y color.
static func etiqueta(texto: String, tam := 18, color := CREMA) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


static func boton(texto: String, accion: Callable, tam := 27) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tam)
	b.pressed.connect(func():
		Sonido.sfx("clic")
		accion.call())
	b.mouse_entered.connect(func(): Sonido.sfx("navegar", 0.08))
	return b
