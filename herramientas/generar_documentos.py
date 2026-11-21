"""Genera los documentos de entrega de la beta en Word (python-docx):

  docs/HoraDorada_Portafolio_de_evidencias_beta.docx   (todo junto)
  docs/HoraDorada_Manual_de_usuario.docx
  docs/HoraDorada_Reporte_de_pruebas_beta.docx

Lee los resultados reales de pruebas/resultados.json, el rendimiento de docs/capturas/rendimiento.json
y las capturas de docs/capturas/. Uso:  python herramientas/generar_documentos.py
Después, Word actualiza el índice (o se hace con herramientas/actualizar_indices.ps1)."""
import datetime, json, os
from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(RAIZ, "docs")
CAP = os.path.join(DOCS, "capturas")
CAFE = RGBColor(0x7A, 0x3B, 0x12)
NARANJA = RGBColor(0xC8, 0x5A, 0x1E)
GRIS = RGBColor(0x55, 0x55, 0x55)

EQUIPO = ["Joel Armando Ibarra Rubalcava", "Jorge Humberto Martínez Delgado"]
REPO_GDD = "https://github.com/joeljorex/hora-dorada"
FECHA = "21 de noviembre de 2026"

with open(os.path.join(RAIZ, "pruebas", "resultados.json"), encoding="utf-8") as f:
    PRUEBAS = json.load(f)
REND = {}
if os.path.exists(os.path.join(CAP, "rendimiento.json")):
    with open(os.path.join(CAP, "rendimiento.json"), encoding="utf-8") as f:
        REND = json.load(f)


# ---------------------------------------------------------------- ayudantes

def documento(titulo_doc):
    d = Document()
    s = d.sections[0]
    s.page_width, s.page_height = Cm(21.59), Cm(27.94)   # carta
    for m in ("left_margin", "right_margin"):
        setattr(s, m, Cm(2.3))
    s.top_margin, s.bottom_margin = Cm(2.2), Cm(2.0)
    est = d.styles["Normal"]
    est.font.name = "Calibri"
    est.font.size = Pt(11)
    est.element.rPr.rFonts.set(qn("w:eastAsia"), "Calibri")
    est.paragraph_format.space_after = Pt(6)
    est.paragraph_format.line_spacing = 1.12
    for nivel, tam, color in ((1, 18, CAFE), (2, 14, NARANJA), (3, 12, CAFE)):
        h = d.styles["Heading %d" % nivel]
        h.font.name = "Calibri"
        h.font.size = Pt(tam)
        h.font.bold = True
        h.font.color.rgb = color
        h.element.rPr.rFonts.set(qn("w:eastAsia"), "Calibri")
        h.paragraph_format.space_before = Pt(14 if nivel == 1 else 10)
        h.paragraph_format.space_after = Pt(6)
        h.paragraph_format.keep_with_next = True
    # Pie de página con número
    pie = s.footer.paragraphs[0]
    pie.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = pie.add_run("Hora Dorada · %s · página " % titulo_doc)
    r.font.size = Pt(9)
    r.font.color.rgb = GRIS
    _campo(pie, "PAGE", 9)
    return d


def _campo(parrafo, instruccion, tam=None):
    r = parrafo.add_run()
    if tam:
        r.font.size = Pt(tam)
    f1 = OxmlElement("w:fldChar"); f1.set(qn("w:fldCharType"), "begin")
    it = OxmlElement("w:instrText"); it.set(qn("xml:space"), "preserve"); it.text = instruccion
    f2 = OxmlElement("w:fldChar"); f2.set(qn("w:fldCharType"), "separate")
    t = OxmlElement("w:t"); t.text = "1" if instruccion == "PAGE" else "(Clic derecho → Actualizar campo para ver el índice)"
    f3 = OxmlElement("w:fldChar"); f3.set(qn("w:fldCharType"), "end")
    for e in (f1, it, f2, t, f3):
        r._r.append(e)


def indice(d):
    d.add_heading("Índice", level=1)
    _campo(d.add_paragraph(), 'TOC \\o "1-2" \\h \\z \\u')
    salto(d)


def salto(d):
    d.add_paragraph().add_run().add_break(WD_BREAK.PAGE)


def p(d, texto, negrita=False, italica=False, color=None, tam=None, centro=False, despues=None):
    par = d.add_paragraph()
    _texto_con_negritas(par, texto, negrita, italica, color, tam)
    if centro:
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    if despues is not None:
        par.paragraph_format.space_after = Pt(despues)
    return par


def _texto_con_negritas(par, texto, negrita=False, italica=False, color=None, tam=None):
    """**texto** va en negritas y `texto` en letra de código."""
    import re
    for trozo in re.split(r"(\*\*[^*]+\*\*|`[^`]+`)", texto):
        if not trozo:
            continue
        r = par.add_run(trozo.strip("*`") if (trozo.startswith("**") or trozo.startswith("`")) else trozo)
        r.bold = negrita or trozo.startswith("**")
        r.italic = italica
        if trozo.startswith("`"):
            r.font.name = "Consolas"
            r.font.size = Pt(10)
            r.font.color.rgb = CAFE
        if color:
            r.font.color.rgb = color
        if tam:
            r.font.size = Pt(tam)


def viñetas(d, lista, estilo="List Bullet"):
    for t in lista:
        par = d.add_paragraph(style=estilo)
        _texto_con_negritas(par, t)
        par.paragraph_format.space_after = Pt(2)


def tabla(d, encabezado, filas, anchos=None, tam=9.5):
    t = d.add_table(rows=1, cols=len(encabezado))
    t.style = "Light Grid Accent 2"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(encabezado):
        c = t.rows[0].cells[i]
        c.text = ""
        r = c.paragraphs[0].add_run(h)
        r.bold = True
        r.font.size = Pt(tam)
    for fila in filas:
        cells = t.add_row().cells
        for i, v in enumerate(fila):
            cells[i].text = ""
            _texto_con_negritas(cells[i].paragraphs[0], str(v), tam=tam)
    if anchos:
        for fila in t.rows:
            for i, w in enumerate(anchos):
                fila.cells[i].width = Cm(w)
    # Repetir encabezado en cada página
    trPr = t.rows[0]._tr.get_or_add_trPr()
    th = OxmlElement("w:tblHeader"); th.set(qn("w:val"), "true"); trPr.append(th)
    d.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


def imagen(d, archivo, pie, ancho=15.5):
    ruta = os.path.join(CAP, archivo)
    if not os.path.exists(ruta):
        p(d, "[Falta la imagen %s]" % archivo, italica=True, color=GRIS)
        return
    d.add_picture(ruta, width=Cm(ancho))
    d.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    par = p(d, pie, italica=True, color=GRIS, tam=9, centro=True)
    par.paragraph_format.space_after = Pt(10)


def codigo(d, texto):
    for linea in texto.strip("\n").split("\n"):
        par = d.add_paragraph()
        par.paragraph_format.space_after = Pt(0)
        par.paragraph_format.left_indent = Cm(0.6)
        r = par.add_run(linea)
        r.font.name = "Consolas"
        r.font.size = Pt(9)
        r.font.color.rgb = RGBColor(0x33, 0x33, 0x33)
    d.add_paragraph().paragraph_format.space_after = Pt(2)


def portada(d, titulo, subtitulo):
    for _ in range(2):
        d.add_paragraph()
    p(d, "Universidad Tecnológica de Hermosillo", negrita=True, tam=16, centro=True, color=CAFE)
    p(d, "IDGS 8-2", tam=12, centro=True)
    p(d, "Materia: ______________________________", tam=11, centro=True, color=GRIS)
    p(d, "Docente: ______________________________", tam=11, centro=True, color=GRIS)
    d.add_paragraph()
    p(d, titulo, negrita=True, tam=26, centro=True, color=NARANJA, despues=2)
    p(d, subtitulo, tam=14, centro=True, color=CAFE)
    d.add_paragraph()
    imagen(d, "06_nivel6_serpientes_y_lagartija.png", "Hora Dorada · versión beta 0.9 en Godot 4.7", 14)
    p(d, "Equipo", negrita=True, tam=12, centro=True)
    for n in EQUIPO:
        p(d, n, tam=12, centro=True, despues=0)
    d.add_paragraph()
    p(d, "Hermosillo, Sonora · " + FECHA, tam=11, centro=True, color=GRIS)
    salto(d)


# ---------------------------------------------------------------- contenido

def seccion_caso(d):
    d.add_heading("1. Caso práctico", level=1)
    p(d, "El caso práctico es el videojuego **Hora Dorada**, diseñado por el equipo en su Documento de Diseño de "
         "Juego (GDD). Es un **rompecabezas en 3D** ambientado en el desierto de Sonora: el jugador es **Gno**, el "
         "espíritu de un viejo reloj de sol, y con la arena de su reloj **mueve el sol**. Su sombra abre las **flores de "
         "luna**, activa placas que abren puertas y apaga a los enemigos de luz.")
    tabla(d, ["Elemento", "Descripción"], [
        ["Género", "Rompecabezas de lógica espacial con acción ligera (esquivar enemigos, juntar monedas, contrarreloj)."],
        ["Público", "De 8 años en adelante (clasificación sugerida E). Jugadores casuales y estudiantes."],
        ["Regla principal", "La sombra de Gno cambia de dirección y de largo según la hora: larga al amanecer y al atardecer, corta al mediodía."],
        ["Objetivo de cada nivel", "Abrir todas las flores con la sombra y llegar al reloj de sol antes de que se acabe la arena o caiga la noche."],
        ["GDD y versión web", REPO_GDD],
    ], [4, 12.5])
    p(d, "La versión beta pasa el juego del navegador (JavaScript) a un **motor gráfico real, Godot 4.7**, con sprites "
         "pixel art reales (paquete Ninja Adventure, licencia CC0), física, luces y sombras del motor, y agrega lo que "
         "pide la tarea: comportamientos de enemigos, transacciones (Mercado del reloj), puntaje, oportunidades y modo demo.")


def seccion_beta(d):
    d.add_heading("2. Videojuego en versión beta", level=1)
    d.add_heading("2.1 Qué trae la beta", level=2)
    viñetas(d, [
        "**6 niveles jugables**: Amanecer, Adelanta el sol, Del otro lado, Placas lunares, Destellos y **Nido de serpientes** (nuevo).",
        "**Mundo 3D** con cámara que gira 90° (Z/X) y cámara alta (C). El sol del motor ilumina y proyecta sombras según la hora.",
        "**3 tipos de enemigo** con comportamientos distintos: destello, serpiente y lagartija.",
        "**Mercado del reloj**: tienda con 9 artículos e historial de transacciones.",
        "**Interfaz** con la madera, corazones, fuente pixel y cuadros de diálogo del paquete de sprites.",
        "**Modo DEMO** (animatronic): el juego se juega solo con un piloto automático.",
        "**Guardado** de monedas, récords, disfraces y partida en curso.",
        "**Ejecutable** `HoraDorada_Beta.exe` para Windows (no requiere instalar Godot).",
    ])
    d.add_heading("2.2 Motor, librerías y recursos", level=2)
    tabla(d, ["Herramienta", "Uso en el juego"], [
        ["Godot Engine 4.7.2 (MIT)", "Motor completo; scripts en GDScript; renderizador GL Compatibility (OpenGL 3.3)."],
        ["Nodos 3D de Godot", "MeshInstance3D y SurfaceTool (suelo y muros), Sprite3D (personajes y objetos), DirectionalLight3D (sol con sombras), WorldEnvironment y ProceduralSkyMaterial (cielo según la hora), Camera3D, Label3D (puntos flotantes)."],
        ["Física de Godot", "CharacterBody3D (Gno y enemigos), StaticBody3D (muros, plantas, puertas), Area3D (objetos, salida y choque con enemigos)."],
        ["AStarGrid2D", "Búsqueda de caminos: la serpiente persigue a Gno rodeando muros, la lagartija regresa a su puesto y el piloto de la demo llega a cada flor."],
        ["Tween, Theme, InputMap", "Animaciones de la interfaz y de la cámara, tema visual con texturas, acciones de teclado y control."],
        ["Ninja Adventure Asset Pack (CC0)", "Sprites, tiles, interfaz, fuente pixel, música y efectos de sonido. Descargado de la página oficial del autor."],
    ], [5, 11.5])
    d.add_heading("2.3 Requisitos de la tarea", level=2)
    p(d, "La siguiente tabla resume dónde está cada elemento que pide la actividad. Después se explica cada uno con su evidencia.")
    tabla(d, ["Requisito", "En el juego", "Archivo"], [
        ["Eventos", "Bus de eventos con 26 señales y un evento aleatorio en cada intento.", "autoload/eventos.gd, nivel.gd"],
        ["Comportamientos", "Máquinas de estados de destello, serpiente y lagartija; piloto de la demo.", "actores/*.gd, piloto.gd"],
        ["Transacciones", "Compras del Mercado del reloj e ingresos al ganar, con historial y guardado seguro.", "autoload/juego.gd, mercado.gd"],
        ["Acciones", "Caminar, saltar, estirarse, mover el sol, girar la cámara, pausa y reinicio.", "actores/gno.gd, nivel.gd"],
        ["Colisiones", "Cuerpos contra muros y plantas; áreas para objetos, salida y daño.", "mundo/mundo.gd, actores/enemigo.gd"],
        ["Puntaje", "Puntos por acción, bonos al ganar, multiplicadores, estrellas y récords.", "logica/puntaje.gd"],
        ["Oportunidades (vidas)", "3 corazones por nivel y 3 oportunidades por partida; fin del juego en 0.", "nivel.gd, juego.gd"],
    ], [3.4, 8.6, 4.5])

    d.add_heading("Eventos", level=3)
    p(d, "El juego usa un **bus de eventos** (patrón observador): quien hace algo lo anuncia y los demás reaccionan sin "
         "conocerse. Por ejemplo, cuando una flor abre, el nivel emite `flor_abierta`; el sonido toca un efecto, el HUD "
         "actualiza el contador y las pruebas automáticas lo cuentan.")
    codigo(d, """
signal flor_abierta(pos: Vector3)
signal enemigo_apagado(tipo: String, pos: Vector3)
signal jugador_golpeado(corazones: int)
signal evento_de_nivel(id: String, nombre: String, descripcion: String)
signal transaccion(registro: Dictionary)
signal nivel_ganado(resultado: Dictionary)
""")
    p(d, "Además, cada intento de un nivel trae un **evento aleatorio** que cambia la partida:")
    tabla(d, ["Evento", "Qué pasa"], [
        ["Brisa del desierto", "Pasan nubes; bajo su sombra Gno no tiene sombra."],
        ["Día veloz", "El sol avanza 60 % más rápido, pero los puntos valen ×1.5."],
        ["Lluvia de ventajas", "Aparecen 4 ventajas en lugar de 2."],
        ["Tesoro de arena", "Aparecen 3 monedas y 1 reloj de arena extra."],
        ["Enemigos inquietos", "Los enemigos van 40 % más rápido y valen el doble."],
    ], [5, 11.5])
    imagen(d, "05_nivel5_destellos.png", "Inicio del nivel 5 con el evento «Brisa del desierto» anunciado y su reto.")

    d.add_heading("Comportamientos", level=3)
    tabla(d, ["Enemigo", "Estados", "Cómo se vence"], [
        ["Destello (luz pura)", "Patrullar en línea recta; al chocar se da la vuelta.", "Cubrirlo con la sombra 0.5 s."],
        ["Serpiente", "Deambular → Perseguir (A* si Gno está a menos de 4.5 casillas) → Huir (si la sombra la toca).", "Cubrirla con la sombra 1 s en total: se esconde bajo la arena."],
        ["Lagartija guardiana", "Vigilar → Preparar (tiembla) → Embestir en línea recta → Cansada (Zz, no hace daño) → Regresar a su puesto (A*).", "Cubrirla con la sombra 0.5 s mientras está cansada."],
        ["Piloto de la demo", "Elegir la flor más cercana → calcular dónde pararse para que la sombra la toque → llegar con A* → ir al reloj de sol.", "—"],
    ], [3.5, 8.5, 4.5])
    imagen(d, "06_nivel6_serpientes_y_lagartija.png", "Nivel 6: serpientes (rojas) y la lagartija (verde) en el pasillo central.")

    d.add_heading("Transacciones", level=3)
    p(d, "Las **monedas de sol** se juntan en los niveles y se depositan al ganar. En el **Mercado del reloj** se gastan. "
         "Cada compra es una transacción completa:")
    viñetas(d, [
        "**Validar**: que el artículo exista, que alcance el saldo, que no se repita un disfraz y que no se pase del máximo (3) de un consumible.",
        "**Descontar y entregar**: resta el precio y agrega el artículo (consumible, oportunidad extra o disfraz).",
        "**Registrar**: agrega al historial el folio, la fecha, el concepto, el monto y el saldo resultante.",
        "**Guardar** en disco de forma segura (primero un archivo temporal y luego se renombra).",
        "**Revertir**: si el guardado falla, el saldo, el inventario y el historial regresan a como estaban y no se cobra nada.",
    ], "List Number")
    tabla(d, ["Artículo", "Precio", "Tipo"], [
        ["Corazón extra", "30", "Consumible (siguiente nivel)"], ["Arena extra (+30 s)", "25", "Consumible"],
        ["Escudo de luz", "20", "Consumible"], ["Sombra larga", "20", "Consumible"],
        ["Oportunidad extra", "60", "+1 intento en la partida"],
        ["Sombrero de palma · Paliacate · Flor en el pelo · Espíritu de luz", "80 · 100 · 120 · 150", "Disfraces (permanentes)"],
    ], [8, 3, 5.5])
    imagen(d, "02_mercado_transacciones.png", "Mercado del reloj con el historial de transacciones (ingreso y dos compras).")

    d.add_heading("Acciones", level=3)
    tabla(d, ["Acción", "Teclado", "Control", "Efecto"], [
        ["Caminar", "W A S D / flechas", "Palanca izq.", "Gno camina en 4 direcciones (relativas a la cámara)."],
        ["Mover el sol", "Q / E", "LB / RB", "Regresa o adelanta la hora; gasta la arena al triple."],
        ["Estirarse", "Espacio", "X", "La sombra mide 40 % más, pero no puede caminar."],
        ["Saltar", "J / Shift", "A", "Salta ~1 casilla; en el aire los enemigos no lo dañan."],
        ["Girar cámara", "Z / X", "Cruceta", "El mundo gira 90° y la sombra cae hacia otro rumbo."],
        ["Cámara alta", "C", "—", "Vista más desde arriba."],
        ["Pausa / reiniciar", "Esc, P / R", "Start", "Abre el menú de pausa o repite el nivel."],
    ], [3, 3, 2.5, 8])

    d.add_heading("Colisiones", level=3)
    tabla(d, ["Capa", "Quién", "Choca con"], [
        ["1 · Mundo", "Suelo, muros, saguaros, biznagas, rocas, flores y puertas cerradas (StaticBody3D).", "—"],
        ["2 · Jugador", "Gno (CharacterBody3D con cápsula).", "Mundo"],
        ["3 · Enemigos", "Destellos, serpientes y lagartija (CharacterBody3D con esfera).", "Mundo"],
        ["Áreas", "Monedas, cofre, relojes, ventajas, salida y zona de daño de cada enemigo (Area3D).", "Detectan al jugador (capa 2)"],
    ], [3, 9, 4.5])
    p(d, "Las puertas de madera se abren y cierran desactivando su colisión, y la cuadrícula de A* se actualiza para que "
         "los enemigos no intenten pasar por una puerta cerrada.")

    d.add_heading("Puntaje", level=3)
    tabla(d, ["Durante el nivel", "Puntos", "Al ganar", "Bono"], [
        ["Flor abierta", "+100", "Cada corazón que queda", "+100"],
        ["Destello / serpiente / lagartija", "+50 / +75 / +100", "Arena que sobra", "+5 por cada 1 %"],
        ["Moneda / cofre", "+10 / +40", "Rapidez", "+2 por segundo debajo de 180 s"],
        ["Ventaja / reloj de arena", "+50 / +30", "Reto cumplido", "+300 a +400"],
        ["Golpe de un enemigo", "−50", "Evento Día veloz", "×1.5 al total"],
    ], [5, 3, 4.5, 4])
    p(d, "Con el total se dan de **1 a 3 estrellas** según los umbrales de cada nivel, y se guarda el récord.")
    imagen(d, "09_victoria_puntaje_y_estrellas.png", "Pantalla de victoria con el desglose del puntaje y las estrellas.")

    d.add_heading("Oportunidades (vidas)", level=3)
    viñetas(d, [
        "Cada nivel empieza con **3 corazones** (4 con el corazón extra). Un golpe quita uno y Gno parpadea 1.3 s sin recibir daño.",
        "La partida empieza con **3 oportunidades**. Se pierde una si se acaban los corazones, la arena o si cae la noche.",
        "Con **0 oportunidades** aparece «Fin del juego» con el puntaje final. Se puede comprar una **oportunidad extra** en el Mercado.",
    ])
    imagen(d, "10_derrota_sin_arena.png", "Derrota por falta de arena: se pierde una oportunidad y se puede reintentar.")

    d.add_heading("2.4 Arquitectura", level=2)
    codigo(d, """
Autoloads (siempre activos)
  Eventos  -> bus de señales
  Juego    -> partida, intentos, monedas, Mercado, guardado, controles
  Sonido   -> música y efectos (escucha a Eventos)

Escenas
  menu.tscn     -> menú con el desierto 3D de fondo; DEMO tras 25 s
  nivel.tscn    -> Mundo + Gno + enemigos + sol + cámara + HUD
  mercado.tscn  -> tienda e historial

Lógica pura (se prueba sola)
  Sombras (sol, sombra, cámara) · Puntaje · Niveles (mapas de texto)
""")
    d.add_heading("2.5 Cómo ejecutarlo", level=2)
    viñetas(d, [
        "Abrir `build/HoraDorada_Beta.exe` (Windows 10/11 de 64 bits, OpenGL 3.3).",
        "O abrir `project.godot` con Godot 4.7 y presionar F5.",
        "Pruebas automáticas: `Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --pruebas`.",
    ])


def seccion_manual(d, numero="3"):
    d.add_heading("%s. Manual de usuario" % numero, level=1)
    d.add_heading("%s.1 Requisitos e instalación" % numero, level=2)
    viñetas(d, [
        "Windows 10 u 11 de 64 bits con tarjeta de video compatible con OpenGL 3.3 (cualquier equipo de los últimos 10 años).",
        "No necesita instalación: copia la carpeta y abre **HoraDorada_Beta.exe**. Si Windows muestra «Windows protegió su PC», elige *Más información → Ejecutar de todas formas* (el archivo no está firmado).",
        "Tu avance se guarda solo en `%APPDATA%\\Godot\\app_userdata\\Hora Dorada (Beta)\\partida.json`.",
    ])
    d.add_heading("%s.2 Menú principal" % numero, level=2)
    imagen(d, "01_menu_principal.png", "Menú principal: a la derecha se ven tus monedas, estrellas, niveles abiertos y disfraz.")
    tabla(d, ["Opción", "Para qué sirve"], [
        ["Continuar", "Aparece si tienes una partida en curso: sigue en el nivel donde te quedaste."],
        ["Nueva partida", "Empieza en el nivel 1 con 3 oportunidades."],
        ["Elegir nivel", "Juega cualquier nivel ya desbloqueado; muestra tus estrellas y récord."],
        ["Mercado del reloj", "Tienda donde gastas tus monedas de sol."],
        ["Ver la demo", "El juego se juega solo (también empieza si no tocas nada en 25 segundos)."],
        ["Cómo jugar / Créditos / Salir", "Ayuda rápida, autores y recursos, y cerrar el juego."],
    ], [4.5, 12])
    d.add_heading("%s.3 Objetivo y reglas" % numero, level=2)
    viñetas(d, [
        "Abre todas las **flores de luna** (moradas) tocándolas con tu **sombra** un momento. Cuando abren se vuelven blancas.",
        "Cuando abren todas, el **reloj de sol** se enciende con un círculo mágico: camina hasta él para ganar.",
        "La **arena del reloj** es tu tiempo: baja sola. Mover el sol con Q/E la gasta al triple. Al final suena una alarma.",
        "Si se acaba la arena, si se hace de noche o si pierdes los 3 corazones, pierdes una **oportunidad**.",
        "Tu sombra **pasa por encima de los muros**, aunque tú no puedas cruzarlos.",
        "Las **placas lunares** (A y B) abren su puerta mientras tu sombra las cubre.",
        "**Bajo una nube** no tienes sombra: espera a que pase.",
    ])
    d.add_heading("%s.4 La pantalla de juego (HUD)" % numero, level=2)
    imagen(d, "03_nivel1_pista_del_narrador.png", "Inicio de un nivel: el narrador da la pista y se ve el HUD completo.")
    tabla(d, ["Zona", "Qué muestra"], [
        ["Arriba a la izquierda", "Corazones, oportunidades que quedan (caritas de Gno), monedas (guardadas y del nivel) y puntaje."],
        ["Arriba al centro", "Hora del día, segundos de arena y la barra del reloj (se pone roja al final)."],
        ["Arriba a la derecha", "Nivel, flores abiertas, evento del intento, reto opcional (✔ al cumplirlo) y ventajas activas con sus segundos."],
        ["Abajo", "Recordatorio de controles y el cuadro de diálogo del narrador."],
    ], [4.5, 12])
    d.add_heading("%s.5 Controles" % numero, level=2)
    tabla(d, ["Acción", "Teclado", "Control de Xbox"], [
        ["Caminar", "W A S D o flechas", "Palanca izquierda"], ["Regresar / adelantar el sol", "Q / E", "LB / RB"],
        ["Estirarse (sombra más larga)", "Espacio", "X"], ["Saltar", "J o Shift", "A"],
        ["Girar la cámara 90°", "Z / X", "Cruceta izquierda / derecha"], ["Cámara alta", "C", "—"],
        ["Pausa", "Esc o P", "Start"], ["Reiniciar el nivel", "R", "—"], ["Pantalla completa", "F11", "—"],
    ], [6, 5, 5.5])
    d.add_heading("%s.6 Enemigos, ventajas y objetos" % numero, level=2)
    tabla(d, ["Elemento", "Qué hace", "Consejo"], [
        ["Destello", "Patrulla de un lado a otro. Si te toca pierdes un corazón.", "Cúbrelo con tu sombra medio segundo y se apaga."],
        ["Serpiente", "Deambula; si te acercas, te persigue rodeando muros.", "Tu sombra la espanta; si la cubres 1 s se esconde."],
        ["Lagartija", "Vigila; si quedas en su fila o columna, embiste muy rápido.", "Esquívala o salta. Cuando se cansa (Zz), cúbrela con tu sombra."],
        ["Moneda / cofre", "+1 / +5 monedas de sol (se guardan al ganar).", "Junta para el Mercado."],
        ["Reloj de arena", "+15 segundos de arena.", "Úsalo cuando necesites mover mucho el sol."],
        ["Ventajas", "Sombra larga, Prisa, Tiempo quieto, Salto alto, Escudo, Corazón, Doble puntos, Semilla mágica.", "Aparecen al azar en cada intento."],
    ], [3, 7.5, 6])
    d.add_heading("%s.7 Mercado del reloj" % numero, level=2)
    p(d, "Desde el menú o al terminar un nivel. Elige un artículo y presiona **Comprar**. Si no te alcanza, el juego te "
         "dice cuánto cuesta y cuánto tienes. Los **consumibles** se usan solos al empezar el siguiente nivel. Los "
         "**disfraces** se quedan para siempre: pulsa **Ponérmelo** para cambiarlo (también cambia tu sombra). A la "
         "derecha está el **historial** con cada ingreso y compra.")
    d.add_heading("%s.8 Pausa, victoria y derrota" % numero, level=2)
    viñetas(d, [
        "**Pausa (Esc)**: Continuar, Reiniciar el nivel o Salir al menú.",
        "**Victoria**: muestra el desglose de puntos, las estrellas y las monedas ganadas. Puedes seguir, ir al Mercado o repetir.",
        "**Derrota**: dice el motivo y cuántas oportunidades te quedan. Con 0 oportunidades se acaba la partida.",
    ])
    d.add_heading("%s.9 Problemas comunes" % numero, level=2)
    tabla(d, ["Problema", "Solución"], [
        ["No abre el .exe", "Revisa que Windows sea de 64 bits y actualiza el controlador de video (OpenGL 3.3)."],
        ["Se ve muy pequeño", "Presiona F11 para pantalla completa."],
        ["No se escucha", "Revisa el volumen de Windows; la música y los efectos salen por el dispositivo predeterminado."],
        ["Quiero empezar de cero", "Borra el archivo partida.json de la carpeta indicada en %s.1." % numero],
    ], [5, 11.5])


def seccion_demo(d, numero="4"):
    d.add_heading("%s. Demo (animatronic)" % numero, level=1)
    p(d, "El juego incluye un **modo DEMO** en el que Hora Dorada se juega solo, como las máquinas de exhibición. Sirve "
         "para mostrar el juego sin que nadie toque los controles (por ejemplo, en una feria o en la presentación).")
    viñetas(d, [
        "Se abre con **Ver la demo** en el menú, o solo, si nadie toca nada durante **25 segundos**.",
        "Un **piloto automático** controla a Gno: elige la flor más cercana, calcula en qué casilla pararse para que su sombra la toque a la hora actual y llega rodeando obstáculos con **A*** (`AStarGrid2D`).",
        "Cuando abren todas las flores camina al reloj de sol y gana; después regresa al menú.",
        "En la demo no se guardan monedas ni puntaje. **Cualquier tecla** la termina.",
    ])
    imagen(d, "11_modo_demo.png", "Modo DEMO: el piloto automático abrió las 4 flores del nivel 1.")


def seccion_pruebas(d, numero="5"):
    total, fallas = PRUEBAS["total"], PRUEBAS["fallas"]
    d.add_heading("%s. Reporte de pruebas de la beta" % numero, level=1)
    d.add_heading("%s.1 Objetivo y alcance" % numero, level=2)
    p(d, "Comprobar que la versión beta 0.9 cumple las reglas del GDD y los requisitos de la actividad (eventos, "
         "comportamientos, transacciones, acciones, colisiones, puntaje y oportunidades), que no truena y que corre "
         "fluido, antes de abrirla a más jugadores.")
    d.add_heading("%s.2 Entorno de prueba" % numero, level=2)
    gpu = next(iter(REND.values()), {}).get("gpu", "—") if REND else "—"
    tabla(d, ["Elemento", "Valor"], [
        ["Equipo", "PC con Windows 11 de 64 bits"], ["Tarjeta de video", gpu + " (OpenGL 3.3)"],
        ["Motor", PRUEBAS.get("godot", "Godot 4.7.2")], ["Versión del juego", PRUEBAS.get("version", "0.9.0-beta")],
        ["Fecha de las pruebas automáticas", PRUEBAS.get("fecha", "").replace("T", " ")],
    ], [6, 10.5])
    d.add_heading("%s.3 Estrategia" % numero, level=2)
    tabla(d, ["Tipo", "Cómo se hizo", "Resultado"], [
        ["Unitarias", "Funciones puras: sol y sombra, cámara, puntaje, niveles y transacciones del Mercado.", "Automáticas"],
        ["Integración", "El juego real corriendo sin ventana: la demo completa el nivel 1, choques con enemigos, sombra que apaga, monedas, muros, derrota por arena, depósito al ganar, serpientes y lagartija.", "Automáticas"],
        ["Visuales", "El juego con ventana toma 11 capturas de pantallas clave (`herramientas/capturador.gd`).", "Revisadas una por una"],
        ["Rendimiento", "Cuadros por segundo y memoria en los niveles con más enemigos.", "Medido"],
        ["Con jugadores", "Formato de la sección %s.9 para compañeros (beta abierta)." % numero, "Por aplicar"],
    ], [3, 10, 3.5])
    d.add_heading("%s.4 Resultados de las pruebas automáticas" % numero, level=2)
    p(d, "**%d pruebas, %d fallas.** Comando: `Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --pruebas`." % (total, fallas),
      color=CAFE)
    grupos = {}
    for r in PRUEBAS["resultados"]:
        grupos.setdefault(r["grupo"], [0, 0])
        grupos[r["grupo"]][0] += 1
        grupos[r["grupo"]][1] += 1 if r["ok"] else 0
    tabla(d, ["Grupo", "Pruebas", "Pasan"], [[g, v[0], v[1]] for g, v in grupos.items()], [10, 3, 3.5])
    p(d, "Detalle de cada prueba:", negrita=True)
    tabla(d, ["#", "Grupo", "Prueba", "Resultado", "Detalle"],
          [[i + 1, r["grupo"].replace("Integración: ", "Int.: "), r["prueba"], "Pasa" if r["ok"] else "FALLA", r["detalle"]]
           for i, r in enumerate(PRUEBAS["resultados"])], [0.9, 3.4, 7.2, 1.7, 3.3], tam=8.5)
    d.add_heading("%s.5 Casos de prueba funcionales" % numero, level=2)
    casos = [
        ["CP-01", "Abrir el ejecutable", "Abre el menú sin errores", "Pasa (el .exe corrió sin errores en consola)"],
        ["CP-02", "Nueva partida", "Nivel 1 con la pista del narrador y su voz", "Pasa (captura 03)"],
        ["CP-03", "Caminar con WASD y con control", "Gno camina y se anima en 4 direcciones", "Por probar con jugadores"],
        ["CP-04", "Tocar una flor con la sombra", "La flor crece, abre y suma 100", "Pasa (integración y captura 04)"],
        ["CP-05", "Mantener E / Q", "Cambia la hora y la arena baja más rápido", "Por probar con jugadores"],
        ["CP-06", "Girar la cámara (Z/X)", "El mundo gira 90° y la sombra cambia de rumbo", "Pasa (unitaria y captura 07)"],
        ["CP-07", "Chocar con un destello", "−1 corazón, −50 puntos, parpadeo", "Pasa (integración)"],
        ["CP-08", "Cubrir un destello con la sombra", "Se apaga y suma 50", "Pasa (integración)"],
        ["CP-09", "Acercarse a una serpiente", "La serpiente persigue a Gno", "Pasa (integración)"],
        ["CP-10", "Pararse en la fila de la lagartija", "Se prepara y embiste", "Pasa (integración)"],
        ["CP-11", "Tocar una moneda", "+1 moneda del nivel", "Pasa (integración)"],
        ["CP-12", "Tomar una ventaja", "Aviso, ícono con segundos y efecto", "Pasa (captura 03: escudo 10 s)"],
        ["CP-13", "Empezar un nivel (2 a 6)", "Se anuncia un evento aleatorio", "Pasa (captura 05)"],
        ["CP-14", "Quedarse sin arena", "Derrota y −1 oportunidad", "Pasa (integración y captura 10)"],
        ["CP-15", "Llegar al reloj con todas las flores", "Victoria, estrellas y monedas depositadas", "Pasa (integración y captura 09)"],
        ["CP-16", "Comprar con saldo suficiente", "Descuenta, entrega y registra", "Pasa (unitarias y captura 02)"],
        ["CP-17", "Comprar sin saldo", "Rechazo con mensaje", "Pasa (unitaria)"],
        ["CP-18", "Pausa con Esc", "Panel de pausa; Esc continúa", "Pasa (captura 08)"],
        ["CP-19", "Esperar 25 s en el menú", "Empieza la DEMO y abre todas las flores", "Pasa (integración y captura 11)"],
        ["CP-20", "Cerrar y volver a abrir", "Se conservan monedas e historial", "Pasa (unitaria de guardado)"],
        ["CP-21", "Archivo de partida dañado", "El juego no truena y empieza de cero", "Pasa (unitaria)"],
        ["CP-22", "Perder con 0 oportunidades", "Pantalla «Fin del juego» con puntaje final", "Pasa la lógica; falta verlo con jugadores"],
        ["CP-23", "Rendimiento en el nivel 6", "30 FPS o más", "Pasa (%s FPS)" % int(REND.get("nivel6", {}).get("fps", 0)) if REND else "Por medir"],
    ]
    tabla(d, ["ID", "Caso", "Resultado esperado", "Resultado obtenido"], casos, [1.4, 5, 5.3, 4.8], tam=9)
    d.add_heading("%s.6 Errores encontrados y corregidos" % numero, level=2)
    tabla(d, ["ID", "Error", "Causa", "Corrección"], [
        ["B-01", "Los paneles de la interfaz se veían partidos en dos tonos.", "El corte de 9 partes de la textura caía en el marco de su ventana interior.", "Márgenes 6/6/5/5 px para que el centro sea de un solo color."],
        ["B-02", "La arena se veía blanca a media mañana.", "Luz ambiental del cielo demasiado fuerte.", "Luz ambiental de color fijo y sol más suave."],
        ["B-03", "La sombra de Gno se dibujaba encima de él.", "La sombra se pintaba sin prueba de profundidad.", "Se activó la prueba de profundidad."],
        ["B-04", "El panel de derrota salía como una columna muy alta.", "Una etiqueta con ajuste de línea empezaba sin ancho.", "Ancho mínimo y el panel se reajusta a su contenido."],
        ["B-05", "Error en consola al apagar un enemigo.", "Se revisaba su zona de choque después de apagarla.", "El enemigo deja de actualizarse al apagarse."],
        ["B-06", "Faltaban ñ, ¡, ¿ e Í en la fuente pixel.", "La fuente del paquete no los trae.", "Se completó la fuente con `completar_fuente.py`."],
        ["B-07", "Las palabras se veían pegadas.", "El espacio de la fuente medía 1 pixel.", "Espacio de 3 pixeles."],
        ["B-08", "La lagartija podía embestir sin dirección.", "La dirección se reducía cada cuadro mientras se preparaba.", "Dirección de embestida guardada aparte."],
        ["B-09", "El historial del Mercado se salía de la pantalla.", "Las tarjetas eran demasiado anchas.", "Tarjetas más angostas y texto con ajuste de línea."],
        ["B-10", "Los enemigos se iniciaban en la esquina del mapa.", "Se configuraban antes de colocarlos.", "Primero se colocan y luego se inician."],
    ], [1.3, 4.4, 5.2, 5.6], tam=9)
    d.add_heading("%s.7 Pendientes conocidos (para la versión final)" % numero, level=2)
    viñetas(d, [
        "Niveles 7 a 17 del GDD (noche con faroles, espejos, puertas solares, mesetas y plataformas) todavía no están en Godot.",
        "No hay controles táctiles (la versión web sí los tiene).",
        "Falta un menú de opciones para el volumen (hoy se usa el de Windows).",
        "Las sombras de las plantas son solo visuales: la regla del juego usa la sombra de Gno.",
        "El ejecutable no está firmado, así que Windows puede mostrar una advertencia.",
    ])
    d.add_heading("%s.8 Rendimiento" % numero, level=2)
    if REND:
        tabla(d, ["Escena", "FPS", "Objetos dibujados", "Memoria (MB)"],
              [[k, int(v["fps"]), int(v["objetos_dibujados"]), v["memoria_mb"]] for k, v in REND.items()], [5, 3, 4.5, 4])
    p(d, "El juego se mantiene en 60 FPS (el máximo con sincronización vertical) en la tarjeta integrada del equipo de prueba.")
    d.add_heading("%s.9 Formato para jugadores de la beta" % numero, level=2)
    p(d, "Pedir a 3 a 5 compañeros que jueguen los niveles 1 a 6 sin ayuda y llenen esta tabla (1 = muy mal, 5 = excelente).")
    tabla(d, ["Pregunta", "J1", "J2", "J3", "J4", "J5"], [
        [q, "", "", "", "", ""] for q in [
            "¿Entendiste la regla de la sombra sin ayuda?", "¿Los controles se sienten cómodos?",
            "¿La dificultad sube de forma justa?", "¿Se entiende qué hace cada enemigo?",
            "¿El Mercado es fácil de usar?", "¿Te dieron ganas de repetir un nivel por las estrellas?",
            "¿Encontraste algún error? (descríbelo abajo)"]], [8, 1.7, 1.7, 1.7, 1.7, 1.7])
    p(d, "Comentarios y errores encontrados: ____________________________________________________________")
    d.add_heading("%s.10 Conclusión" % numero, level=2)
    p(d, "La beta cumple con los elementos que pide la actividad y pasó las %d pruebas automáticas sin fallas. Los diez "
         "errores que salieron durante la revisión visual y de código ya están corregidos. Lo siguiente es aplicar el "
         "formato con jugadores, corregir lo que reporten y agregar los niveles restantes del GDD." % total)


def seccion_avance(d, numero="6"):
    d.add_heading("%s. Entrega de avance (capturas)" % numero, level=1)
    capturas = [
        ("01_menu_principal.png", "Menú principal con el desierto 3D de fondo."),
        ("03_nivel1_pista_del_narrador.png", "Nivel 1: pista del narrador y HUD."),
        ("04_nivel1_sombra_abre_flor.png", "La sombra de Gno (silueta) y las sombras del sol del motor."),
        ("05_nivel5_destellos.png", "Nivel 5 con destellos y el evento del intento."),
        ("07_camara_girada_90.png", "Cámara girada 90°: la sombra cae hacia otro rumbo."),
        ("08_pausa.png", "Menú de pausa."),
    ]
    for a, t in capturas:
        imagen(d, a, t, 14.5)


def seccion_pr(d, numero="7"):
    d.add_heading("%s. Revisión de avance del equipo (PR)" % numero, level=1)
    p(d, "El trabajo se organiza en **tarjetas** (issues) y **ramas**. Cada integrante sube su rama, abre un **Pull "
         "Request (PR)** y el otro lo **revisa** (comenta y aprueba) antes de unirlo a `main`. La tabla queda lista para "
         "pegar los enlaces.")
    tabla(d, ["Integrante", "Tarjetas", "Rama", "PR (enlace)", "Revisa"], [
        [EQUIPO[0], "Núcleo del sol y la sombra; mundo 3D; Gno; nivel jugable", "feature/nucleo-sol-sombra", "____________", EQUIPO[1].split()[0]],
        [EQUIPO[1], "Enemigos y comportamientos (destello, serpiente, lagartija)", "feature/enemigos", "____________", EQUIPO[0].split()[0]],
        [EQUIPO[1], "HUD, menú, tema visual y modo DEMO", "feature/interfaz-demo", "____________", EQUIPO[0].split()[0]],
        [EQUIPO[0], "Mercado del reloj y transacciones; guardado", "feature/mercado", "____________", EQUIPO[1].split()[0]],
        [", ".join(n.split()[0] for n in EQUIPO), "Pruebas automáticas, ejecutable y documentación", "feature/pruebas-beta", "____________", "Ambos"],
    ], [3.3, 5, 3.4, 2.6, 2.2], tam=9)
    p(d, "En cada revisión se comenta: si compila, si las pruebas pasan, si el código sigue el estilo del proyecto y "
         "qué se probó en el juego.", italica=True, color=GRIS)


def seccion_video(d, numero="8"):
    d.add_heading("%s. Video o participación en clase" % numero, level=1)
    p(d, "Enlace del video: ________________________________   Fecha de participación en clase: ______________")
    p(d, "Guion sugerido (2 a 3 minutos):", negrita=True)
    viñetas(d, [
        "0:00 · Presentación del equipo y del caso práctico (Hora Dorada, GDD).",
        "0:20 · Menú y modo DEMO: el juego se juega solo.",
        "0:40 · Nivel 1: mover el sol con Q/E y abrir flores con la sombra (acciones, eventos, puntaje).",
        "1:10 · Nivel 5 y 6: destellos, serpiente y lagartija (comportamientos y colisiones); perder un corazón.",
        "1:40 · Perder por arena: se pierde una oportunidad. Ganar: desglose de puntos y estrellas.",
        "2:10 · Mercado del reloj: comprar y ver el historial (transacciones).",
        "2:30 · Pruebas automáticas (88 pasan) y cierre.",
    ], "List Number")


def seccion_creditos(d, numero="9"):
    d.add_heading("%s. Créditos" % numero, level=1)
    viñetas(d, [
        "Equipo: " + " y ".join(EQUIPO) + ".",
        "Motor: Godot Engine 4.7.2 (licencia MIT).",
        "Arte, música y efectos: Ninja Adventure Asset Pack, de Pixel-boy y AAA (CC0), descargado de pixel-boy.itch.io.",
        "Sol y fondos: OpenGameArt (CC0). Voces: generadas con Piper.",
        "Detalle archivo por archivo: `assets/CREDITOS.md` y `assets/ORIGEN.csv`.",
    ])


# ---------------------------------------------------------------- documentos

def guardar(d, nombre):
    ruta = os.path.join(DOCS, nombre)
    d.save(ruta)
    print("Listo:", ruta)


d = documento("Portafolio de evidencias")
portada(d, "HORA DORADA", "Portafolio de evidencias · Videojuego en versión beta")
indice(d)
seccion_caso(d)
seccion_beta(d)
seccion_manual(d, "3")
seccion_demo(d, "4")
seccion_pruebas(d, "5")
seccion_avance(d, "6")
seccion_pr(d, "7")
seccion_video(d, "8")
seccion_creditos(d, "9")
guardar(d, "HoraDorada_Portafolio_de_evidencias_beta.docx")

d = documento("Manual de usuario")
portada(d, "HORA DORADA", "Manual de usuario · versión beta 0.9")
indice(d)
seccion_manual(d, "1")
seccion_demo(d, "2")
seccion_creditos(d, "3")
guardar(d, "HoraDorada_Manual_de_usuario.docx")

d = documento("Reporte de pruebas beta")
portada(d, "HORA DORADA", "Reporte de pruebas de la versión beta")
indice(d)
seccion_pruebas(d, "1")
guardar(d, "HoraDorada_Reporte_de_pruebas_beta.docx")
