# Mapa de áudio — Mushrooms Deserve to Die

Entrega da ata de 27/10/2026, seção 4.1: **lista de sons por cenário e função, com referências e arquivos disponíveis**, integrada ao jogo atual. Ela segue o GDD v2 (tato/Cordyceps implementado; os demais sentidos ficam como diretriz) e as outras frentes da ata: lótus em focos de luz (2.2), memórias no cenário (2.3), regiões e ligações (3.2) e chefes (3.3).

- Catálogo usado pelo jogo: `scripts/audio_cues.gd`. Nenhum som é referenciado fora dele.
- Comportamento: `scripts/audio_director.gd`. É criado pelo `Main`, que repassa ao `World` em `world.audio`.
- Arquivos: `assets/audio/` (109 arquivos, cerca de 22 MB). Os gerados: `tools/audio_gen/`.
- Teste: `tests/audio_director.gd` (suíte `audio_director` em `tools/check_project.py`).

## 1. Regras de mixagem

| Bus | Envia para | Uso | Responsivo a |
|---|---|---|---|
| **Master** (índice 0) | — | Volume do menu (slider) e tecla **M** | Inalterado pelo diretor |
| Music | Master | Trilhas, camada de perigo/fase II, stingers | Abaixa durante avisos; passa-baixa em pausa/memória; *phaser* durante a inversão de controles |
| Ambience | Master | Ambientes por região | Abaixa durante avisos e memórias |
| Space | Master | Reverb da região (eco) | Floresta seca → raízes → **caverna** (galerias) → ninho |
| SFX | Space | Efeitos do mundo (passos, golpes, inimigos, lótus) | Recebe o eco da região |
| Telegraph | Master | **Avisos de ataque** (sem eco, sempre nítidos) | Abaixa Music/Ambience enquanto dura |
| Voice | Master | Falas silábicas (seiva, flor) | — |
| UI | Master | Menu, pausa, mapa | — |

**Leitura dos ataques (ata 4.1).** Cada aviso de ataque segue quatro regras:
1. Tem som próprio no bus Telegraph.
2. O clímax do som coincide com o golpe: o diretor desloca o início do som, então a duração variável do aviso (fase I/II) não quebra a sincronia.
3. Enquanto o aviso dura, Music e Ambience abaixam: 6 dB no chefe, 3 dB nos inimigos.
4. As trilhas de combate não usam risers, swells invertidos nem rolos de cliques, que se confundiriam com os avisos (faixa de 1–5 kHz).

## 2. Por cenário

| Região (`Level.REGIONS`) | Trilha | Camada de perigo | Ambiente | Eco (Space) | Passos |
|---|---|---|---|---|---|
| Reino Verdejante | `musica_verdejante.ogg` (Sol lídio, 80 BPM, 84 s) | `verdejante_perigo.ogg` | `amb_floresta.ogg`: vento, folhas, grilos, pássaros | floresta | musgo |
| Travessia de Raízes | `musica_fronteira.ogg` (Lá dórico, 96 BPM, 80 s) | `fronteira_perigo.ogg` | `amb_raizes.ogg`: insetos noturnos, rangidos, esporos | floresta | terra |
| Descida da Rede | Fronteira | idem | raízes | raízes | terra |
| Galerias de Seiva | `musica_rede.ogg` (Ré frígio, 60 BPM, 96 s) | `rede_perigo.ogg` | `amb_galerias.ogg`: **goteiras com eco**, filete d'água, ronco | **caverna** (abaixo de y=400); raízes no caminho alto | **úmido** (alto: terra) |
| Copas Antigas | Fronteira | idem | raízes | floresta | musgo |
| Vestíbulo do Ninho | Rede | idem | `amb_ninho.ogg`: cliques de formiga, drone, batimento | raízes; **pisos baixos (y≥600) = caverna + goteiras** | terra / **úmido** embaixo |
| Ninho do Cordyceps (arena) | `combate_cordyceps.ogg` (ré frígio dominante, 126 BPM, 61 s) | `combate_cordyceps_fase2.ogg` (fase II) | ninho | ninho | terra |
| Encontro com flor sagrada | `flor_sagrada_encontro.ogg` (Dó lídio, 72 BPM, 53 s) | — | ninho | ninho | — |
| Menu | `menu_principal_loop.ogg` (45,963 s, mesma duração do vídeo do menu) | — | — | — | — |

Em qualquer superfície, pisar sobre um galho (plataforma de raiz) troca o passo para **madeira**.

**Troca de trilha.** A troca acontece depois de 0,8 s na nova zona (histerese), com crossfade de 3,5 s. A camada de perigo tem a mesma duração da base e toca sincronizada desde o início. Ela sobe em cerca de 0,7 s quando uma formiga persegue, prepara ou ataca a até 760 px, e só desce 3 s depois que a ameaça some.

**Regiões futuras.** A ata 3.2 cita formigueiro, cemitério e caverna, ainda não implementados. Elas usam os perfis existentes: caverna e formigueiro = `galerias` + Space `caverna` + passos úmidos; cemitério = `raizes` com eco `raizes`. Basta acrescentar uma linha em `REGION_AUDIO`.

## 3. Por função

### Protagonista
| Evento no jogo | Cue | Arquivos |
|---|---|---|
| Contato de pé na corrida (poses 0/6 de 12, pela distância percorrida) | `passo_musgo` / `passo_terra` / `passo_umido` / `passo_madeira` | `passo_grama_01-04`, `passo_terra_raiz_01-03`, `passo_umido_01-04`, `passo_madeira_01-03` |
| Pulo / aterrissagem (volume pela velocidade de queda) | `pulo`, `aterrissagem`, `aterrissagem_umida` | idem |
| Lâmina brota / corte / acerto | `espinho_brota`, `ataque_espinho` (3), `golpe_acerta` (3), `golpe_pesado` (chefe) | `espinho_brota`, `ataque_espinho_01-03`, `hit_inimigo_01-03`, `hit_pesado` |
| Dash / dash recusado na dormência | `dash`, `dash_bloqueado` | `dash`, `dash_bloqueado_dormencia` |
| Esporo atinge → dormência | `esporo_impacto` + `dormencia_inicio` | idem |
| Controles invertidos / pulso evitado | `controles_invertidos` (+ *phaser* na trilha enquanto dura), `pulso_evitado` | idem |
| Calêndula (F) | `calendula_cura` | idem |
| Dano / morte | `druida_dano` (2), `druida_morte` | `druida_dano_01-02`, `druida_morte` |

### Inimigos da trilha (posicionais)
| Tipo | Aviso (Telegraph, clímax em 0,62 s = fim dos 0,65 s de aviso) | Golpe | Contínuo |
|---|---|---|---|
| Formiga batedora | `formiga_aviso` (cliques acelerando) | `formiga_ataque` | — |
| Cuspidor | `cuspidor_aviso` (inspiração borbulhante) | `cuspidor_disparo` | — |
| Mosca | `mosca_aviso` (zumbido subindo) | `mosca_mergulho` | `mosca_zumbido` (loop que segue a mosca) |
| Todos | — | `formiga_dano`, `formiga_morte` | — |

### Cordyceps (tato)
| Padrão | Aviso (clímax 1,36 s alinhado ao golpe) | Golpe |
|---|---|---|
| Raízes | `tell_raizes`: ronco + rangidos acelerando + estalo | `raizes_irrompem` |
| Esporos | `tell_esporos`: inspiração + gorgolejo + estouro | `esporos_lancados` |
| Pulso da Rede (inversão) | `tell_pulso`: varredura com trêmulo acelerando | `pulso_inversao` |
| Mandíbulas (investida) | `tell_mandibulas`: cliques acelerando + rosnado | `investida_mandibulas` |

Os sons de presença são estes:
- Entrada na arena: `cordyceps_rugido`.
- Dor a cada 3 acertos: `cordyceps_dor`.
- Fase II: `fase_dois` (no bus Telegraph) e a camada `combate_cordyceps_fase2`.
- Colapso: `chefe_colapso` e `colapso_estalo` nas poses 2, 3 e 4.
- Fim do colapso: `chefe_silencia`.
- Fragmento surgindo: `flor_surge` com a trilha `flor`.

### Flores sagradas e bênção (ata 2.1 e 4.1)
- Quando o fragmento/flor surge, a trilha **muda para `flor_sagrada_encontro`**.
- Na oração de recompensa, tocam `bencao_calendula` e a **fala da flor** (`voz_flor_01-08`), com foco "bênção" na mixagem.
- A "segunda conversa" opcional ainda não existe no jogo. Quando existir, ela reutiliza `speak("flor", texto, semente)`.

### Lótus e focos de luz (ata 2.2)
| Momento | Som |
|---|---|
| Lótus no mapa | `lotus_foco` (loop posicional; o lótus ativo soa +5 dB) |
| Ajoelhar / plantar a raiz | `lotus_plantar` |
| Oração (1,4 s) | loop `lotus_oracao`: pitch +14% e volume de −22 a −8 dB conforme o progresso |
| Salvamento (primeira ativação) | `lotus_salvo` |
| Revisitar o lótus já ativo | `lotus_reafirmado` (curto) |
| Dano interrompe | `lotus_interrompida` |
| Nascer/renascer (nova jornada, continuar, renascer) | `lotus_renascimento` (o druida nasce de um lótus, GDD §4) |

### Memórias (ata 2.3: pista reconhecível sem poluir a tela com brilho)
Cada memória não ouvida emite um loop posicional (alcance de 620 px) que segue o tema do objeto. Ao escutar, o loop some e toca `memoria_revelada`. O texto é **falado com a voz da seiva** (sílabas de `voz_seiva_01-08`, com duração proporcional ao texto e semente fixa por memória), e a trilha recua (−9 dB e passa-baixa).

| Família | Memórias | Loop |
|---|---|---|
| Seiva | roots, sap, bridge | `memoria_seiva` (bolhas + brilho de vidro) |
| Madeira | border, canopy, rings | `memoria_madeira` (rangidos + toque de madeira) |
| Sussurro | echo, threshold | `memoria_sussurro` (sussurros formânticos) |

### Interface
- Navegação e confirmação: `ui_mover`, `ui_confirmar`. Valem para os botões do menu original e das telas do jogo, e o foco automático ao abrir a tela não soa.
- Pausa: `pausa_abrir` e `pausa_fechar`, com a trilha abafada.
- Mapa: `mapa_abrir` e `mapa_fechar`.

## 4. Falas (ata 4.1: "sons de fala")
São falas por sílabas, sem palavras reais. Ficam legíveis em qualquer idioma e não exigem dublagem.
- **Voz da seiva** (memórias): grave e soprada, f0 entre 118 e 150 Hz.
- **Voz da flor** (bênção): aguda, com harmônico de sino, f0 entre 330 e 395 Hz.

A API é `audio.speak(voz, texto, semente)` e serve também para futuras flores e NPCs.

## 5. Próximo chefe associado à audição (Claviceps) — diretriz
O GDD prevê música falsa antes de ataque forte e áudio direcional mentiroso. Para não quebrar a leitura:
- **O bus Telegraph nunca mente.** Aviso verdadeiro, centrado, com clímax no golpe e acompanhado do pulsar visual sincronizado (GDD §7.3).
- A mentira fica só em Music e Ambience: tema calmo falso (como `boss_claviceps_falsa_calma` do pack v1), panorama trocado e eco em outra direção.
- A Lavanda (GDD §6) pode ser implementada como "Telegraph em destaque": abaixa Music/Ambience por alguns segundos com `set_focus`.

## 6. Referências usadas
- **Floresta e insetos:** grilos de entardecer (pulsos de 4–5 kHz em grupos de 2–3) e cigarras noturnas (ruído de 5–7,5 kHz modulado em 38 Hz).
- **Cavernas:** goteiras em calcário (pluque senoidal com queda de afinação de 45% em ~25 ms) e reverberação longa, com 3,6 s de decaimento e eco de 0,37 s.
- **Formigas:** estridulação/cliques de quitina (2–4 kHz). Cordyceps: crescimento fúngico (rangidos e estalos de casca).
- **Combate legível:** trilhas de chefes de jogos de ação 2D (Hollow Knight, Cuphead) que reservam espaço espectral para avisos. Neste projeto, a música fica em graves/médios e os avisos em 1–5 kHz.
- **Fala por sílabas:** convenção de "gibberish" com formantes (Animal Crossing, Undertale).

## 7. Como regerar ou acrescentar
```
python tools/audio_gen/build.py            # tudo (Python 3 + numpy + scipy + ffmpeg/libvorbis)
python tools/audio_gen/build.py sfx amb    # partes: sfx, amb, music
```
Para acrescentar um som:
1. Gere ou coloque o arquivo em `assets/audio/<tipo>/`.
2. Adicione o cue em `scripts/audio_cues.gd`.
3. Chame `sound.emit("cue")` no `World`, ou `audio.play("cue", posicao)` para som posicional.

O teste `audio_director` falha se algum arquivo do catálogo faltar.

## 8. Limites atuais
Os limites conhecidos desta entrega:
- **Placeholders procedurais.** O áudio é sintetizado por código: serve para validar timing, legibilidade e transições. O coro, os sussurros e as falas são os timbres mais artificiais.
- **Não verificado no motor.** A verificação foi por análise (afinação/acordes, clímax dos avisos, emendas dos loops, sincronia das camadas, loudness). Não houve audição humana nem execução no Godot neste ambiente.
- **Arquivos `.import` pendentes.** Os `.import` dos novos áudios ainda não existem: o Godot os cria na primeira importação (`Launch_Game.ps1` / `check_project.py`), e eles devem ser versionados em seguida.
- **WAVs legados.** `assets/ambience.wav`, `dash.wav`, `hit.wav`, `hurt.wav`, `lotus.wav`, `slash.wav` e `warning.wav` (gerados por `tests/generate_audio.py`) não são mais carregados, e podem ser removidos numa limpeza futura.
