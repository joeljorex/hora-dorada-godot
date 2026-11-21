# Créditos de los recursos

## Motor y librerías

| Qué | Para qué | Licencia |
|---|---|---|
| **Godot Engine 4.7.2** | Motor del juego: render 3D, luz y sombras del sol, física (`CharacterBody3D`, `StaticBody3D`, `Area3D`), búsqueda de caminos (`AStarGrid2D`), interfaz (`Control`, `Theme`), audio, animaciones (`Tween`) y guardado (`FileAccess`, `JSON`) | MIT |
| **fontTools** (Python) | Herramienta para completar la fuente con ñ, ¡, ¿ e Í (`herramientas/completar_fuente.py`) | MIT |
| **Pillow** (Python) | Ícono y revisión de recortes | HPND |

## Arte, música y efectos

**Ninja Adventure – Asset Pack**, de **Pixel-boy** y **AAA**
- Página oficial: <https://pixel-boy.itch.io/ninja-adventure-asset-pack> (descargado el 21-nov-2026)
- Licencia: **Creative Commons Zero (CC0 1.0)**: se puede usar, modificar y publicar sin pedir permiso. Texto completo en [LICENCIA_NinjaAdventure_CC0.txt](LICENCIA_NinjaAdventure_CC0.txt).

De este paquete salen los tiles del desierto, Gno y sus disfraces, los destellos, la **serpiente** y la **lagartija**,
las flores, monedas, cofre, relojes de arena, ventajas, la interfaz de madera (paneles, botones, barra y corazones),
el cuadro de diálogo, la fuente pixel, la música (OGG) y los efectos de sonido.

La lista exacta, archivo por archivo, está en [ORIGEN.csv](ORIGEN.csv) (la genera `herramientas/copiar_recursos.py`).

**Cambios hechos a los recursos:**
- Se renombraron al español.
- A la fuente (`ui/fuente.ttf`) se le agregaron **ñ, ¡, ¿, Í, ·, ×** armándolas con piezas de la misma fuente, y se ensanchó el espacio. La original quedó en `herramientas/fuente_original.ttf`.

## Otros recursos (CC0, OpenGameArt)

| Archivo | Original |
|---|---|
| `sprites/ui/sol.png` | *Smiling Sun*, pixelado a 48 px |
| `sprites/ui/luna.png` | *Sun, Earth and Moon* (Umplix), recortada |
| `sprites/fondos/*` | *Rocky desert landscape (layered, looping)* |

## Voces

Las frases del narrador y de Gno (`audio/voz/*.mp3`) se generaron con **Piper** para la versión web de Hora Dorada
(voces `es_MX-claude-high`, Apache-2.0, y `es_MX-ald-medium`, Unlicense).

## Lo que es propio del equipo

El concepto, las mecánicas del sol y la sombra, los niveles, la historia, el código en GDScript, los comportamientos de
los enemigos, el Mercado del reloj, las pruebas y la documentación.
