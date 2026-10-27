# Movimento de madeira v2

## Contrato de integração

`assets/motion_wood_native_v2.png` mede **384 × 160**, com quatro colunas e quatro linhas de células **96 × 40**. Todas as poses olham à direita e têm âncora fixa **(48,36)**. Manter SCALE4 e Sprite2D centralizado em **(0,-64)**. O corpo recebe apenas mais16pixels de margem de cada lado comparado ao atlas v1; não muda de escala.

`assets/prayer_wood_native_v2.png` é uma célula96 × 40 com a mesma âncora. A oração já está orientada à direita e contém exatamente os pixels v1, deslocados16pixels. O personagem ajoelhado continua com25 × 25pixels.

A ordem continua igual: índices0–7 corrida;8 preparação;9 ataque ativo;10 recuperação;11 dash;12 subida;13 queda;14 aterrissagem/agachar;15 idle. Não centralizar pelos limites opacos nem ajustar cada pose ao seu tamanho individual.

## Fontes, prompts e preparação

O script `art/prepare_motion_wood_v2.py` reproduz os arquivos nativos e os previews por isolamento, recorte, composição e amostragem nearest uniforme. Ele não desenha braços, lâmina ou novas poses por código.

`assets/motion_wood_run_v2.png` é a edição via image_gen da fonte v1 em1402 × 1122. O prompt completo está em `art/motion_wood_run_v2_prompt.txt`. A edição pediu novos braços nas primeiras oito poses, preservando as pernas, cabeça, capa e proporções. A preparação mantém as âncoras de origem e a redução uniforme1/8. Para limitar pequenas variações de borda da geração, a composição final mantém os pixels v1 acima de y18 e a partir de y29; apenas a faixa y18..28 usa os braços e o torso editados. A oclusão da capa pelo braço nessa faixa faz parte do desenho gerado.

O ataque usa a fonte selecionada `assets/attack_wood_wide_v2c.png`, em1941 × 810. A referência `art/attack_wood_wide_v2_reference.png` isolou a pose ativa aprovada. As três edições locais da madeira estão preservadas como `attack_wood_wide_v2.png`, `v2b.png` e `v2c.png`; os prompts completos correspondentes estão em `art/attack_wood_wide_v2*_prompt.txt`. A primeira versão exagerou o alcance, a segunda encurtou, e a terceira chegou ao comprimento escolhido.

A anatomia dos ataques gerados foi descartada. O corpo ativo final mantém exatamente os pixels v1 até x59 inclusive. Apenas a madeira do retângulo de origem **(936,480,480,96)** da versão c é reduzida uniformemente1/16 para **30 × 6**, e composta em **(60,22)**, junto ao punho aprovado. A lâmina curta anterior é apagada de x60 em diante. Trata-se de madeira efetivamente desenhada pelo image_gen, sem alongar braço ou corpo.

## Alcance medido da madeira

A âncora ativa está em x48. O último pixel visível está em **x87**, portanto o alcance máximo desenhado é **156pixels de jogo** em SCALE4, quatro pixels aquém do alvo160. O centro da palma está aproximadamente em x59,44pixels à frente da âncora. Da mão à ponta são cerca de **28pixels nativos, ou112pixels de jogo**. A madeira começa em x60, conectada diretamente ao punho.

O ataque ativo ocupa o retângulo opaco **(32,14,56,22)**, incluindo corpo e ponta. A madeira ocupa aproximadamente x60..87, y22..27. É horizontal, marrom/dourada com base verde e contorno em degraus, sem cabo, metal ou arco. Preparação e recuperação mantêm os brotos curtos da versão anterior. Não comparar a largura total do ataque com a largura corporal para avaliar proporção.

## Medidas dos punhos para revisão

As coordenadas abaixo são relativas à célula96 × 40. Os centros são aproximações anatômicas dos desenhos; as regiões incluem punho verde e contorno local. Elas permitem avaliar os braços independentemente das pernas.

|Fase|Centro do punho próximo|Centro do punho distante|Região próxima (x,y,w,h)|Região distante (x,y,w,h)|
|---|---|---|---|---|
|0|(42,27)|(58,24)|(40,25,5,4)|(56,23,5,4)|
|2|(56,23)|(43,25)|(54,21,5,4)|(41,23,5,5)|
|4|(57,24)|(39,27)|(55,22,5,5)|(37,25,6,4)|
|6|(44,26)|(57.5,23.5)|(43,24,5,4)|(55,21,6,5)|

Na fase0, a perna próxima clara avança enquanto o braço próximo recua atrás do quadril. A perna distante escura recua enquanto o braço distante avança. Na fase4 ocorre o contrário: braço próximo à frente e distante atrás. O punho próximo percorre cerca de **15pixels nativos/60pixels de jogo** entre0 e4; o distante percorre19pixels nativos/76pixels de jogo, no sentido oposto. Nas passagens2/6 também mudam ambos os braços: aproximadamente12pixels para o próximo e14.5 para o distante.

Os cotovelos estão dobrados e os punhos alternam entre peito e quadril traseiro. Os destaques próximos costumam ter R140..185, G200..230 e B<15; os tons distantes são mais escuros, com G90..190. O runtime pode simplificar pela paleta existente. Verificar regiões dos braços, agrupamentos verdes ou diferenças da faixa y18..28; hashes de quadros inteiros poderiam passar apenas pelo movimento das pernas.

## Pixels preservados e limites

Todos os estados fora da corrida, exceto a madeira ativa, e a oração mantêm exatamente os pixels v1 com a margem adicional. A anatomia ativa até x59 mantém exatamente o corpo e o braço aprovados. Em cada quadro de corrida, as faixas y<18 e y>=29 mantêm os pixels v1. As oito poses de pernas continuam legíveis. A faixa intermediária pode conter pequenas variações de borda no torso, parte superior das coxas e capa, além da alteração intencional dos braços; não afirmar que toda a capa ou todas as pernas são idênticas bit a bit.

A inspeção dos previews confirmou braços contrários, madeira maior, ausência de armas fora do ataque/oração e membros verdes. Isso não substitui a revisão na engine: conferir continuidade, fases0/4 e2/6, contato dos pés, ligação ombro→mão, ausência de braços extras, espelhamento pela âncora fixa e crescimento/retração horizontal da madeira.

Previews: `art/motion_wood_native_v2_preview.png`, `art/motion_wood_run_v2_preview.gif`, `art/motion_wood_v2_arms_0_4.png` e `art/attack_wood_native_v2_preview.png`.
