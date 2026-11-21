# Tarjetas y Pull Requests de la beta

El trabajo de la beta está dividido en **tarjetas** (issues) y **ramas**. Cada rama se sube a GitHub, se abre su
**Pull Request (PR)** y el otro integrante lo **revisa** antes de unirlo a `main`. Los roles los propuso el
asistente; el equipo los puede cambiar.

Las ramas están **en capas** (cada una sale de la anterior), así que se unen en este orden:

| # | Rama | Integrante (propuesto) | Revisa | Tarjetas |
|---|---|---|---|---|
| 1 | `feature/nucleo-sol-sombra` | Joel | Jorge | T1, T2, T3 |
| 2 | `feature/enemigos` | Jorge | Joel | T4 |
| 3 | `feature/interfaz-demo` | Jorge | Joel | T5, T6 |
| 4 | `feature/mercado` | Joel | Jorge | T7 |
| 5 | `feature/pruebas-beta` | Joel y Jorge | Ambos | T8, T9, T10 |

## Tarjetas

| ID | Tarjeta | Criterio de aceptación |
|---|---|---|
| T1 | Bus de eventos, estado del juego y sonido | Las señales del bus avisan flores, golpes, compras y eventos; el sonido reacciona solo. |
| T2 | Sol y sombra (lógica) | La sombra cambia de rumbo y largo con la hora y la cámara (pruebas unitarias). |
| T3 | Mundo 3D y nivel jugable | Los 6 niveles se arman desde su mapa de texto; flores, placas, puertas, ventajas, eventos y retos funcionan. |
| T4 | Enemigos con comportamientos | Destello patrulla; serpiente deambula, persigue (A*) y huye; lagartija vigila, embiste, se cansa y regresa. |
| T5 | HUD y paneles | Corazones, oportunidades, monedas, puntaje, arena, evento, reto, ventajas; pausa, victoria y derrota. |
| T6 | Menú y modo DEMO | La demo se juega sola y abre todas las flores; empieza tras 25 s sin tocar nada. |
| T7 | Mercado del reloj (transacciones) | Validar, descontar, entregar, registrar y guardar; revertir si falla; historial con folio y saldo. |
| T8 | Pruebas automáticas | 88 pruebas pasan (`-- --pruebas`). |
| T9 | Ejecutable y capturas | `HoraDorada_Beta.exe` abre sin Godot; 11 capturas en `docs/capturas`. |
| T10 | Manual, reporte de pruebas y portafolio | Documentos Word y PDF en `docs/`. |

## Texto para cada PR

### PR 1 · Núcleo del sol y la sombra (Joel)
**Qué incluye:** bus de eventos (`eventos.gd`), estado y guardado (`juego.gd`), sonido, lógica del sol y la sombra
(`sombras.gd`), puntaje, niveles, mundo 3D (`mundo.gd`), Gno y el nivel jugable.
**Cómo probar:** abrir el proyecto en Godot 4.7; el juego completo corre al unir hasta el PR 3.
**Cierra:** T1, T2, T3.

### PR 2 · Enemigos con comportamientos (Jorge)
**Qué incluye:** clase base `Enemigo` (colisión, sprite y zona de daño) y tres máquinas de estados: `Destello`,
`Serpiente` (persigue con `AStarGrid2D` y huye de la sombra) y `Lagartija` (vigila, embiste, se cansa y regresa).
**Cómo probar:** niveles 5 y 6. **Cierra:** T4.

### PR 3 · Interfaz y modo DEMO (Jorge)
**Qué incluye:** tema de madera del paquete, HUD, paneles de pausa, victoria y derrota, menú principal y piloto
automático de la demo. **Cómo probar:** F5 → esperar 25 s en el menú. **Cierra:** T5, T6.

### PR 4 · Mercado del reloj (Joel)
**Qué incluye:** tienda con 9 artículos, compra atómica, historial de transacciones y regreso al nivel.
**Cómo probar:** ganar un nivel → Mercado del reloj → comprar. **Cierra:** T7.

### PR 5 · Pruebas, ejecutable y documentación (ambos)
**Qué incluye:** 88 pruebas automáticas, capturador, README, créditos, manual, reporte de pruebas y portafolio.
**Cómo probar:** `Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --pruebas`. **Cierra:** T8, T9, T10.

## Cómo hacer la revisión (cada integrante)

1. En el PR del compañero, pestaña **Files changed**: leer el código y dejar al menos un comentario en una línea.
2. Bajar la rama y probarla: `git fetch` y `git switch <rama>`; abrir en Godot y jugar el nivel que toca.
3. **Review changes → Approve** (o *Request changes* si algo falla) con un resumen de lo que se probó.
4. Unir con **Merge pull request** y pasar al siguiente PR.

El ejecutable (`build/HoraDorada_Beta.exe`, ~118 MB) no cabe en el repositorio: se sube como archivo de un **Release**.
