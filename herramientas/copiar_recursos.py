"""Copia al proyecto de Godot solo los recursos que usa la beta de Hora Dorada.

Origen:
  1) hora-dorada/assets  (lo que ya usaba la versión web; ya viene renombrado al español)
  2) el paquete "Ninja Adventure - Asset Pack" (Pixel-boy y AAA, CC0) descargado de
     https://pixel-boy.itch.io/ninja-adventure-asset-pack

Uso:  python herramientas/copiar_recursos.py "<carpeta del paquete Ninja Adventure>"
Escribe assets/ORIGEN.csv con cada archivo copiado y su origen (para los créditos)."""
import csv, os, shutil, sys

AQUI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(os.path.dirname(AQUI), "hora-dorada", "assets")
PACK = sys.argv[1] if len(sys.argv) > 1 else ""
DEST = os.path.join(AQUI, "assets")

# destino -> (origen base, ruta relativa)
DE_WEB = {
    "sprites/tiles/suelo.png": "sprites/tiles/suelo.png",
    "sprites/tiles/detalles_suelo.png": "sprites/tiles/detalles_suelo.png",
    "sprites/tiles/naturaleza.png": "sprites/tiles/naturaleza.png",
    "sprites/tiles/desierto.png": "sprites/tiles/desierto.png",
    "sprites/tiles/relieve.png": "sprites/tiles/relieve.png",
    "sprites/tiles/elementos.png": "sprites/tiles/elementos.png",
    "sprites/tiles/mazmorra.png": "sprites/tiles/mazmorra.png",
    "sprites/tiles/logica.png": "sprites/tiles/logica.png",
    "sprites/monstruos/destello.png": "sprites/monstruos/espiritu.png",
    "sprites/objetos/flor.png": "sprites/objetos/flor_animada.png",
    "sprites/objetos/reloj_arena.png": "sprites/objetos/reloj_arena.png",
    "sprites/objetos/nube.png": "sprites/objetos/nube.png",
    "sprites/fx/circulo.png": "sprites/fx/circulo_naranja.png",
    "sprites/fx/chispa_magica.png": "sprites/fx/chispa_magica.png",
    "sprites/fx/chispa.png": "sprites/fx/chispa.png",
    "sprites/fx/humo.png": "sprites/fx/humo.png",
    "sprites/ui/sol.png": "sprites/ui/sol.png",
    "sprites/ui/luna.png": "sprites/ui/luna.png",
    "sprites/personajes/sombra_pies.png": "sprites/personajes/sombra.png",
    "sprites/personajes/estatua_cara.png": "sprites/personajes/estatua_cara.png",
    "sprites/fondos/montanas_lejos.png": "sprites/fondos/far-mountains.png",
    "sprites/fondos/desierto_lejos.png": "sprites/fondos/nowater-far.png",
    "sprites/fondos/desierto_medio.png": "sprites/fondos/nowater-mid.png",
    "sprites/fondos/desierto_cerca.png": "sprites/fondos/nowater-close.png",
}
for p in ("flam", "samurai", "ninjared", "princess", "spirit"):
    for a in ("walk", "idle", "item", "dead", "jump", "cara"):
        DE_WEB["sprites/personajes/%s_%s.png" % (p, a)] = "sprites/personajes/%s_%s.png" % (p, a)
for v in ("sombraLarga", "prisa", "solQuieto", "saltoAlto", "escudo", "corazon", "doblePuntos", "florRapida"):
    DE_WEB["sprites/ventajas/%s.png" % v] = "sprites/ventajas/%s.png" % v
for s in ("crece", "flor", "todas", "placa", "placa_off", "puerta", "destello", "danio", "ganar", "perder",
          "clic", "reloj", "sin_arena", "estirar", "saltar", "aterrizar", "girar", "ventaja"):
    DE_WEB["audio/sfx/%s.wav" % s] = "audio/sfx/%s.wav" % s
for v in ("hola", "gano", "gano3", "perdio", "controles", "nivel2", "nivel3", "nivel4", "nivel5"):
    DE_WEB["audio/voz/%s.mp3" % v] = "audio/voz/lineas/%s.mp3" % v

DE_PACK = {
    # Nuevos enemigos (comportamientos)
    "sprites/monstruos/serpiente.png": "Actor/Monster/Snake/Snake.png",
    "sprites/monstruos/serpiente_cara.png": "Actor/Monster/Snake/Faceset.png",
    "sprites/monstruos/lagartija.png": "Actor/Monster/Lizard/Lizard.png",
    "sprites/monstruos/lagartija_cara.png": "Actor/Monster/Lizard/Faceset.png",
    # Monedas, cofre y tienda
    "sprites/objetos/moneda.png": "Items/Treasure/GoldCoin.png",
    "sprites/objetos/monedas_giro.png": "Items/Treasure/Coin2.png",
    "sprites/objetos/cofre.png": "Items/Treasure/LittleTreasureChest.png",
    "sprites/objetos/bolsa.png": "Ui/Receptacle/Receptacle Rectangle/BackgroundBag.png",
    # Interfaz (tema de madera del paquete) y fuente pixel
    "ui/fuente.ttf": "Ui/Font/NormalFont.ttf",
    "ui/panel.png": "Ui/Theme/Theme Wood/nine_path_panel.png",
    "ui/panel_2.png": "Ui/Theme/Theme Wood/nine_path_panel_2.png",
    "ui/panel_interior.png": "Ui/Theme/Theme Wood/nine_path_panel_interior.png",
    "ui/fondo.png": "Ui/Theme/Theme Wood/nine_path_bg.png",
    "ui/foco.png": "Ui/Theme/Theme Wood/nine_path_focus.png",
    "ui/boton.png": "Ui/Theme/Theme Wood/button_normal.png",
    "ui/boton_hover.png": "Ui/Theme/Theme Wood/button_hover.png",
    "ui/boton_pressed.png": "Ui/Theme/Theme Wood/button_pressed.png",
    "ui/boton_disabled.png": "Ui/Theme/Theme Wood/button_disabled.png",
    "ui/barra.png": "Ui/Theme/Theme Wood/slider_progress.png",
    "ui/celda.png": "Ui/Theme/Theme Wood/inventory_cell.png",
    "ui/corazones.png": "Ui/Receptacle/Heart.png",
    "ui/dialogo.png": "Ui/Dialog/DialogBoxFaceset.png",
    "ui/marco_cara.png": "Ui/Dialog/FacesetBox.png",
    # Efectos visuales
    "sprites/fx/escudo.png": "FX/Magic/Shield/SpriteSheetYellow.png",
    "sprites/fx/humo_circular.png": "FX/Smoke/SmokeCircular/SpriteSheet.png",
    # Música (OGG originales)
    "audio/musica/titulo.ogg": "Audio/Musics/1 - Adventure Begin.ogg",
    "audio/musica/dia.ogg": "Audio/Musics/31 - Sunny.ogg",
    "audio/musica/tranquila.ogg": "Audio/Musics/5 - Peaceful.ogg",
    "audio/musica/tienda.ogg": "Audio/Musics/20 - Good Time.ogg",
    "audio/musica/tension.ogg": "Audio/Musics/28 - Tension.ogg",
    "audio/musica/final.ogg": "Audio/Musics/8 - End Theme.ogg",
    # Efectos nuevos
    "audio/sfx/moneda.wav": "Audio/Sounds/Bonus/Coin2.wav",
    "audio/sfx/compra.wav": "Audio/Sounds/Bonus/Gold1.wav",
    "audio/sfx/rechazo.wav": "Audio/Sounds/Alert/Alert2.wav",
    "audio/sfx/cofre.wav": "Audio/Sounds/Bonus/Bonus2.wav",
    "audio/sfx/serpiente.wav": "Audio/Sounds/Creature/Dog.wav",
    "audio/sfx/embestida.wav": "Audio/Sounds/Whoosh & Slash/Whoosh2.wav",
    "audio/sfx/evento.wav": "Audio/Jingles/Secret1.wav",
    "audio/sfx/game_over.wav": "Audio/Jingles/GameOver3.wav",
    "audio/sfx/navegar.wav": "Audio/Sounds/Menu/Move1.wav",
}


def copiar(base, rel, dest_rel, filas, fuente):
    src = os.path.join(base, *rel.split("/"))
    if not os.path.isfile(src):
        print("FALTA", fuente, rel)
        return
    dst = os.path.join(DEST, *dest_rel.split("/"))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    filas.append((dest_rel, fuente, rel))


filas = []
for d, r in DE_WEB.items():
    copiar(WEB, r, d, filas, "hora-dorada (web)")
if PACK:
    for d, r in DE_PACK.items():
        copiar(PACK, r, d, filas, "Ninja Adventure (CC0)")
    shutil.copyfile(os.path.join(PACK, "LICENSE.txt"), os.path.join(DEST, "LICENCIA_NinjaAdventure_CC0.txt"))
with open(os.path.join(DEST, "ORIGEN.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["archivo_en_el_juego", "fuente", "archivo_original"])
    w.writerows(filas)
print("Copiados:", len(filas))
