class_name Lagartija
extends Enemigo
## Lagartija guardiana: vigila desde su puesto. Si Gno queda en su misma fila o columna sin muros
## de por medio, se prepara y embiste en línea recta. Después se cansa (no hace daño) y, si la sombra
## la cubre medio segundo mientras descansa, se rinde. Luego regresa a su puesto con A*.

const ALCANCE := 7
var puesto := Vector2i.ZERO
var cansancio := 0.0
var _embestida := Vector2.ZERO
var _zz: Label3D


func iniciar(n: Node) -> void:
	tipo = "lagartija"
	configurar(n, "res://assets/sprites/monstruos/lagartija.png", 1.05)
	puesto = celda()
	_zz = Label3D.new()
	_zz.text = "Zz"
	_zz.font = Tema.fuente()
	_zz.font_size = 40
	_zz.outline_size = 10
	_zz.pixel_size = 0.01
	_zz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_zz.position.y = 1.3
	_zz.visible = false
	add_child(_zz)
	cambiar("vigilar")


func pensar(delta: float) -> void:
	var gno: Gno = nivel.gno
	var cg := Vector2i(int(floor(gno.global_position.x)), int(floor(gno.global_position.z)))
	var c := celda()
	dania = estado != "cansada"
	_zz.visible = estado == "cansada"
	mult_vel = nivel.mult_enemigos
	match estado:
		"vigilar":
			dir = Vector2.ZERO
			var alineada := (cg.x == c.x or cg.y == c.y) and c.distance_to(cg) <= ALCANCE
			if alineada and cg != c and gno.altura() < 0.5 and nivel.mundo.linea_libre(c, cg):
				_embestida = Vector2(signi(cg.x - c.x), signi(cg.y - c.y))
				cambiar("preparar")
		"preparar":
			dir = Vector2.ZERO
			sprite.position.x = sin(t_estado * 60.0) * 0.04
			if t_estado > 0.45:
				sprite.position.x = 0
				Eventos.enemigo_asustado.emit("embestida")
				cambiar("embestir")
		"embestir":
			dir = _embestida
			vel = 6.0
			if choco() or t_estado > 1.3:
				dir = Vector2.ZERO
				cansancio = 0.0
				cambiar("cansada")
		"cansada":
			dir = Vector2.ZERO
			if nivel.sombra_cubre(pos_mapa(), 0.34):
				cansancio += delta
				sprite.modulate = Color(1, 1.0 - cansancio, 1.0 - cansancio)
				if cansancio >= 0.5:
					apagar()
					return
			if t_estado > 2.2:
				sprite.modulate = Color.WHITE
				cambiar("regresar")
		"regresar":
			vel = 1.4
			if c == puesto:
				cambiar("vigilar")
			else:
				seguir_camino(puesto)
				if t_estado > 8.0:
					cambiar("vigilar")
