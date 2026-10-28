# Plataformas de raízes A v2

Atlas raster gerado por `image_gen` integrado, fundo alpha real. Referência exclusiva: coluna esquerda **A — PIXEL SIMPLES** de `style_a_reference.png`. Capturas examinadas antes da geração: `02_trail.png` e `13_upper_route.png`. O arquivo fonte permanece integral em `assets/style_a_platforms_v2.png` (1254 × 1254 RGBA). Não substituir por desenho vetorial.

## Recortes reais

Coordenadas x,y,largura,altura em pixels da fonte, medidas sobre alpha >=128, limite final exclusivo. Não usar o layout nominal do prompt: a geração não seguiu aquelas células.

| Peça | Rect2i fonte | Tamanho nativo recomendado |
|---|---|---|
| curta | (47,280,622,197) | 50 × 16 |
| média | (47,617,950,196) | 76 × 16 |
| longa | (25,952,1199,189) | 100 × 16 |

Os recortes incluem o contorno inferior inteiro, raízes curvas e pontas pendentes naturais. O atlas contém pequenas franjas de alpha parcial exteriores; usar limiar alpha >=0.5 antes de conversão nativa. Converter cada recorte uma única vez para resolução nativa por NEAREST e mapear à paleta existente de47cores por `StyleAtlas.simplify`. Apresentação4× NEAREST: altura64pixels no jogo, sem escala vertical posterior. Sem mipmaps ou filtragem linear.

## Montagem recomendada

Para larguras arbitrárias, preparar longa100 ×16 com cap esquerdo8 ×16, interior84 ×16 e cap direito8 ×16. Sempre preservar altura16 inteira de cada parte. Os caps mantêm as terminações curvas reais; não recortar uma plataforma acabada em retângulo na largura final. O centro do atlas é sugestão de trecho repetível, não tile garantidamente contínuo pelo gerador; o integrador deve escolher uma junção de material compatível e validar as emendas em captura. Preferir sobreposição de1–2colunas internas de raiz/musgo a uma emenda vertical exposta, sem encobrir as pontas dos caps.

No chão, reutilizar a faixa de musgo desta arte como borda decorativa sobre o solo contínuo existente, sem prolongar pontas como blocos soltos. Interior do solo usa massas maiores, mas evitar textura de alta frequência entre os atores e a borda. A geração é deliberadamente rasa para não colidir visualmente com o degrau seguinte76pixels abaixo.

## Topo e collider

O topo funcional é y0 em resolução nativa. Há arredondamento de1–3colunas nas extremidades da fonte e leve irregularidade no primeiro pixel de musgo. Fixar a linha superior funcional com a borda horizontal lima já usada no jogo e desenhar o corpo completo imediatamente abaixo, mantendo os caps sob a borda. Não elevar musgo acima do collider nem deslocar a colisão para os pixels pendentes. Toda a camada de raízes abaixo do topo é decorativa. O integrador deve confirmar cobertura do topo de ponta a ponta em capturas das plataformas curtas e longas.

## Limites e validação

Inspeção da arte fonte: três silhuetas conectadas, raízes afuniladas, caps completos e alpha exterior; nenhum limite retangular inferior. O raster fonte tem detalhes mais finos do que a resolução final: a conversão nativa e paleta compartilhada são obrigatórias para o estilo A. Arte fonte não certifica montagem, emenda, collider ou aprovação visual do jogo; estes exigem nova captura da engine após integração. Não houve alteração de scripts pelo artista.

## Ciclo2: plataformas largas autorais V3

`assets/style_a_platforms_wide_v3.png` é atlas RGBA2172 ×724 com duas silhuetas completas novas. Gerado com `image_gen` e uma edição dirigida após medir a primeira tentativa. Prompt e instrução de edição preservados em `art/style_a_platforms_wide_v3_prompt.txt`. Foram inspecionadas também as capturas corrigidas `review/style_a_fix/captures/02_trail.png` e `13_upper_route.png`, nas quais transformar a fonte longaV2 em210 ×16 alongava os motivos horizontalmente. V3 desenha MAIS raízes curtas para preencher a largura, sem reutilizar uma raiz horizontalmente esticada.

| Peça V3 | Recorte real alpha>=128 | Aspecto fonte | Nativo |
|---|---|---|---|
| larga560 | (108,128,1598,170) | 9.400:1 | 140 ×16 (8.750:1) |
| larga840 | (27,427,2118,159) | 13.321:1 | 210 ×16 (13.125:1) |

A fonte larga840 já corresponde à proporção final dentro de1.5%; larga560 difere7%. Usar larga560 para plataforma550pixels e larga840 para750/840pixels. Converter inteira para resolução nativa final e aplicar paleta47. Cada sprite tem caps próprios, sequências de raízes variadas, nenhuma emenda interna e contorno inferior inteiro. Não montar V3 por caps, repetir tiles nem sobrepor peças. Plataformas menores continuam usando as fontes completasV2, conforme escolha do integrador.

V3 foi examinada como fonte raster e os recortes medidos sobre alpha. Integração e aprovação pertencem ao ciclo de capturas e revisão independente, não à simples existência do atlas.
