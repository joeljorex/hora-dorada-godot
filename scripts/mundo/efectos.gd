class_name Efectos
extends RefCounted
## Ayudantes para crear sprites 3D con recorte de una hoja, animaciones de un solo uso y textos flotantes.

const PIXEL := 1.0 / 16.0
static var _mats := {}


static func sprite(ruta: String, region := Rect2(), pixel := PIXEL, billboard := BaseMaterial3D.BILLBOARD_FIXED_Y) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = load(ruta)
	if region.size != Vector2.ZERO:
		s.region_enabled = true
		s.region_rect = region
	s.pixel_size = pixel
	s.billboard = billboard
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = false
	s.double_sided = true
	return s


## Coloca el sprite con la base en el suelo.
static func apoyar(s: Sprite3D) -> void:
	var alto := s.region_rect.size.y if s.region_enabled else float(s.texture.get_height()) / maxf(1.0, s.vframes)
	s.position.y = alto * s.pixel_size * 0.5


## Animación de un solo uso (chispa, humo...) que se borra sola.
static func animacion(padre: Node3D, ruta: String, cuadros: int, pos: Vector3, fps := 14.0, pixel := PIXEL) -> void:
	var s := sprite(ruta, Rect2(), pixel, BaseMaterial3D.BILLBOARD_ENABLED)
	s.hframes = cuadros
	s.position = pos
	padre.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "frame", cuadros - 1, cuadros / fps).from(0)
	tw.tween_callback(s.queue_free)


## Texto que sube y se desvanece ("+100").
static func texto(padre: Node3D, contenido: String, pos: Vector3, color := Color("ffe9a8"), tam := 48) -> void:
	var l := Label3D.new()
	l.text = contenido
	l.font = Tema.fuente()
	l.font_size = tam
	l.outline_size = 12
	l.modulate = color
	l.outline_modulate = Color(0.15, 0.07, 0.03)
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.position = pos
	padre.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 1.2, 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


## Material para un recorte de un atlas (suelo, muros...).
static func material_atlas(ruta: String, tinte := Color.WHITE) -> StandardMaterial3D:
	var clave := "%s|%s" % [ruta, tinte.to_html()]
	if _mats.has(clave):
		return _mats[clave]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(ruta)
	m.albedo_color = tinte
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.metallic_specular = 0.0
	_mats[clave] = m
	return m


## Cuadro plano en el suelo con un recorte del atlas (placas, adornos).
static func calcomania(ruta: String, region: Rect2, tam := 1.0, alto := 0.02) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam)
	q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	var tex: Texture2D = load(ruta)
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tam_tex := Vector2(tex.get_width(), tex.get_height())
	m.uv1_scale = Vector3(region.size.x / tam_tex.x, region.size.y / tam_tex.y, 1)
	m.uv1_offset = Vector3(region.position.x / tam_tex.x, region.position.y / tam_tex.y, 0)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position.y = alto
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func cambiar_region(mi: MeshInstance3D, region: Rect2) -> void:
	var m: StandardMaterial3D = mi.material_override
	var tam_tex := Vector2(m.albedo_texture.get_width(), m.albedo_texture.get_height())
	m.uv1_offset = Vector3(region.position.x / tam_tex.x, region.position.y / tam_tex.y, 0)
