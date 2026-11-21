class_name Serpiente
extends Enemigo
## Serpiente: deambula; si Gno se acerca, lo persigue usando A* (AStarGrid2D) para rodear muros.
## Le tiene miedo a la sombra: mientras la cubre huye, y si la cubre 1 segundo en total se esconde bajo la arena.

const RADIO_VISTA := 4.5
const RADIO_OLVIDO := 7.0
var miedo := 0.0
var _t_ruta := 0.0


func iniciar(n: Node) -> void:
	tipo = "serpiente"
	configurar(n, "res://assets/sprites/monstruos/serpiente.png", 1.0)
	vel = 0.9
	dir = dir_libre_al_azar()
	cambiar("deambular")


func pensar(delta: float) -> void:
	var gno: Gno = nivel.gno
	var distancia := pos_mapa().distance_to(gno.pos_mapa())
	var cubierta: bool = nivel.sombra_cubre(pos_mapa(), 0.32)
	if cubierta:
		miedo += delta
		if miedo >= 1.0:
			apagar()
			return
		if estado != "huir":
			Eventos.enemigo_asustado.emit(tipo)
			cambiar("huir")
	else:
		miedo = maxf(0.0, miedo - delta * 0.5)
	sprite.modulate = Color(1, 1.0 - miedo * 0.5, 1.0 - miedo * 0.5)
	match estado:
		"deambular":
			vel = 0.9
			if t_estado > 2.0 or choco():
				dir = dir_libre_al_azar()
				t_estado = randf() * 0.8
			if distancia < RADIO_VISTA and gno.altura() < 0.5:
				cambiar("perseguir")
		"perseguir":
			vel = 1.55
			_t_ruta -= delta
			if _t_ruta <= 0.0:
				seguir_camino(Vector2i(int(floor(gno.global_position.x)), int(floor(gno.global_position.z))))
				_t_ruta = 0.35
			if distancia > RADIO_OLVIDO:
				cambiar("deambular")
		"huir":
			vel = 2.1
			var lejos := pos_mapa() - gno.pos_mapa()
			dir = lejos.normalized() if lejos.length() > 0.01 else dir_libre_al_azar()
			if not cubierta and t_estado > 1.0:
				cambiar("deambular")
	mult_vel = nivel.mult_enemigos
