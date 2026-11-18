extends RefCounted
## Catálogo de áudio (ata 27/10/2026, 4.1). Lista por cenário e função: docs/AUDIO_MAP.md.
## Cada cue lista variações sorteadas sem repetir, bus, volume base (dB), variação de pitch (±) e
## intervalo mínimo entre repetições (s). Avisos de ataque informam o instante do clímax: o diretor
## desloca a reprodução para o clímax coincidir com o golpe, seja qual for a duração do aviso.

const ROOT = "res://assets/audio/"
const TELL_CLIMAX = 1.36
const AVISO_CLIMAX = 0.62

const CUES = {
	# Protagonista ------------------------------------------------------------------
	"passo_musgo": {"files": ["sfx/passo_grama_01.wav", "sfx/passo_grama_02.wav", "sfx/passo_grama_03.wav", "sfx/passo_grama_04.wav"], "db": -12.0, "pitch": 0.06, "gap": 0.08},
	"passo_terra": {"files": ["sfx/passo_terra_raiz_01.wav", "sfx/passo_terra_raiz_02.wav", "sfx/passo_terra_raiz_03.wav"], "db": -12.0, "pitch": 0.06, "gap": 0.08},
	"passo_umido": {"files": ["sfx/passo_umido_01.wav", "sfx/passo_umido_02.wav", "sfx/passo_umido_03.wav", "sfx/passo_umido_04.wav"], "db": -11.0, "pitch": 0.07, "gap": 0.08},
	"passo_madeira": {"files": ["sfx/passo_madeira_01.wav", "sfx/passo_madeira_02.wav", "sfx/passo_madeira_03.wav"], "db": -12.0, "pitch": 0.06, "gap": 0.08},
	"pulo": {"files": ["sfx/pulo.wav"], "db": -11.0, "pitch": 0.05, "gap": 0.05},
	"aterrissagem": {"files": ["sfx/aterrissagem.wav"], "db": -8.0, "pitch": 0.05, "gap": 0.1},
	"aterrissagem_umida": {"files": ["sfx/aterrissagem_umida.wav"], "db": -8.0, "pitch": 0.05, "gap": 0.1},
	"dash": {"files": ["sfx/dash.wav"], "db": -6.0, "pitch": 0.04},
	"dash_bloqueado": {"files": ["sfx/dash_bloqueado_dormencia.wav"], "db": -6.0, "pitch": 0.03, "gap": 0.25},
	"espinho_brota": {"files": ["sfx/espinho_brota.wav"], "db": -15.0, "pitch": 0.05},
	"ataque_espinho": {"files": ["sfx/ataque_espinho_01.wav", "sfx/ataque_espinho_02.wav", "sfx/ataque_espinho_03.wav"], "db": -6.0, "pitch": 0.04},
	"golpe_acerta": {"files": ["sfx/hit_inimigo_01.wav", "sfx/hit_inimigo_02.wav", "sfx/hit_inimigo_03.wav"], "db": -4.0, "pitch": 0.05},
	"golpe_pesado": {"files": ["sfx/hit_pesado.wav"], "db": -3.0, "pitch": 0.05},
	"druida_dano": {"files": ["sfx/druida_dano_01.wav", "sfx/druida_dano_02.wav"], "db": -4.0, "pitch": 0.04},
	"druida_morte": {"files": ["sfx/druida_morte.wav"], "db": -2.0},
	"dormencia_inicio": {"files": ["sfx/dormencia_inicio.wav"], "db": -8.0, "gap": 0.4},
	"controles_invertidos": {"files": ["sfx/controles_invertidos.wav"], "db": -6.0},
	"pulso_evitado": {"files": ["sfx/pulso_evitado.wav"], "db": -8.0},
	"calendula_cura": {"files": ["sfx/calendula_cura.wav"], "db": -6.0},
	"esporo_impacto": {"files": ["sfx/esporo_impacto.wav"], "db": -6.0, "pitch": 0.05},
	# Inimigos da trilha (avisos no bus Telegraph, sempre audíveis) --------------------
	"formiga_aviso": {"files": ["sfx/formiga_aviso.wav"], "bus": "Telegraph", "db": -7.0, "climax": AVISO_CLIMAX},
	"formiga_ataque": {"files": ["sfx/formiga_ataque_melee.wav"], "db": -6.0, "pitch": 0.05},
	"cuspidor_aviso": {"files": ["sfx/cuspidor_aviso.wav"], "bus": "Telegraph", "db": -7.0, "climax": AVISO_CLIMAX},
	"cuspidor_disparo": {"files": ["sfx/formiga_tiro_esporo.wav"], "db": -6.0, "pitch": 0.05},
	"mosca_aviso": {"files": ["sfx/mosca_aviso.wav"], "bus": "Telegraph", "db": -8.0, "climax": AVISO_CLIMAX},
	"mosca_mergulho": {"files": ["sfx/formiga_mergulho_aereo.wav"], "db": -6.0, "pitch": 0.05},
	"formiga_dano": {"files": ["sfx/formiga_dano.wav"], "db": -8.0, "pitch": 0.06},
	"formiga_morte": {"files": ["sfx/formiga_morte.wav"], "db": -6.0, "pitch": 0.04},
	# Cordyceps (tato) -----------------------------------------------------------------
	"cordyceps_rugido": {"files": ["sfx/cordyceps_rugido.wav"], "db": -4.0},
	"tell_raizes": {"files": ["sfx/tell_raizes.wav"], "bus": "Telegraph", "db": -2.0, "climax": TELL_CLIMAX},
	"tell_esporos": {"files": ["sfx/tell_esporos.wav"], "bus": "Telegraph", "db": -2.0, "climax": TELL_CLIMAX},
	"tell_pulso": {"files": ["sfx/tell_pulso.wav"], "bus": "Telegraph", "db": -3.0, "climax": TELL_CLIMAX},
	"tell_mandibulas": {"files": ["sfx/tell_mandibulas.wav"], "bus": "Telegraph", "db": -2.0, "climax": TELL_CLIMAX},
	"raizes_irrompem": {"files": ["sfx/raizes_irrompem.wav"], "db": -3.0, "pitch": 0.03},
	"esporos_lancados": {"files": ["sfx/esporos_lancados.wav"], "db": -5.0, "pitch": 0.03},
	"pulso_inversao": {"files": ["sfx/pulso_inversao.wav"], "db": -4.0},
	"investida_mandibulas": {"files": ["sfx/investida_mandibulas.wav"], "db": -3.0, "pitch": 0.03},
	"cordyceps_dor": {"files": ["sfx/cordyceps_dor.wav"], "db": -7.0, "pitch": 0.06, "gap": 0.6},
	"fase_dois": {"files": ["sfx/fase_dois.wav"], "bus": "Telegraph", "db": -3.0},
	"chefe_colapso": {"files": ["sfx/chefe_colapso.wav"], "db": -2.0},
	"colapso_estalo": {"files": ["sfx/colapso_estalo_01.wav", "sfx/colapso_estalo_02.wav", "sfx/colapso_estalo_03.wav"], "db": -5.0, "pitch": 0.04},
	"chefe_silencia": {"files": ["sfx/chefe_silencia.wav"], "bus": "Music", "db": -4.0},
	# Flores sagradas, lótus e memórias -----------------------------------------------
	"flor_surge": {"files": ["sfx/flor_sagrada_coletada.wav"], "db": -6.0},
	"bencao_calendula": {"files": ["sfx/bencao_calendula.wav"], "bus": "Music", "db": -3.0},
	"lotus_plantar": {"files": ["sfx/lotus_plantar.wav"], "db": -6.0, "pitch": 0.03},
	"lotus_interrompida": {"files": ["sfx/lotus_interrompida.wav"], "db": -8.0},
	"lotus_salvo": {"files": ["sfx/lotus_checkpoint_ativado.wav"], "db": -4.0},
	"lotus_reafirmado": {"files": ["sfx/lotus_reafirmado.wav"], "db": -7.0},
	"lotus_renascimento": {"files": ["sfx/lotus_renascimento.wav"], "db": -5.0},
	"memoria_revelada": {"files": ["sfx/memoria_revelada.wav"], "db": -6.0},
	# Interface ----------------------------------------------------------------------
	"ui_mover": {"files": ["sfx/menu_mover.wav"], "bus": "UI", "db": -4.0, "gap": 0.05},
	"ui_confirmar": {"files": ["sfx/menu_confirmar.wav"], "bus": "UI", "db": -2.0, "gap": 0.05},
	"pausa_abrir": {"files": ["sfx/pausa_abrir.wav"], "bus": "UI", "db": -4.0},
	"pausa_fechar": {"files": ["sfx/pausa_fechar.wav"], "bus": "UI", "db": -4.0},
	"mapa_abrir": {"files": ["sfx/mapa_abrir.wav"], "bus": "UI", "db": -4.0},
	"mapa_fechar": {"files": ["sfx/mapa_fechar.wav"], "bus": "UI", "db": -4.0},
}

# Trilhas em loop. "layer" toca sincronizada por cima (mesma duração): perigo na trilha, fase II no chefe.
const MUSIC = {
	"menu": {"file": "music/menu_principal_loop.ogg", "db": -3.0},
	"verdejante": {"file": "music/musica_verdejante.ogg", "layer": "music/verdejante_perigo.ogg", "db": -4.0, "layer_db": -3.0},
	"fronteira": {"file": "music/musica_fronteira.ogg", "layer": "music/fronteira_perigo.ogg", "db": -4.0, "layer_db": -3.0},
	"rede": {"file": "music/musica_rede.ogg", "layer": "music/rede_perigo.ogg", "db": -4.0, "layer_db": -3.0},
	"cordyceps": {"file": "music/combate_cordyceps.ogg", "layer": "music/combate_cordyceps_fase2.ogg", "db": -3.0, "layer_db": -2.0},
	"flor": {"file": "music/flor_sagrada_encontro.ogg", "db": -4.0},
}

const AMBIENCE = {
	"floresta": {"file": "ambience/amb_floresta.ogg", "db": -2.0},
	"raizes": {"file": "ambience/amb_raizes.ogg", "db": -2.0},
	"galerias": {"file": "ambience/amb_galerias.ogg", "db": 0.0},
	"ninho": {"file": "ambience/amb_ninho.ogg", "db": -2.0},
}

# Loops posicionais (AudioStreamPlayer2D), em WAV com loop exato (chunk smpl); range em px a partir da câmera.
const LOOPS = {
	"memoria_seiva": {"file": "loops/memoria_seiva.wav", "db": -9.0, "range": 620.0, "attenuation": 1.6},
	"memoria_madeira": {"file": "loops/memoria_madeira.wav", "db": -9.0, "range": 620.0, "attenuation": 1.6},
	"memoria_sussurro": {"file": "loops/memoria_sussurro.wav", "db": -8.0, "range": 620.0, "attenuation": 1.6},
	"lotus_foco": {"file": "loops/lotus_foco.wav", "db": -14.0, "range": 520.0, "attenuation": 1.8},
	"lotus_oracao": {"file": "loops/lotus_oracao.wav", "db": -10.0},
	"mosca_zumbido": {"file": "loops/mosca_zumbido.wav", "db": -16.0, "range": 900.0, "attenuation": 1.5},
}

const VOICES = {
	"seiva": {"files": ["voice/voz_seiva_01.wav", "voice/voz_seiva_02.wav", "voice/voz_seiva_03.wav", "voice/voz_seiva_04.wav", "voice/voz_seiva_05.wav", "voice/voz_seiva_06.wav", "voice/voz_seiva_07.wav", "voice/voz_seiva_08.wav"], "db": -5.0},
	"flor": {"files": ["voice/voz_flor_01.wav", "voice/voz_flor_02.wav", "voice/voz_flor_03.wav", "voice/voz_flor_04.wav", "voice/voz_flor_05.wav", "voice/voz_flor_06.wav", "voice/voz_flor_07.wav", "voice/voz_flor_08.wav"], "db": -6.0},
}

# Uma entrada por região de Level.REGIONS (mesma ordem): trilha, ambiente, superfície e eco.
const REGION_AUDIO = [
	{"music": "verdejante", "ambience": "floresta", "surface": "musgo", "space": "floresta"},
	{"music": "fronteira", "ambience": "raizes", "surface": "terra", "space": "floresta"},
	{"music": "fronteira", "ambience": "raizes", "surface": "terra", "space": "raizes"},
	{"music": "rede", "ambience": "galerias", "surface": "umido", "space": "caverna"},
	{"music": "fronteira", "ambience": "raizes", "surface": "musgo", "space": "floresta"},
	{"music": "rede", "ambience": "ninho", "surface": "terra", "space": "raizes"},
]

# Acústica do bus Space (reverb), interpolada ao trocar de região: eco de caverna nas galerias.
const SPACES = {
	"floresta": {"room": 0.35, "wet": 0.06, "damping": 0.7, "predelay": 10.0},
	"raizes": {"room": 0.5, "wet": 0.12, "damping": 0.55, "predelay": 25.0},
	"caverna": {"room": 0.85, "wet": 0.32, "damping": 0.35, "predelay": 70.0},
	"ninho": {"room": 0.7, "wet": 0.2, "damping": 0.45, "predelay": 45.0},
}

# Sinal sonoro de cada memória, conforme o objeto/tema do texto (ata 2.3: pista sem poluir a tela).
const MEMORY_LOOP = {
	"roots": "memoria_seiva", "sap": "memoria_seiva", "bridge": "memoria_seiva",
	"border": "memoria_madeira", "canopy": "memoria_madeira", "rings": "memoria_madeira",
	"echo": "memoria_sussurro", "threshold": "memoria_sussurro",
}

const ENEMY_SOUNDS = {
	"scout": {"tell": "formiga_aviso", "strike": "formiga_ataque"},
	"spitter": {"tell": "cuspidor_aviso", "strike": "cuspidor_disparo"},
	"fly": {"tell": "mosca_aviso", "strike": "mosca_mergulho"},
}

const BOSS_TELLS = ["tell_raizes", "tell_esporos", "tell_pulso", "tell_mandibulas"]
const BOSS_STRIKES = {"roots": "raizes_irrompem", "spores": "esporos_lancados", "invert": "pulso_inversao", "charge": "investida_mandibulas"}

# Nomes antigos emitidos por world.sound (contrato anterior) -> cues novos.
const LEGACY = {"hurt": "druida_dano", "dash": "dash", "slash": "ataque_espinho", "hit": "golpe_acerta", "lotus": "lotus_salvo", "warning": "fase_dois"}
