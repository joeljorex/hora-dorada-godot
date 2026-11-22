extends Node
## Toma capturas de pantalla del juego real para el avance y el reporte de pruebas.
## Uso (con ventana, no headless):
##   Godot_v4.7.2-stable_win64_console.exe --path . -- --capturas
## Guarda las imágenes en docs/capturas/. Usa una partida aparte (no toca la del jugador).

var carpeta := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	carpeta = ProjectSettings.globalize_path("res://docs/capturas/")
	DirAccess.make_dir_recursive_absolute(carpeta)
	await _esperar(3.0)
	await _foto("01_menu_principal")

	Juego.borrar_datos()
	Juego.nueva_partida()
	Juego.depositar(150, "Monedas de sol del nivel 1")
	Juego.comprar("escudo_inicial")
	Juego.comprar("traje_sombrero")
	Juego.volver_a = "nivel"
	Juego.ir_a("res://escenas/mercado.tscn")
	await _esperar(1.5)
	await _foto("02_mercado_transacciones")
	Juego.equipar("hoja")

	var n := await _nivel(0)
	await _esperar(1.2)
	await _foto("03_nivel1_pista_del_narrador")
	n._empezar()
	n.gno.global_position = Vector3(6.5, 0, 6.2)
	await _esperar(2.0)
	await _foto("04_nivel1_sombra_abre_flor")

	n = await _nivel(4)
	n._empezar()
	await _esperar(4.0)
	await _foto("05_nivel5_destellos")
	_medir_fps("nivel5")

	n = await _nivel(5)
	n._empezar()
	n.efectos["escudo"] = 60.0
	await _esperar(5.0)
	await _foto("06_nivel6_serpientes_y_lagartija")
	_medir_fps("nivel6")
	n.girar(1)
	await _esperar(1.2)
	await _foto("07_camara_girada_90")
	n.pausar(true)
	await _esperar(0.6)
	await _foto("08_pausa")
	n.pausar(false)

	n = await _nivel(1)
	n._empezar()
	n.monedas_nivel = 3
	n.puntos_base = 640
	n.todas_abiertas = true
	n._ganar()
	await _esperar(1.2)
	await _foto("09_victoria_puntaje_y_estrellas")

	n = await _nivel(2)
	n._empezar()
	n.arena = 0.01
	await _esperar(1.5)
	await _foto("10_derrota_sin_arena")

	Juego.iniciar_demo()
	await _esperar(14.0)
	await _foto("11_modo_demo")
	Juego.demo = false
	Juego.borrar_datos()
	print("Capturas listas en ", carpeta)
	get_tree().quit()


var mediciones := {}


## Cuadros por segundo (para el reporte de pruebas). Se guardan en docs/capturas/rendimiento.json.
func _medir_fps(nombre: String) -> void:
	mediciones[nombre] = {"fps": Performance.get_monitor(Performance.TIME_FPS),
		"objetos_dibujados": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"memoria_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"gpu": RenderingServer.get_video_adapter_name()}
	var f := FileAccess.open(carpeta + "rendimiento.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(mediciones, "	"))
	f.close()
	print("Rendimiento ", nombre, ": ", mediciones[nombre])


func _nivel(i: int) -> Node:
	Juego.demo = false
	if not Juego.hay_partida():
		Juego.nueva_partida()
	Juego.jugar_nivel(i)
	await _esperar(0.6)
	return get_tree().current_scene


func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg, true, false, true).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(carpeta + nombre + ".png")
	print("Captura: ", nombre)
