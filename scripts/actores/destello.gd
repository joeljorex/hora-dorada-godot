class_name Destello
extends Enemigo
## Destello: espíritu de luz pura. Patrulla en línea recta y se da la vuelta al chocar.
## Si la sombra de Gno lo cubre medio segundo, se apaga.

var eje := "h"


func iniciar(n: Node, eje_patrulla: String) -> void:
	tipo = "destello"
	eje = eje_patrulla
	configurar(n, "res://assets/sprites/monstruos/destello.png", 1.0)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # es luz: no hace sombra
	vel = 1.6
	dir = Vector2.RIGHT if eje == "h" else Vector2.DOWN
	cambiar("patrullar")


func pensar(delta: float) -> void:
	if nivel.sombra_cubre(pos_mapa(), 0.3):
		apagado += delta / 0.5
		if apagado >= 1.0:
			apagar()
			return
	else:
		apagado = maxf(0.0, apagado - delta * 0.8)
	mult_vel = nivel.mult_enemigos * (1.0 - apagado * 0.8)
	sprite.modulate = Color(1, 1, 1, 1.0 - apagado * 0.6)
	if choco() and t_estado > 0.15:
		dir = -dir
		t_estado = 0.0
