# Resultados de las pruebas automáticas

Fecha: 2026-11-21 15:20:58 · Versión 0.9.0-beta · 4.7.2-stable (official)

**88 pruebas, 0 fallas**

| Grupo | Prueba | Resultado | Detalle |
|---|---|---|---|
| Sol y sombra | Al amanecer la sombra apunta al oeste | ✅ Pasa |  |
| Sol y sombra | Al mediodía la sombra apunta al norte | ✅ Pasa |  |
| Sol y sombra | La sombra de la mañana es mucho más larga que la del mediodía | ✅ Pasa | 5.87 vs 0.47 |
| Sol y sombra | La sombra nunca pasa del máximo (12 casillas) | ✅ Pasa |  |
| Sol y sombra | Desde lo alto la sombra empieza más lejos | ✅ Pasa | alto 0.88 / piso 0.88 |
| Sol y sombra | La sombra cubre un punto que está en su camino | ✅ Pasa | largo al mediodía 0.47 |
| Sol y sombra | En la mañana la sombra larga alcanza 4 casillas (hacia el oeste) | ✅ Pasa | largo 5.87 |
| Sol y sombra | La sombra no cubre un punto detrás de Gno | ✅ Pasa |  |
| Sol y sombra | La sombra no cubre un punto a un lado | ✅ Pasa |  |
| Sol y sombra | Sin sombra (bajo una nube) no cubre nada | ✅ Pasa |  |
| Sol y sombra | Girar la cámara y regresar da la misma dirección (vista 0) | ✅ Pasa |  |
| Sol y sombra | Girar la cámara y regresar da la misma dirección (vista 1) | ✅ Pasa |  |
| Sol y sombra | Girar la cámara y regresar da la misma dirección (vista 2) | ✅ Pasa |  |
| Sol y sombra | Girar la cámara y regresar da la misma dirección (vista 3) | ✅ Pasa |  |
| Sol y sombra | Con un giro, la sombra de la mañana cae al sur (GDD) | ✅ Pasa |  |
| Sol y sombra | Hora del reloj: 6:00 a.m. a 7:00 p.m. | ✅ Pasa |  |
| Puntaje | Bono de corazones: 100 por corazón | ✅ Pasa |  |
| Puntaje | Bono de arena: 5 por cada 1 % que sobra | ✅ Pasa | 250 |
| Puntaje | Bono de rapidez: 2 por segundo debajo de 180 | ✅ Pasa | 160 |
| Puntaje | El total suma todos los bonos | ✅ Pasa | 1510 |
| Puntaje | El evento Día veloz multiplica ×1.5 | ✅ Pasa | 750 |
| Puntaje | Si el reto no se cumple no da bono | ✅ Pasa |  |
| Puntaje | El puntaje nunca es negativo | ✅ Pasa |  |
| Puntaje | Estrellas según los umbrales del nivel | ✅ Pasa |  |
| Niveles | Nivel 1 (Amanecer): mide 24 × 13 | ✅ Pasa |  |
| Niveles | Nivel 1: un inicio y una salida | ✅ Pasa |  |
| Niveles | Nivel 1: tiene flores (4) | ✅ Pasa |  |
| Niveles | Nivel 1: se puede llegar del inicio a la salida (con puertas abiertas) | ✅ Pasa |  |
| Niveles | Nivel 2 (Adelanta el sol): mide 24 × 13 | ✅ Pasa |  |
| Niveles | Nivel 2: un inicio y una salida | ✅ Pasa |  |
| Niveles | Nivel 2: tiene flores (2) | ✅ Pasa |  |
| Niveles | Nivel 2: se puede llegar del inicio a la salida (con puertas abiertas) | ✅ Pasa |  |
| Niveles | Nivel 3 (Del otro lado): mide 24 × 13 | ✅ Pasa |  |
| Niveles | Nivel 3: un inicio y una salida | ✅ Pasa |  |
| Niveles | Nivel 3: tiene flores (4) | ✅ Pasa |  |
| Niveles | Nivel 3: se puede llegar del inicio a la salida (con puertas abiertas) | ✅ Pasa |  |
| Niveles | Nivel 4 (Placas lunares): mide 24 × 13 | ✅ Pasa |  |
| Niveles | Nivel 4: un inicio y una salida | ✅ Pasa |  |
| Niveles | Nivel 4: tiene flores (2) | ✅ Pasa |  |
| Niveles | Nivel 4: se puede llegar del inicio a la salida (con puertas abiertas) | ✅ Pasa |  |
| Niveles | Nivel 5 (Destellos): mide 24 × 13 | ✅ Pasa |  |
| Niveles | Nivel 5: un inicio y una salida | ✅ Pasa |  |
| Niveles | Nivel 5: tiene flores (4) | ✅ Pasa |  |
| Niveles | Nivel 5: se puede llegar del inicio a la salida (con puertas abiertas) | ✅ Pasa |  |
| Niveles | Nivel 6 (Nido de serpientes): mide 24 × 13 | ✅ Pasa |  |
| Niveles | Nivel 6: un inicio y una salida | ✅ Pasa |  |
| Niveles | Nivel 6: tiene flores (4) | ✅ Pasa |  |
| Niveles | Nivel 6: se puede llegar del inicio a la salida (con puertas abiertas) | ✅ Pasa |  |
| Transacciones del Mercado | Sin monedas la compra se rechaza | ✅ Pasa | No te alcanza: cuesta 20 y tienes 0. |
| Transacciones del Mercado | Se avisa el rechazo por el bus de eventos | ✅ Pasa |  |
| Transacciones del Mercado | Se depositan 100 monedas | ✅ Pasa |  |
| Transacciones del Mercado | El depósito queda en el historial | ✅ Pasa |  |
| Transacciones del Mercado | Comprar escudo (20) deja 80 | ✅ Pasa | Compraste: Escudo de luz |
| Transacciones del Mercado | El escudo queda en el inventario | ✅ Pasa |  |
| Transacciones del Mercado | Comprar disfraz (80) lo pone de una vez | ✅ Pasa |  |
| Transacciones del Mercado | No se puede comprar dos veces el mismo disfraz | ✅ Pasa | Ya tienes ese disfraz. |
| Transacciones del Mercado | El saldo coincide con la suma del historial | ✅ Pasa | 0 = 0 |
| Transacciones del Mercado | Máximo 3 consumibles del mismo tipo | ✅ Pasa | Solo puedes guardar 3 de este artículo. |
| Transacciones del Mercado | La oportunidad extra solo se compra en una partida | ✅ Pasa | Las oportunidades se compran durante una partida. |
| Transacciones del Mercado | Comprar oportunidad extra suma un intento | ✅ Pasa | 4 |
| Transacciones del Mercado | Cada transacción tiene folio, fecha y saldo | ✅ Pasa |  |
| Transacciones del Mercado | Guardar y cargar conserva saldo e historial | ✅ Pasa |  |
| Transacciones del Mercado | Un archivo dañado se respalda y no truena el juego | ✅ Pasa |  |
| Transacciones del Mercado | Los consumibles se usan solos al empezar el nivel | ✅ Pasa |  |
| Transacciones del Mercado | Una partida nueva empieza con 3 oportunidades | ✅ Pasa |  |
| Transacciones del Mercado | Perder un nivel cuesta una oportunidad | ✅ Pasa |  |
| Transacciones del Mercado | Con 0 oportunidades se acaba la partida | ✅ Pasa |  |
| Integración: demo (piloto automático) | La demo abre todas las flores del nivel 1 con la sombra | ✅ Pasa | 4 de 4 |
| Integración: demo (piloto automático) | La demo llega al reloj de sol y gana el nivel 1 | ✅ Pasa | 16.9 s de juego |
| Integración: demo (piloto automático) | Los puntos de las flores se suman (100 por flor) | ✅ Pasa | 400 |
| Integración: demo (piloto automático) | La demo no guarda monedas ni puntaje | ✅ Pasa | 70 = 70 |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | El nivel 5 tiene 4 destellos | ✅ Pasa | 4 |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | Chocar con un destello quita un corazón (Area3D) | ✅ Pasa | 3 → 2 |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | Después del golpe Gno es invulnerable un momento | ✅ Pasa |  |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | Mientras es invulnerable no recibe otro golpe | ✅ Pasa |  |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | Cubrir un destello con la sombra medio segundo lo apaga | ✅ Pasa | apagado 1.03 |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | El nivel cuenta los enemigos apagados (evento del bus) | ✅ Pasa |  |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | Tocar una moneda la recoge (Area3D.body_entered) | ✅ Pasa | 0 → 1 |
| Integración: colisiones y comportamientos (nivel 5, Destellos) | Los muros detienen a Gno (CharacterBody3D contra StaticBody3D) | ✅ Pasa | z = 5.28, muro en 4 |
| Integración: arena, intentos y victoria | Si se acaba la arena se pierde el nivel | ✅ Pasa |  |
| Integración: arena, intentos y victoria | Perder cuesta una oportunidad (3 → 2) | ✅ Pasa | 2 |
| Integración: arena, intentos y victoria | Llegar al reloj con las flores abiertas gana el nivel | ✅ Pasa |  |
| Integración: arena, intentos y victoria | Al ganar se depositan las monedas del nivel | ✅ Pasa | 0 → 7 |
| Integración: arena, intentos y victoria | El depósito queda como transacción de ingreso | ✅ Pasa |  |
| Integración: arena, intentos y victoria | Ganar desbloquea el siguiente nivel | ✅ Pasa |  |
| Integración: serpientes y lagartija (nivel 6) | El nivel 6 tiene serpientes y una lagartija | ✅ Pasa |  |
| Integración: serpientes y lagartija (nivel 6) | La serpiente persigue a Gno cuando está cerca | ✅ Pasa | perseguir |
| Integración: serpientes y lagartija (nivel 6) | La lagartija embiste si Gno queda en su fila | ✅ Pasa | embestir |
