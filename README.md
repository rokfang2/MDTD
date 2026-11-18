# Mushrooms Deserve to Die (MDTD)

Projeto editável de um jogo de ação e exploração 2D, desenvolvido em **Godot 4.7.2**, com GDScript e renderização Compatibility.

A versão atual contém uma fase com rotas altas/baixas, quatro lótus de checkpoint, oito memórias e o primeiro chefe, Cordyceps. A derrota do chefe tem seis poses de colapso e restos persistentes. O estilo visual escolhido é Pixel Simples. Há um dos cinco confrontos previstos no GDD; os demais chefes e finais ainda não estão implementados.

O áudio é responsivo ao jogo (ata de 27/10/2026), com estes elementos:
- trilha e ambiente por região, com crossfade e eco de caverna nas galerias (goteiras e passos úmidos);
- camada de perigo sincronizada quando inimigos perseguem;
- trilha de combate do Cordyceps com camada de fase II;
- avisos de ataque com som próprio, alinhados ao golpe, que abaixam a trilha para preservar a leitura;
- lótus que soa no mapa e canto de oração que acompanha o progresso;
- memórias como pistas sonoras, faladas com a "voz da seiva";
- música e fala da flor sagrada na bênção.

Lista por cenário e função: `docs/AUDIO_MAP.md`.

## Abrir e jogar

1. Instale o Godot 4.7.2 e importe o arquivo `project.godot` deste repositório.
2. Aguarde a importação automática dos recursos e pressione **F5**.
3. No menu original animado, escolha **Start Game** para uma nova jornada ou **Continue**, se houver progresso local.

No Windows, também é possível dar dois cliques em `jogar.cmd`. Na primeira vez, o atalho procura o Godot 4.7 na Área de Trabalho, em Documentos, Downloads, OneDrive e Arquivos de Programas, e memoriza o caminho para as próximas. Se o Godot estiver em outro lugar, defina uma vez a variável de ambiente `GODOT_BIN` num terminal: `setx GODOT_BIN "C:\caminho\Godot.exe"`.

O repositório contém os recursos usados pelo projeto; a pasta `.godot/` é recriada pela engine. Não inclui executável exportado, saves pessoais, backups nem capturas/logs de desenvolvimento.

## Controles

| Tecla | Ação |
|---|---|
| A/D ou setas | Mover |
| Espaço/W/seta para cima | Pular; soltar reduz a altura |
| Shift/K | Dash |
| J/X/clique esquerdo | Golpe horizontal de madeira |
| S/seta para baixo | Agachar parado |
| S+Espaço | Descer de uma plataforma suspensa |
| E | Interagir; ajoelhar e orar para salvar no lótus |
| Tab | Mapa |
| Esc | Pausa |
| M | Áudio |
| F | Calêndula, após obtê-la |

A oração acontece na posição do personagem; dano a interrompe. Memórias entram no save na próxima oração. A recompensa do chefe também exige oração. **Start Game** começa uma nova jornada; uma gravação posterior substitui o progresso local anterior.

## Organização

| Pasta / arquivo | O que tem |
|---|---|
| `scenes/` | Cenas do Godot: `main.tscn` (cena principal do jogo) e `main_menu.tscn` (menu original) |
| `scripts/` | Código do jogo: jogador, mundo, chefe, mapa, terreno, HUD, save e áudio (`audio_director.gd` e o catálogo `audio_cues.gd`) |
| `assets/` | Tudo o que o jogo carrega: sprites, sons, fontes e texturas |
| `assets/audio/` | Efeitos e falas (`sfx/`, `voice/`), músicas (`music/`), ambientes (`ambience/`) e loops (`loops/`) |
| `assets/fonts/`, `assets/textures/` | Fontes e imagens de fundo do menu original |
| `art/` | Arte de origem, que o jogo não carrega: referência do estilo, especificações de animação e prompts de geração |
| `art/flowers/` | Arte conceitual e folha de sprites de cada flor sagrada (2048 px) |
| `docs/gdd/` | Game Design Document v2 (narrativa, mundo, chefes, flores e finais) |
| `docs/AUDIO_MAP.md` | Sons por cenário e função, regras de mixagem e diretrizes para os próximos chefes |
| `docs/review/` | Guia e relatórios das revisões de qualidade |
| `tests/` | Suítes de teste que rodam dentro do Godot |
| `tools/` | Ferramentas do grupo, fora do jogo: `check_project.py` (roda os testes numa cópia isolada) e `audio_gen/` (gera o áudio) |
| `docs/AGENTS.md` | Regras e decisões técnicas seguidas pelos agentes de IA (ver abaixo) |
| `jogar.cmd` | Atalho para jogar no Windows (chama `tools/launch_game.ps1`) |

Pastas e arquivos usam nomes em minúsculas, com `_` no lugar de espaços.

## Como o projeto foi feito

Projeto do grupo **Mushrooms Deserve to Die**, para a disciplina de Desenvolvimento de Jogos (2º semestre, noturno).

**Feito pelo grupo:** GDD, narrativa, mundo e chefes; menu original; decisões de design e direção de arte; playtests.

### Ferramentas auxiliares

- **Godot 4.7.2 e GDScript:** motor e linguagem do jogo.
- **Python 3:** ferramentas em `tools/` (testes automatizados e geração de áudio, que usa numpy, scipy e ffmpeg).
- **Git, GitHub e VS Code:** versionamento e trabalho em grupo.
- **IA generativa, como apoio e não como base,** sempre sob direção e revisão do grupo:
  - **Código e testes:** parte dos scripts em GDScript e dos testes foi escrita com agentes de programação (Codex e Claude Code). As regras que eles seguiam estão em `docs/AGENTS.md`.
  - **Arte:** sprites e cenários foram gerados com ferramentas de imagem (ChatGPT e Gemini) a partir dos prompts em `art/`, e depois selecionados e ajustados pelo grupo.
  - **Áudio:** os sons e as músicas são sintetizados por código, com os scripts em `tools/audio_gen/`.

As decisões de jogo, a escolha do estilo e a aprovação final de cada mudança estão sob responsabilidade integral do grupo.

## Observações

### Reorganização do repositório (novembro de 2026)

O jogo não mudou: a reorganização só alterou nomes e lugares de arquivos, e os 585 testes automatizados continuam passando. O que mudou para quem já tinha uma cópia:

| Antes | Agora |
|---|---|
| `Scenes/` | `scenes/` |
| `Fonts/`, `Textures/` | `assets/fonts/`, `assets/textures/` (arquivos renomeados sem espaços, ex.: `green_nature.ttf`) |
| `icon.svg` | `assets/icon.svg` |
| `pixel art/` | `art/flowers/` (arquivos sem espaços, ex.: `calendula_sprites.jfif`) |
| `review/` | `docs/review/` |
| `AGENTS.md` | `docs/AGENTS.md` |
| `tests/generate_audio.py` | `tools/generate_audio.py` |
| `Jogar.cmd`, `Launch_Game.ps1`, `Abrir_no_Godot.cmd` | Só `jogar.cmd` na raiz; o launcher foi para `tools/launch_game.ps1`. Para editar, importe o `project.godot` no Godot |

Outras mudanças:
- A folha de sprites da Coroa-de-Cristo, que estava quebrada (2 bytes), foi recuperada do histórico.
- O GDD v2 foi adicionado em `docs/gdd/`.
- Os `.import` do áudio passaram a ser versionados, e o `.gitignore` agora ignora executáveis (`.exe`, `.apk`) e `export_presets.cfg`.

**Atenção:** trabalhos em andamento que usem os caminhos antigos (`res://Scenes/...`, `res://Fonts/...`, `res://Textures/...`) precisam ser atualizados antes de juntar com esta versão. Quem usa o Codex deve apontá-lo para `docs/AGENTS.md`, que não está mais na raiz.

### Atualizações anteriores

O menu original do repositório (fundo em movimento, fontes e composição) foi preservado e integrado à versão jogável; **Start Game** e **Continue** iniciam a jornada atual.
