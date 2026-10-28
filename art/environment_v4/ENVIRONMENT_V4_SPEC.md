# Ambiente A — candidatos V4

## Diagnóstico e direção

Capturas examinadas antes da criação: `review/large_map/captures/01_old_new_connection.png`, `04_gallery_upper.png` e `08_canopy_lower.png`, comparadas à coluna esquerda A de `art/style_a_reference.png` e ao herói aprovado em `assets/idle_native_v3.png`. A árvore próxima verde/laranja do fundo antigo tinha células visuais grandes e alto contraste, competindo com o herói de contorno4px. As raízes do solo eram arcos muito grandes, enquanto as plataformas tinham outra densidade. A correção proposta é aproximar a gramática dos agrupamentos, sem ampliar o herói nem alterar poses/moveset.

Novos rasters foram gerados/editados exclusivamente com `image_gen` integrado. Nenhum PNG foi desenhado/editado com Python ou por código. Os assets aprovados anteriores permanecem intactos. A preparação determinística NEAREST/paleta/alpha pertence ao integrador Godot. Prompts completos: `IMAGEGEN_PROMPTS.txt`. Imagens brutas, inclusive tentativas anteriores: `raw/`.

## Arquivos e preparação

| Candidato | Região | Nativo | Uso |
|---|---|---|---|
| `assets/style_a_forest_candidate_v4.png` | imagem inteira4:3 | 320 ×240 | fundo1280 ×960, extensão para câmera inferior |
| `assets/style_a_soil_candidate_v4.png` | imagem inteira2:1 | 256 ×128 | corpo opaco do solo1024 ×512, sem musgo superior embutido |
| `assets/style_a_terrain_candidate_v4.png` | atlas1448 ×1086RGBA, abaixo | por peça | plataformas completas e faixa de musgo |

Fundo usa três camadas de silhuetas púrpuras com troncos/fungos, sem árvore próxima laranja/verde. A extensão inferior preserva o panorama e continua em vegetação escura, sem linha de piso falso. Ciano/magenta aparecem discretamente. Pode-se recortar os primeiros180pixels nativos para o menu, sem comprimir240em180.

Solo mantém terra opaca roxa/marrom e rede de raízes menores conectadas. Os tons médios separam madeira/terra; não reduzir a uma massa preta. Deve ocupar toda a geometria sólida e as laterais. A faixa de musgo é independente e cobre o topo real.

## Recortes reais do atlas

Medidos em pixels da fonte final sobre alpha>=128, x,y,largura,altura; extremos finais exclusivos. A geração não seguiu células iguais: não usar coordenadas nominais do prompt.

| Peça | Rect2i fonte | Nativo | Diferença de proporção aproximada |
|---|---|---|---|
| curta | (74,134,444,157) | 50 ×16 | 10.5% |
| média | (74,343,856,154) | 100 ×16 | 12.4% |
| larga550 | (74,559,1084,125) | 140 ×16 | 0.9% |
| longa840 | (34,755,1387,117) | 210 ×16 | 10.7% |
| faixa de musgo | (74,938,988,132) | 128 ×16 | 6.9% |

Aplicar limiar alpha0.5, resize único por NEAREST para tamanho nativo, paleta47compartilhada e desenho4×NEAREST. Manter corpo16linhas completo e gutter transparente1linha após ele. Não recortar raiz inferior para encaixar em collider nem deformar continuamente o UV. Escolher largura de fonte mais próxima. A plataforma550tem desenho próprio para evitar a deformação38%da média100. Larguras maiores podem precisar avaliação específica: a passarela1000exige250nativos, aproximadamente19%mais que210, portanto julgar a captura antes de aceitar.

## Material e montagem

Musgo em verde45a61c/79c91c e poucos highlights a9e326; linha funcional superior79c91c de1texel(4worldpx), exatamente y0do collider. O topo gerado apresenta leves tufos, portanto o integrador pode manter a linha geométrica funcional já existente. Toda raiz/musgo pendente fica abaixo do collider. Madeira tem contorno escuro de1texel e2–3faixas mates, em família462031/66302b/88402c. Raízes devem permanecer conectadas à base sólida. Primeiras4peças têm caps próprios e contorno inferior inteiro; não montar caps internos ou peças sobrepostas como solução padrão.

A quinta peça é faixa horizontal sem caps para o chão contínuo. Sua borda inferior orgânica é decorativa sobre o corpo opaco do solo, evitando sugerir vazios sólidos. Não usar o recorte18do atlas antigo como musgo, pois recriaria a diferença de material.

## Repetição e limites

O gerador recebeu pedido seamless, mas não se deve assumir bordas pixel-idênticas. O integrador propôs reflexão/MIRROR em X para fundo, solo e faixa; isso preserva continuidade da amostra na borda sem pintura raster por código. A reflexão pode gerar simetrias locais e exige inspeção nas capturas. UV de solo pode ser ancorado verticalmente em y400world para o corredor visível420..850ficar dentro do tile512pixels, sem uma costuraY no quadro.

Esta entrega é inspeção de fontes raster e medição de regiões. Não é aprovação do jogo. O integrador fará as capturas reais, e o revisor separado avaliará densidade do pixel, contraste, escala das raízes, emendas, topo/collider, laterais sólidas e continuidade no fundo em câmera baixa. Herói, ações, inimigos, colisores e saves não foram alterados pelo artista.

## Correção de ruído do fundo V5

Após integração, capturas `review/art_cohesion/captures/17_trail_idle.png` e `21_arena.png` mostraram manchas roxas pequenas que a paleta47expôs no fundoV4. O revisor confirmou o problema. Uma edição dirigida por `image_gen` preservou composição e dimensão1448 ×1086, eliminando os detalhes/manchas interiores e simplificando os fungos luminosos. Entrega separada: `assets/style_a_forest_candidate_v5.png`, mesmo destino320 ×240nativo. Prompt completo: `FOREST_V5_PROMPT.txt`. Bruto: `raw/forest_flat_v5.png`. V4 permanece intacto.

O prompt pediu quatro preenchimentos roxos hexuniformes. O gerador removeu a textura pontilhada visível, mas manteve alguma variação tonal ampla; portanto a fonte não deve ser descrita como literalmente4cores. Sua quantização47e nova captura devem confirmar a ausência de manchas isoladas. Bandas amplas contíguas e ruído de1texel são fenômenos diferentes; o revisor fará a distinção no resultado real. Solo e plataformas não foram editados neste cicloV5.
