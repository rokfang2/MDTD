#!/usr/bin/env python3
"""Gera todo o áudio do jogo em assets/audio/ (determinístico: sementes fixas).

Requisitos: Python 3 + numpy + scipy + ffmpeg (libvorbis). Não é necessário para jogar.
    python tools/audio_gen/build.py            # tudo
    python tools/audio_gen/build.py sfx amb    # partes: sfx, amb, music
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DEST = os.path.join(ROOT, "assets", "audio")
sys.path.insert(0, HERE)
from engine import to_ogg  # noqa: E402

# Pack v1 (efeitos já entregues) -> nomes usados pelo catálogo do jogo (scripts/audio_cues.gd)
REUSE = {
    "01_protagonista": ["passo_grama_01", "passo_grama_02", "passo_grama_03", "passo_grama_04", "passo_terra_raiz_01",
                        "passo_terra_raiz_02", "passo_terra_raiz_03", "pulo", "aterrissagem", "dash", "dash_bloqueado_dormencia",
                        "ataque_espinho_01", "ataque_espinho_02", "ataque_espinho_03", "espinho_brota", "hit_inimigo_01",
                        "hit_inimigo_02", "hit_inimigo_03", "hit_pesado", "druida_dano_01", "druida_dano_02", "druida_morte"],
    "02_inimigos_formiga_cordyceps": ["formiga_ataque_melee", "formiga_tiro_esporo", "formiga_mergulho_aereo", "formiga_dano", "formiga_morte"],
    "04_mundo_itens": ["flor_sagrada_coletada", "lotus_checkpoint_ativado", "lotus_renascimento"],
    "05_ui": ["menu_mover", "menu_confirmar"],
}
RENAME = {"03_bosses/boss_azurescens_rugido": "cordyceps_rugido"}
MUSIC = [
    ("compose_menu.py", [], "menu_principal_loop"),
    ("compose_reino.py", [], "musica_verdejante"), ("compose_reino.py", ["--perigo"], "verdejante_perigo"),
    ("compose_fronteira.py", [], "musica_fronteira"), ("compose_fronteira.py", ["--perigo"], "fronteira_perigo"),
    ("compose_rede.py", [], "musica_rede"), ("compose_rede.py", ["--perigo"], "rede_perigo"),
    ("compose_cordyceps.py", [], "combate_cordyceps"), ("compose_cordyceps.py", ["--fase2"], "combate_cordyceps_fase2"),
    ("compose_flor.py", [], "flor_sagrada_encontro"),
]


def run(script, args):
    print(">>", script, " ".join(args), flush=True)
    subprocess.run([sys.executable, os.path.join(HERE, script)] + args, cwd=HERE, check=True)


def main(parts):
    tmp = tempfile.mkdtemp(prefix="mdtd-audio-")
    for sub in ("sfx", "music", "ambience", "loops", "voice"):
        os.makedirs(os.path.join(DEST, sub), exist_ok=True)
    if "sfx" in parts:
        v1 = os.path.join(tmp, "v1")
        run("sfx_pack_v1.py", [v1])
        for folder, names in REUSE.items():
            for name in names:
                shutil.copy2(os.path.join(v1, folder, name + ".wav"), os.path.join(DEST, "sfx", name + ".wav"))
        for src, name in RENAME.items():
            shutil.copy2(os.path.join(v1, src + ".wav"), os.path.join(DEST, "sfx", name + ".wav"))
        run("sfx_ata.py", [os.path.join(DEST, "sfx"), os.path.join(DEST, "voice")])
    if "amb" in parts:
        run("ambience.py", [os.path.join(DEST, "ambience"), os.path.join(DEST, "loops"), os.path.join(tmp, "amb")])
    if "music" in parts:
        for script, args, name in MUSIC:
            wav = os.path.join(tmp, name + ".wav")
            run(script, [wav] + args)
            to_ogg(wav, os.path.join(DEST, "music", name + ".ogg"), quality=5)
    shutil.rmtree(tmp, ignore_errors=True)
    print("OK:", DEST)


if __name__ == "__main__":
    main(set(sys.argv[1:]) or {"sfx", "amb", "music"})
