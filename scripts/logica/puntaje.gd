class_name Puntaje
extends RefCounted
## Puntaje (GDD §10). Los puntos se suman durante el nivel y los bonos se calculan al ganar.

const PUNTOS := {
	"flor": 100, "destello": 50, "serpiente": 75, "lagartija": 100, "moneda": 10, "cofre": 40,
	"ventaja": 50, "reloj": 30, "golpe": -50,
}
const BONO_CORAZON := 100
const BONO_ARENA_POR_CIENTO := 5
const BONO_RAPIDEZ_SEG := 2
const LIMITE_RAPIDEZ := 180.0

const EVENTOS := {
	"brisa": {"nombre": "Brisa del desierto", "desc": "Pasan nubes: bajo su sombra no tienes sombra."},
	"dia_veloz": {"nombre": "Día veloz", "desc": "El sol avanza más rápido, pero ganas 50 % más puntos."},
	"lluvia": {"nombre": "Lluvia de ventajas", "desc": "Aparecen más ventajas en el mapa."},
	"tesoro": {"nombre": "Tesoro de arena", "desc": "Hay monedas y relojes de arena extra."},
	"inquietos": {"nombre": "Enemigos inquietos", "desc": "Los enemigos van más rápido y valen el doble."},
}
const RETOS := {
	"sin_golpes": {"nombre": "Termina sin perder corazones", "bono": 300},
	"ventajas2": {"nombre": "Recoge 2 ventajas", "bono": 300},
	"enemigos": {"nombre": "Apaga a todos los enemigos", "bono": 400},
	"arena": {"nombre": "Termina con la mitad de arena o más", "bono": 300},
	"rapido": {"nombre": "Termina en menos de 2 minutos", "bono": 300},
}


## Bonos al ganar. datos: {base, corazones, arena, arena_max, segundos, reto_ok, reto_bono, mult}
static func calcular_final(datos: Dictionary) -> Dictionary:
	var base := int(datos.get("base", 0))
	var b_corazones := int(datos.get("corazones", 0)) * BONO_CORAZON
	var frac := 0.0
	if float(datos.get("arena_max", 0.0)) > 0.0:
		frac = clampf(float(datos.get("arena", 0.0)) / float(datos["arena_max"]), 0.0, 1.0)
	var b_arena := int(round(frac * 100.0)) * BONO_ARENA_POR_CIENTO
	var b_rapidez := int(maxf(0.0, LIMITE_RAPIDEZ - float(datos.get("segundos", LIMITE_RAPIDEZ)))) * BONO_RAPIDEZ_SEG
	var b_reto := int(datos.get("reto_bono", 0)) if bool(datos.get("reto_ok", false)) else 0
	var subtotal := base + b_corazones + b_arena + b_rapidez + b_reto
	var mult := float(datos.get("mult", 1.0))
	var total := maxi(0, int(round(subtotal * mult)))
	return {"base": base, "corazones": b_corazones, "arena": b_arena, "rapidez": b_rapidez, "reto": b_reto,
			"mult": mult, "total": total}


static func estrellas(total: int, umbrales: Array) -> int:
	var e := 1
	if umbrales.size() > 0 and total >= int(umbrales[0]):
		e = 2
	if umbrales.size() > 1 and total >= int(umbrales[1]):
		e = 3
	return e
