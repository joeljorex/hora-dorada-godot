extends Node
## Bus de eventos (patrón observador).
## Cualquier parte del juego emite una señal aquí y quien le interese (HUD, sonido, puntaje, pruebas)
## se conecta sin conocer a quien la emitió.

signal flor_creciendo(pos: Vector3)
signal flor_abierta(pos: Vector3)
signal todas_las_flores
signal moneda_tomada(cantidad: int, pos: Vector3)
signal cofre_abierto(cantidad: int, pos: Vector3)
signal ventaja_tomada(tipo: String)
signal ventaja_terminada(tipo: String)
signal reloj_tomado(segundos: float)
signal enemigo_asustado(tipo: String)
signal enemigo_apagado(tipo: String, pos: Vector3)
signal jugador_golpeado(corazones: int)
signal jugador_salto
signal placa_cambio(letra: String, activa: bool)
signal puerta_cambio(letra: String, abierta: bool)
signal evento_de_nivel(id: String, nombre: String, descripcion: String)
signal reto_cumplido(nombre: String)
signal puntos(delta: int, motivo: String, pos: Vector3)
signal aviso_arena
signal camara_girada(vista: int)
signal nivel_iniciado(indice: int)
signal nivel_ganado(resultado: Dictionary)
signal nivel_perdido(motivo: String)
signal transaccion(registro: Dictionary)
signal compra_rechazada(motivo: String)
