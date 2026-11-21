"""Completa la fuente pixel de Ninja Adventure (CC0) con los caracteres del español que le faltan:
ñ, ¡, ¿, Í, ·, ×, ✔ (se arma con piezas de la misma fuente, así conserva el estilo).

- ñ: la "n" más la tilde que se recorta de "ã" (contornos de "ã" que no están en "a").
- Í: la "I" más el acento que se recorta de "Á".
- ¡ y ¿: "!" y "?" girados 180° (rotación de 180° en un glifo compuesto).
- ·: el punto "." subido a media altura.
- × y ✔: se copian de "x" y "v" (aproximación).

Uso:  python herramientas/completar_fuente.py assets/ui/fuente.ttf
Sobrescribe el archivo (deja respaldo en fuente_original.ttf)."""
import os, shutil, sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.recordingPen import DecomposingRecordingPen

ruta = sys.argv[1]
# La fuente original del paquete se guarda en herramientas/ (fuera de assets para que no entre al juego)
respaldo = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fuente_original.ttf")
if not os.path.exists(respaldo):
    shutil.copyfile(ruta, respaldo)
f = TTFont(respaldo)
cmap = f.getBestCmap()
gs = f.getGlyphSet()
glyf = f["glyf"]
hmtx = f["hmtx"]


def nombre(c):
    return cmap[ord(c)]


def contornos(c):
    """Lista de contornos (cada uno una lista de operaciones) del glifo."""
    pen = DecomposingRecordingPen(gs)
    gs[nombre(c)].draw(pen)
    lista, actual = [], []
    for op, args in pen.value:
        actual.append((op, args))
        if op in ("closePath", "endPath"):
            lista.append(actual)
            actual = []
    return lista


def clave(contorno):
    return tuple((op, tuple(tuple(round(v) for v in p) for p in args)) for op, args in contorno)


def extra(con_acento, base):
    """Contornos que tiene el glifo con acento y no tiene la letra base (el acento)."""
    b = {clave(k) for k in contornos(base)}
    return [k for k in contornos(con_acento) if clave(k) not in b]


def dibujar(pen, lista, transform=(1, 0, 0, 1, 0, 0)):
    tp = TransformPen(pen, transform)
    for contorno in lista:
        for op, args in contorno:
            getattr(tp, op)(*args)


def limites(lista):
    xs = [p[0] for k in lista for op, args in k for p in args]
    ys = [p[1] for k in lista for op, args in k for p in args]
    return min(xs), min(ys), max(xs), max(ys)


def agregar(caracter, pen, ancho):
    nuevo = "uni%04X" % ord(caracter)
    glyf[nuevo] = pen.glyph()
    hmtx[nuevo] = (ancho, 0)
    if nuevo not in f.getGlyphOrder():
        f.setGlyphOrder(f.getGlyphOrder() + [nuevo])
    for tabla in f["cmap"].tables:
        if tabla.isUnicode():
            tabla.cmap[ord(caracter)] = nuevo


def con_acento(nuevo, base, acentuada, base_acento):
    acento = extra(acentuada, base_acento)
    cuerpo = contornos(base)
    bx0, _, bx1, _ = limites(cuerpo)
    ax0, _, ax1, _ = limites(contornos(base_acento))
    dx = ((bx0 + bx1) - (ax0 + ax1)) / 2
    pen = TTGlyphPen(None)
    dibujar(pen, cuerpo)
    dibujar(pen, acento, (1, 0, 0, 1, dx, 0))
    agregar(nuevo, pen, hmtx[nombre(base)][0])


con_acento("ñ", "n", "ã", "a")
con_acento("Í", "I", "Á", "A")

for nuevo, base in (("¡", "!"), ("¿", "?")):
    cuerpo = contornos(base)
    x0, y0, x1, y1 = limites(cuerpo)
    alto_x = limites(contornos("x"))[3]
    # Girar 180° alrededor del centro y bajar para que cuelgue como en tipografía española
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    pen = TTGlyphPen(None)
    dibujar(pen, cuerpo, (-1, 0, 0, -1, 2 * cx, 2 * cy - (y1 - alto_x)))
    agregar(nuevo, pen, hmtx[nombre(base)][0])

punto = contornos(".")
alto_x = limites(contornos("x"))[3]
pen = TTGlyphPen(None)
dibujar(pen, punto, (1, 0, 0, 1, 0, alto_x / 2 - limites(punto)[3] / 2))
agregar("·", pen, hmtx[nombre(".")][0])

for nuevo, base in (("×", "x"), ("✔", "v")):
    pen = TTGlyphPen(None)
    dibujar(pen, contornos(base))
    agregar(nuevo, pen, hmtx[nombre(base)][0])

# El espacio original mide 1 pixel de la fuente (227 unidades de 2048; la rejilla es de 9 px por em):
# se deja en 3 pixeles para que se distingan las palabras.
hmtx["space"] = (682, 0)

f["maxp"].numGlyphs = len(f.getGlyphOrder())
f.save(ruta)
nuevo = TTFont(ruta).getBestCmap()
print("Listo:", {c: ord(c) in nuevo for c in "ñÍ¡¿·×✔"})
