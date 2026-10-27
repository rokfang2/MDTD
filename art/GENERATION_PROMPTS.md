# Arte das revisões 2 e 3

Gerada com a ferramenta integrada de geração de imagens, sem CLI ou chave de API. Nenhum arquivo original foi sobrescrito.

Referência visual fornecida pelo usuário: **style_reference.png**, cópia de MainMenu_BG_PixelArt_v2.png. A arte antiga de floresta foi usada como referência de composição; a arena antiga como referência de ambiente. O protagonista conserva a folha de corrida fornecida.

| Uso | Arquivo de jogo | Prompt completo |
|---|---|---|
| Trilha | ../assets/forest_v2.png | forest_prompt.txt |
| Arena | ../assets/roots_v2.png | roots_prompt.txt |
| Guardião, inimigo, lótus e gema | ../assets/actors_v2.png | actors_prompt.txt |
| Menu | ../assets/menu_v2.png | Imagem original fornecida, sem geração |
| Druida, inimigo e lótus da revisão 3 | ../assets/actors_v3.png | cohesion_prompt.txt |

As regiões do atlas são definidas em scripts/art.gd, world.gd e boss.gd. A imagem gerada tem 1254 × 1254 pixels; os recortes foram medidos na saída real, pois o layout solicitado no prompt não foi seguido exatamente. Os elementos são separados por alpha e não foram processados para remover fundo.

As capturas para revisão ficam em ../review/captures/. Os acabamentos do chão são desenhados no mesmo lugar das colisões, para não depender de uma ilustração preservar coordenadas exatas.

Na revisão 3, o atlas novo tem 1774 × 887 pixels, com oito células e separação real das linhas em y=465. scripts/pixel_art.gd prepara a apresentação nativa e a ancora pela base opaca de cada pose. O PNG original é preservado. Druida, inimigo, lótus e guardião são apresentados em pixels inteiros de 4 px com paleta de 19 cores; o cenário continua sendo a base. A faixa quadriculada desenhada no chão foi substituída por musgo do próprio cenário.


## Revisão 4

Ferramenta integrada image_gen, modo padrão. Arquivos versionados sem alterar as artes antigas. Prompts completos:
- crossing_v4_prompt.txt → assets/crossing_v4.png (travessia das raízes).
- cordyceps_v4_prompt.txt → assets/cordyceps_v4.png (formiga Cordyceps em duas poses, batedor e voador). Referências: captura fornecida pelo usuário para anatomia; style_reference.png para estilo.
- prayer_v4_prompt.txt → assets/prayer_v4.png (druida ajoelhado, referência actors_v3.png).
- branch_v4_prompt.txt → assets/branch_v4.png (raiz com musgo para plataformas).

PixelArt prepara os recortes em grade nativa, paleta compartilhada e escala4x durante execução, preservando os PNGs originais. O conceito de guardião baixo gerado antes da referência Cordyceps foi descartado e não entrou no projeto.


## Revisão 5 — pixels menores e terreno contínuo

Ferramenta: image_gen integrada, modo padrão. Prompts completos em prayer5_prompt.txt, enemy5_prompt.txt, backdrop5_prompt.txt, terrain5_prompt.txt e soil5_prompt.txt. Arquivos finais:

| Prompt | Asset final | Uso |
|---|---|---|
| prayer5_prompt.txt | assets/prayer5_v5.png | Meio ajoelhado, um joelho erguido, mãos na espada |
| enemy5_prompt.txt | assets/enemy5_v5.png | Quatro poses de formiga e quatro de voador |
| backdrop5_prompt.txt | assets/backdrop5_v5.png | Fundo sem plataformas pintadas |
| terrain5_prompt.txt | assets/terrain5_v5.png | Raiz completa com duas terminações transparentes |
| soil5_prompt.txt | assets/soil5_v5.png | Material contínuo de solo/raízes |

Oração referência actors_v3.png; insetos referência cordyceps_v4.png e style_reference.png. Fundo/raízes usam style_reference.png. A apresentação mantém pixels2px e preserva cores, sem quantização de20cores. As artes originais e as revisões anteriores continuam no projeto.


## Revisão6 — referência literal e prancha única

Cenário: assets/menu_v2.png, cópia literal da imagem fornecida pelo usuário. Arte nova: assets/style_atlas_v6b.png (image_gen integrada, modo padrão). Prompt completo: style_atlas_v6b_prompt.txt. Referência estilística: art/style_reference.png; atlas6a usado apenas para posições e identidades. O atlas inclui20células com protagonistas, oração, lótus, gema, insetos animados, boss e terreno.

A primeira proposta assets/style_atlas_v6.png e seu prompt style_atlas_v6_prompt.txt foram rejeitados na comparação visual por acabamento fino. Só6b é consumida pelo jogo. scripts/style_atlas.gd contém os recortes reais, pois a geração não obedeceu uma grade perfeitamente regular. PNGs de origem preservados.


## Revisão7 — escolha explícita A, pixel simples

Referência: coluna esquerda de art/style_a_reference.png, selecionada pelo usuário. A coluna B não foi selecionada. Ferramenta image_gen integrada, modo padrão; sem serviço externo configurado pelo usuário.

- style_a_atlas_prompt.txt → assets/style_a_atlas.png: protagonistas, oração, lótus, gema, formigas, voadores, duas poses do chefe, plataforma e solo inicial.
- style_a_forest_prompt.txt → assets/style_a_forest.png: floresta sem plataformas, nativa320x180 na execução.
- style_a_roots_prompt.txt → assets/style_a_roots.png: solo de composição longa, nativo384x128 na execução; substituiu a repetição curta da célula19 do atlas.

scripts/style_atlas.gd documenta recortes reais e a paleta de47cores do primeiro plano. PixelArt prepara atores pequenos, com ampliação inteira4x e alpha binário. A pose de oração é normalizada para a direita antes do flip do jogador. Lançadores recebem tons magenta nos fungos superiores; mesma anatomia de formiga. scripts/terrain.gd desenha o topo exatamente no collider, sem deformação UV. Assets anteriores preservados, mas não são usados para os atores ou cenário atuais.


## Revisão7.1 — equipe de arte e plataformas completas

Artista separado criou assets/style_a_platforms_v2.png, com três silhuetas completas, e style_a_platforms_wide_v3.png, com duas variantes autorais largas. Prompts completos: style_a_platforms_v2_prompt.txt e style_a_platforms_wide_v3_prompt.txt (inclui edição dirigida). Referência exclusiva A; recortes alpha e medidas em PLATFORM_ART_SPEC.md.

Corretor integrou em terrain.gd. Revisor devolveu a primeira montagem por alongamento das raízes; entrega final utiliza as variantes largasV3 sem sobreposição ou recorte inferior. Cada plataforma tem silhueta completa convertida uma vez à grade nativa, paleta47cores e ampliação4x, mantendo topo no collider. Capturas e aceite separado em review/style_a_fix/.


## Revisão8 — artista de movimento dedicado

image_gen integrada gerou assets/motion_a_v1.png, referenciada no A aprovado e na identidade atual do druida. Prompt completo motion_a_v1_prompt.txt. Preparação por recortes reais e escala uniforme1/8 nearest em prepare_motion_a_v1.py produz assets/motion_a_native_v1.png:16células64x40, origem32,36. O renderer aplica a paleta compartilhada e escala4; não recorta cada pose por limites de alpha. Especificação e limites em MOTION_ART_SPEC.md.

Oito poses de corrida alternam pernas, três de ataque, dash, subida, queda, pouso e idle. Animação integrada e revisada em sequência real da engine; ver review/motion/TEAM_REVIEW.md e LATEST_REVIEW.md. O GIF art/motion_a_run_preview.gif é só preview da prancha; review/motion/motion_preview.gif é o registro real integrado.


## Revisão9 — madeira, membros verdes e ataque horizontal

image_gen integrada EDIT preservando o moveset: assets/motion_wood_v1.png e prayer_wood_v1.png. Prompts completos motion_wood_v1_prompt.txt e prayer_wood_v1_prompt.txt. Preparação uniforme/isolamento/nearest em prepare_motion_wood_v1.py, sem recolorir/desenhar poses por código. Assets runtime motion_wood_native_v1.png e prayer_wood_native_v1.png; contrato64x40/origem32,36/escala4 em MOTION_WOOD_SPEC.md.

O loader aplica paleta existente. Rastro horizontal por células em player.gd; madeira é parte do sprite da mão, não lâmina vetorial separada. Madeira recolhida fora do ataque e invocada durante a oração. Versão anterior preservada sem sobrescrever e no backup externo solicitado. Revisão real/aceite em review/wood/.


## Revisão10 — balanço dos braços e madeira longa

Arte nova via image_gen: motion_wood_run_v2.png e attack_wood_wide_v2c.png (tentativas anteriores preservadas), prompts completos motion_wood_run_v2_prompt.txt e attack_wood_wide_v2*_prompt.txt. Preparação reproduzível prepare_motion_wood_v2.py isola/composita desenhos gerados mantendo regiões aprovadas, sem desenhar braços/madeira por código. Runtime motion_wood_native_v2.png384x160/células96x40/pivô48,36; oração v1 apenas recebeu margem em prayer_wood_native_v2.png.

Braços editados na banda18..28, cabeça e pernas inferiores preservadas; madeira separada ligada à mão aprovada sem escalar corpo. Medidas/ROIs/limites em MOTION_WOOD_V2_SPEC.md. Revisão de sequência real e testes separados em review/wood_v2/. Não reutilizar o preview da versão anterior como evidência desta versão.

## Revisão11
Corrida/idle: MOTION_RUN_V3_SPEC.md, motion_run_v3*_prompt.txt, idle_v3_prompt.txt e prepare_motion_run_v3.py. Ataque/ações/oração: ACTIONS_V3_SPEC.md, *_v3_prompt.txt e prepare_actions_v3.py. Fontes raw preservadas nos assets; runtime usa somente folhas native_v3.

## Revisão12
Corrida: RUN_V4_SPEC.md, motion_run_v4_prompt.txt e prepare_run_v4.py. Espada: ATTACK_V5_SPEC.md, attack_v5_prompt.txt e prepare_attack_v5.py; built-in image_gen, fontes e candidato v4 preservados. Arte v5 escolhida após revisão separar material de gesto; corte atravessa o torso, mantendo ativo integral160. Cadência em MOTION_CADENCE_V4_SPEC.md.
