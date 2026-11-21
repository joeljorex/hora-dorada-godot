class_name Niveles
extends RefCounted
## Niveles de la beta. Cada mapa mide 24 × 13; el borde de muro se agrega solo.
##
## Leyenda
##   .  arena            #  muro de adobe       P  inicio de Gno        X  reloj de sol (salida)
##   F  flor de luna     c  saguaro             b  biznaga              g  agave
##   r  roca             k  cráneo (adorno)     u  rodadora (adorno)    p  camino de piedra
##   $  moneda de sol    C  cofre (5 monedas)   h  reloj de arena (+15 s)
##   a  placa lunar → abre la puerta A          q  placa lunar → abre la puerta B
##   d  destello (patrulla en horizontal)       v  destello (patrulla en vertical)
##   s  serpiente (deambula y persigue)         z  lagartija (vigila y embiste en línea recta)

const ANCHO := 24
const ALTO := 13

const LISTA := [
	{
		"nombre": "Amanecer",
		"pista": "Tu sombra hace florecer las flores de luna. Camina hasta que tu sombra las toque.",
		"voz": "controles", "musica": "dia", "t0": 0.06, "dia": 150.0, "tiempo": 150.0, "estrellas": [1100, 1500],
		"mapa": [
			"........................",
			"..F.........c.......$...",
			"........................",
			".....c..........F.......",
			"..$.....................",
			"..........P.............",
			"....F...................",
			".................c......",
			"pppppp..............$...",
			"...c............X.......",
			"........................",
			".........F.........$....",
			"..k..............u......",
		],
	},
	{
		"nombre": "Adelanta el sol",
		"pista": "Mantén E para adelantar el sol y Q para regresarlo. Gastas arena del reloj: úsala con cuidado.",
		"voz": "nivel2", "musica": "dia", "t0": 0.35, "dia": 150.0, "tiempo": 150.0, "estrellas": [850, 1200],
		"mapa": [
			"........................",
			".###..............###...",
			".#F#..............#F#...",
			".###..............###...",
			"........................",
			"...........P............",
			"....pppppppppppppppp....",
			"..$..................$..",
			"...c............c.......",
			"........................",
			"..........X.............",
			".......$.......$........",
			"u...........k...........",
		],
	},
	{
		"nombre": "Del otro lado",
		"pista": "Tú no puedes cruzar el muro... tu sombra sí. Al amanecer las sombras son larguísimas.",
		"voz": "nivel3", "musica": "tranquila", "t0": 0.12, "dia": 240.0, "tiempo": 140.0, "estrellas": [1000, 1400],
		"mapa": [
			"...........#............",
			"...F.......#............",
			"...........#.....P......",
			"...........#.........$..",
			".......F...#............",
			"...........#............",
			"...........#.....c......",
			"...........#............",
			"..F........#....$.......",
			".....k.....#.......k....",
			"...........#............",
			".....F.....#.......X....",
			"...........#.....$......",
		],
	},
	{
		"nombre": "Placas lunares",
		"pista": "Las placas abren su puerta mientras tu sombra las cubre. Busca la hora justa.",
		"voz": "nivel4", "musica": "tranquila", "t0": 0.14, "dia": 200.0, "tiempo": 175.0, "estrellas": [950, 1350],
		"mapa": [
			"...........#............",
			"...........#.....F......",
			"...........#.........$..",
			"....P......#............",
			"...........#........F...",
			"...a.......#............",
			"...........A............",
			"...........#............",
			"...c.......#...........q",
			"...........#######B#####",
			"...........#............",
			"..$........#.....X......",
			"...........#............",
		],
	},
	{
		"nombre": "Destellos",
		"pista": "Los destellos son luz pura: atrápalos con tu sombra y se apagan. Si te tocan, pierdes un corazón.",
		"voz": "nivel5", "musica": "dia", "t0": 0.22, "dia": 160.0, "tiempo": 160.0, "estrellas": [1300, 1800],
		"mapa": [
			"........................",
			"..F...#.........#....F..",
			"......#....d....#.......",
			"......#.........#.......",
			"..$.....................",
			"....d.......P.......d...",
			".....................$..",
			"......#.........#.......",
			"......#....v....#.......",
			"..F...#.........#....F..",
			"........................",
			"..........c....c........",
			"u..k.......X.........k..",
		],
	},
	{
		"nombre": "Nido de serpientes",
		"pista": "Las serpientes te persiguen y la lagartija embiste en línea recta. Espanta a las serpientes con tu sombra; a la lagartija, cuando se cansa.",
		"voz": "", "musica": "tension", "t0": 0.2, "dia": 200.0, "tiempo": 190.0, "estrellas": [1400, 1900],
		"mapa": [
			"........................",
			"..F......#........$..F..",
			".........#..............",
			"..s......#......c.......",
			".....$...#..........s...",
			".........###..####......",
			"....P..............z....",
			".........###..####......",
			"..$......#..............",
			".........#......s....h..",
			"..F......#..C.......F...",
			".........#..............",
			"..k.....X#.......$.....u",
		],
	},
]


static func cantidad() -> int:
	return LISTA.size()


static func obtener(i: int) -> Dictionary:
	return LISTA[clampi(i, 0, LISTA.size() - 1)]


## Mapa con el borde de muro: filas de ANCHO + 2 caracteres.
static func mapa_con_borde(def: Dictionary) -> Array:
	var filas: Array = []
	var borde := "#".repeat(ANCHO + 2)
	filas.append(borde)
	for f in def["mapa"]:
		filas.append("#" + String(f) + "#")
	filas.append(borde)
	return filas
