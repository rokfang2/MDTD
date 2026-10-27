# Corrida v4 — apoio0 e passagem3

## Entrega e contrato

`assets/run_native_v4.png`:384 × 120, quatro colunas e três linhas,12quadros em ordem. Células96 × 40, pivô fixo(48,36), direção direita, SCALE4 e Sprite2D centralizado em(0,-64). O integrador mantém a cadência que o usuário solicitou; este artista não alterou runtime, física ou duração do ciclo.

Fonte da edição: `assets/motion_run_raw_v4.png`, gerada pelo built-in image_gen a partir de `assets/motion_run_v3_final.png`. O prompt completo está em `art/motion_run_v4_prompt.txt`. Preparação reproduzível em `art/prepare_run_v4.py`. Fonte e atlas antigos em uso foram preservados; somente um novo atlas foi criado.

## Correções exatas

Quadro0: translação vertical exata de **+1pixel nativo**, mantendo todos os pixels e a escala. Antes, os limites opacos terminavam em y35exclusive e o pé ficava um pixel acima do apoio. Agora terminam em **y36**, igual ao contato6. A cabeça também desce1pixel, ficando em y10 igual ao contato6. Não foi feita alteração artística para satisfazer teste: o ajuste corrige contato físico e exige atualizar todas as regiões de inspeção0 em +1y.

Quadro3: nova pose de passagem, sem preservar a coxa distante incorreta. A perna próxima clara fica vertical, apoiada sob o quadril. A coxa distante escura avança à direita, com joelho levantado e canela dobrada; o pé escuro fica acima do chão. O braço claro está à frente e o escuro atrás, em oposição ao movimento das pernas. O sprite foi isolado da região de origem(0,330,360,255), com âncora(175,570) e redução uniforme1/8. Não houve interpolação ou desenho de anatomia por Python.

Todos os outros10quadros mantêm exatamente os pixels visíveis v3. O preparo também normaliza RGB sob alfa0 para(0,0,0,0), evitando pontos coloridos em viewers; isso não muda a silhueta opaca.

## Regiões medidas para validação

Regiões são(x,y,w,h), relativas à célula96 × 40. Contatos opostos continuam em0 e6. A perna próxima clara lidera à direita no0; a distante escura lidera à direita no6.

|Quadro|Parte|Região|Medida no raster fonte nativo|
|---|---|---|---|
|0|punho próximo|(40,26,7,4)|centro claro≈(43.2,26.9)|
|0|punho distante|(56,23,6,5)|centro verde≈(58,24)|
|0|pé esquerdo atrás|(34,31,10,5)|0pixels claros|
|0|pé direito líder|(52,32,8,4)|11pixels claros|
|6|punho próximo|(54,22,7,6)|centro claro≈(56.3,24)|
|6|punho distante|(43,24,6,5)|centro verde≈(45,26)|
|6|pé esquerdo atrás|(34,31,10,5)|16pixels claros|
|6|pé direito líder|(52,31,8,5)|0pixels claros|
|3|punho próximo|(55,21,7,6)|centro claro≈(57,23)|
|3|punho distante|(40,22,7,6)|centro verde≈(44,25)|
|3|joelho à frente|(51,25,7,6)|14pixels verdes;0claros|
|3|perna de apoio|(45,29,7,7)|23pixels claros|
|9|punho próximo|(41,23,7,6)|centro claro≈(44.5,24.8)|
|9|punho distante|(55,20,7,6)|centro verde≈(58,23)|
|9|joelho à frente|(48,25,7,6)|20pixels verdes;18claros|
|9|perna distante atrás|(36,29,8,6)|0pixels claros|

As contagens acima usam o RGBA nativo antes da paleta: claro significa G>=140,R>=70,B<80,alfa>127; verde significa G>30,G>1.1R,G>1.2B,alfa>127. São medidas auxiliares de inspeção, não uma regra universal de material: o punho distante ainda tem alguns pixels intermediários claros. Para os pés/joelhos, a separação é inequívoca. Um controle negativo que repete0..5 em6..11 falha porque o pé claro de0está à direita, enquanto6exige o claro à esquerda; não depende de hashes globais ou contagem de quadros.

O deslocamento horizontal entre punhos próximos0/6 é cerca de13pixels nativos/52pixels de jogo, com direção inversa aos pés líderes. O distante também troca de lado. Na passagem3, o joelho dianteiro é escuro; na9, claro, evitando as duas passagens com a mesma perna à frente.

## Inspeção e limites

Previews: `art/run_native_v4_preview.png`, `art/run_native_v4_preview.gif` e `art/run_v4_contacts_passings.png` (ordem0,6,3,9). `art/inspect_run_v4_rois.py` reproduz as medidas.

O artista inspecionou a nova passagem e os contatos no raster, e liberou o PNG para captura. Revisão da engine deve confirmar cadência reduzida pelo integrador, continuidade entre2→3→4 e8→9→10, apoio0/6, ausência de deslizamento, braços contralaterais e estabilidade do corpo. Não afirmar aprovação de fluidez a partir de12imagens ou contagens de cores. A passagem3 é nova; a9 e os demais quadros mantêm os desenhos v3, com suas diferenças de inclinação e voo. Idle4 e demais ações não foram alterados nesta correção.
