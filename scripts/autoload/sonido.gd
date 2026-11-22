extends Node
## Música, efectos y voces. Escucha el bus de Eventos, así el resto del juego no tiene que
## acordarse de tocar sonidos.

const SFX := "res://assets/audio/sfx/%s.wav"
const MUSICA := "res://assets/audio/musica/%s.ogg"
const VOZ := "res://assets/audio/voz/%s.mp3"

var _musica: AudioStreamPlayer
var _voz: AudioStreamPlayer
var _canales: Array[AudioStreamPlayer] = []
var _cache := {}
var _musica_actual := ""
var _ultimo := {}   # para no repetir el mismo efecto muchas veces seguidas


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = AudioStreamPlayer.new()
	add_child(_musica)
	_voz = AudioStreamPlayer.new()
	add_child(_voz)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_canales.append(p)
	_musica.finished.connect(func(): _musica.play())
	# Efectos conectados a los eventos del juego
	Eventos.flor_creciendo.connect(func(_p): sfx("crece", 0.18))
	Eventos.flor_abierta.connect(func(_p): sfx("flor"))
	Eventos.todas_las_flores.connect(func(): sfx("todas"))
	Eventos.moneda_tomada.connect(func(_c, _p): sfx("moneda"))
	Eventos.cofre_abierto.connect(func(_c, _p): sfx("cofre"))
	Eventos.ventaja_tomada.connect(func(_t): sfx("ventaja"))
	Eventos.reloj_tomado.connect(func(_s): sfx("reloj"))
	Eventos.enemigo_apagado.connect(func(_t, _p): sfx("destello"))
	Eventos.enemigo_asustado.connect(func(_t): sfx("serpiente", 0.8))
	Eventos.jugador_golpeado.connect(func(_c): sfx("danio"))
	Eventos.jugador_salto.connect(func(): sfx("saltar"))
	Eventos.placa_cambio.connect(func(_l, a): sfx("placa" if a else "placa_off"))
	Eventos.puerta_cambio.connect(func(_l, _a): sfx("puerta"))
	Eventos.evento_de_nivel.connect(func(_i, _n, _d): sfx("evento"))
	Eventos.reto_cumplido.connect(func(_n): sfx("todas"))
	Eventos.aviso_arena.connect(func(): sfx("sin_arena"))
	Eventos.camara_girada.connect(func(_v): sfx("girar"))
	Eventos.nivel_ganado.connect(func(_r): sfx("ganar"))
	Eventos.nivel_perdido.connect(func(_m): sfx("perder"))
	Eventos.transaccion.connect(func(r): sfx("compra" if r["tipo"] == "compra" else "moneda"))
	Eventos.compra_rechazada.connect(func(_m): sfx("rechazo"))


func _cargar(ruta: String) -> AudioStream:
	if _cache.has(ruta):
		return _cache[ruta]
	var s: AudioStream = load(ruta) if ResourceLoader.exists(ruta) else null
	_cache[ruta] = s
	return s


func _db(v: float) -> float:
	return linear_to_db(clampf(v, 0.0001, 1.0))


func sfx(nombre: String, espera := 0.05) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	if ahora - float(_ultimo.get(nombre, -10.0)) < espera:
		return
	_ultimo[nombre] = ahora
	var s := _cargar(SFX % nombre)
	if s == null:
		return
	for p in _canales:
		if not p.playing:
			p.stream = s
			p.volume_db = _db(float(Juego.opciones.get("efectos", 0.9)))
			p.play()
			return


func musica(nombre: String) -> void:
	if nombre == _musica_actual and _musica.playing:
		return
	_musica_actual = nombre
	var s := _cargar(MUSICA % nombre)
	if s == null:
		_musica.stop()
		return
	_musica.stream = s
	_musica.volume_db = _db(float(Juego.opciones.get("musica", 0.7)) * 0.8)
	_musica.play()


func actualizar_volumen() -> void:
	_musica.volume_db = _db(float(Juego.opciones.get("musica", 0.7)) * 0.8)


func voz(nombre: String) -> void:
	if not bool(Juego.opciones.get("voz", true)):
		return
	var s := _cargar(VOZ % nombre)
	if s == null:
		return
	_voz.stream = s
	_voz.volume_db = _db(float(Juego.opciones.get("efectos", 0.9)))
	_voz.play()


func callar() -> void:
	_voz.stop()
