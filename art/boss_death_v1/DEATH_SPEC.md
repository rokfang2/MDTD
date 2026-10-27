# Cordyceps — derrota visual V1

Fonte: `assets/cordyceps_death_sheet_v1.png`, RGBA1536 ×1024. Gerada por `image_gen` integrado, sem edição raster por código ou Python. Prompts e bruto preservados nesta pasta. Referências examinadas: `style_a_atlas.png`, chefe inferior esquerdo; `review/art_cohesion/captures/21_arena.png`; coluna esquerda A de `art/style_a_reference.png` e contrato de `PixelArt.guardian`.

## Seis poses

Ordem: três colunas na primeira linha, depois três na segunda. Todas orientadas para ESQUERDA, como o chefe atual. Olho ciano, carapaça marrom arredondada, musgo verde no tórax e três Cordyceps laranja. A derrota muda a postura: não apenas troca de cor ou fade.

| Índice | Conteúdo | Bounds reais alpha>=128 na fonte |
|---|---|---|
| 0 | impacto/recuo, cabeça e patas dianteiras erguidas | (91,179,399,394) |
| 1 | patas dobrando, tórax desce | (577,257,395,316) |
| 2 | inseto ajoelhado, cabeça baixa e abdômen perto do chão | (1068,351,418,226) |
| 3 | queda sobre a frente/flanco, cabeça no chão, abdômen inclinado | (91,717,414,228) |
| 4 | corpo deitado, pernas dobradas, olho apagando e fungos pendentes | (556,796,456,150) |
| 5 | restos reconhecíveis com fungos apagados e micélio conectado | (1065,814,434,143) |

Os bounds servem para inspeção, NÃO para redimensionar cada pose individualmente. O corpo foi gerado na mesma escala; aplicar fator uniforme1/5a todos. Larguras nativas aproximadas80/79/84/83/91/87. A primeira pose ergue o tórax e tem altura79nativa, maior que os67nativos do idle, por postura. Não aumentar nem encolher o abdômen para compensar a altura do recuo.

## Preparação determinística pelo integrador

Canvas comum112 ×96nativo, pivô(56,88), ampliação4×NEAREST. A altura96acomoda o recuo e margem; o corpo permanece80nativos de largura na primeira pose, como o chefe vivo. Pivô em mundo deve permanecer exatamente no apoio real do chefe, y590na arena.

Uma preparação com regiões de célula, sem cortar cada silhueta pelo alpha:

* Linha superior: para coluna c=0..2, extrair Rect2i(32+c*512,133,480,450); resizeNEAREST para96 ×90; blit em(8,0) no canvas112 ×96.
* Linha inferior: extrair Rect2i(32+c*512,620,480,400); resizeNEAREST para96 ×80; blit em(8,23) no mesmo canvas112 ×96.
* O fator1/5é exato nos dois eixos para TODAS as poses. As células têm margens diferentes porque o gerador não cumpriu o posicionamento vertical nominal; a escala corporal não muda. Não fazer fit de cada bbox na mesma dimensão.
* Os contatos físicos ficam próximos de y88nativo: primeira linha88..88.8 e segunda88..88.2. Se necessário ajustar1texel vertical na pose2para contato exato, sem alterar escala. Micélio da pose5estende cerca2texels abaixo do apoio, como decoração rasteira incorporada à borda do chão.
* Limpar alpha no limiar0.5 e então aplicar paleta47atual. Existem RGBs coloridos sob alpha0que o preview de fonte pode mostrar como halo; amostras exteriores conferidas têm alpha0. Nenhuma aura deve ir para o runtime. A preparação precisa ignorar RGB transparente.

## Cadência sugerida e permanência

Exemplo para avaliação: impacto0.10s, pernascedem0.14s, ajoelhado0.18s, queda0.20s, corpo0.40s, restos persistentes. A integração pode ajustar os tempos à lógica da luta. As poses4/5devem ser vistas claramente; restos5não podem virar alpha0imediatamente. Partículas complementam a queda e não cobrem todas as poses. A transição para recompensa deve preservar a leitura de derrota física.

## Limites de avaliação

Inspeção fonte e medição de alpha, sem runtime editado pelo artista. Há seis posturas distintas e restos persistentes. A geração adicionou segmentação visível ao abdômen; cor, volume e identidade permanecem reconhecíveis, mas o revisor independente deve comparar à versão viva. A queda não é uma simulação física: o integrador deve conferir a trajetória visual entre poses2/3e o apoio no piso. Aprovação depende das capturas de engine e da sequência temporal, não apenas desta prancha.
