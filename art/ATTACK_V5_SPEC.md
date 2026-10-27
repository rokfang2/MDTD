# Ataque v5 — corte lateral horizontal

## Entrega liberada para engine

`assets/attack_native_v5.png`:288 × 80, três colunas e duas linhas, seis células96 × 40 em ordem0..5. Direção direita, pivô(48,36), SCALE4, Sprite2D centralizado em(0,-64). Todos os corpos têm28pixels de altura e pés terminando na linha36. Nenhum runtime, teste, backup ou outro atlas foi alterado pelo artista.

O revisor independente inspecionou a fonte e o preview nativo antes da liberação. Confirmou que as orientações0atrás/1perspectiva/2direita/3cruza à esquerda/4recolhe/5livre permanecem legíveis, sem salto grosseiro de proporção ao reutilizar o ativo v4. Isso libera integração e captura; o timing real ainda deve ser validado na engine.

## Fonte e preparação

`assets/attack_raw_v5.png` foi gerado pelo built-in image_gen usando `assets/attack_raw_v4_final.png` como referência de identidade/material. O prompt completo é `art/attack_v5_prompt.txt`.

`art/prepare_attack_v5.py` isola cinco novas anatomias, reduzidas pela mesma escala uniforme1/9.5 (retângulos de origem912 × 380 para96 × 40), com nearest e alfa128. Não ajusta cada corpo aos limites da espada. As âncoras de origem são:0(420,338),1(1070,340),3(420,668),4(1090,668),5(1740,668). Todo pixel transparente ficaRGBA0, eliminando resíduos RGB sob alfa0.

A fase2 é uma cópia INTEGRAL e EXATA da fase3 de `assets/attack_native_v4.png`, sem resize ou redesenho. A preparação verifica igualdade de todos os pixels. Isso preserva corpo, mão, madeira rígida fosca, ponto de dano e alcance160 já integrados. As demais cinco poses vêm da nova geração, sem copiar o corpo ativo e apenas mudar o comprimento da madeira.

## Gesto que corrige a estocada

0 antecipação: mão e lâmina atrás, apontando horizontalmente à ESQUERDA, torso preparado e cabeça olhando à direita.1 início da rotação: cotovelo e punho cruzam o peito, lâmina encurtada pela perspectiva, em formato de ponta/losango voltado ao observador.2 corte ativo: projeção plena à DIREITA, corpo e ombro carregam a espada.3 follow-through: antebraço atravessa o torso e termina à ESQUERDA do quadril, espada inteira apontada à esquerda diante do corpo; a capa gira para a direita.4 mão recolhe perto das costelas, madeira curta à esquerda.5 mãos vazias e postura pronta.

A sequência de projeções é ESQUERDA→PERSPECTIVA→DIREITA→ESQUERDA CRUZADA→ESQUERDA CURTA→NENHUMA. A transição2→3 não avança mais o punho axialmente: cruza o centro corporal, muda a orientação da lâmina e troca o lado da capa. Não existe crescente vertical ou rastro pintado. Material permanece madeira rígida larga e afilada, fosca cinza-marrom, sem metal, bronze, galhos, nós salientes, cipó ou chicote.

## Regiões, alcance e testes de gesto

|Fase|Região de madeira (x,y,w,h)|Observação|
|---|---|---|
|0|(13,15,20,10)|madeira atrás à esquerda,61pixels marrons na região|
|1|(43,18,11,8)|projeção curta diante do peito,36pixels marrons|
|2|(65,18,23,7)|EXATA peça/corpo v4fase3,81pixels marrons|
|3|(13,18,19,8)|região exclusiva da ponta esquerda,70pixels marrons; não contém capa|
|4|(24,18,14,8)|madeira curta esquerda,43pixels marrons|
|5|nenhuma|mãos livres|

A região3 acima é deliberadamente limitada a x13..31, muito à esquerda do torso. A madeira inteira do follow-through se estende aproximadamente de x13 até38, y19..24. A capa desse quadro fica à DIREITA, aproximadamente x52..64,y18..30. Portanto a contagem de madeira esquerda não pode passar por contar a capa creme. A antiga estocada v4fase3 não tem madeira nessa região esquerda e deve falhar uma regressão que exija pelo menos8pixels marrons ali.

As contagens foram medidas antes da quantização: alfa>127, R>=50,G>=35,B>=20,R>=G>=B e R-G<80. O script `art/inspect_attack_v5_rois.py` as reproduz. Preferir ROIs materiais e anatomia do torso a hashes de quadros completos para avaliar o gesto. Região corporal útil: torso/ombros x40..61,y17..29; a mão3 termina perto de x39, cruzando para o lado esquerdo da âncora48.

Ativo2: último pixel x87, borda externa88 =>(88-48)*4=160pixels de jogo; centro do último pixel156pixels. Madeira y18..24, centro≈21.5 =>cerca de-58pixels de jogo; o efeito horizontal centrado em-60 permanece alinhado. A recuperação3 possui madeira à esquerda, mas NÃO deve emitir dano ou trilha de ataque atrás do personagem.

## Timing acordado com integração

Root já remapeou0/1 para antecipação0..45ms,2 como única pose ativa45..145ms, e3/4/5 para recuperação145..230ms. Preservar230ms totais, sem acelerar ou alterar física/dano para mascarar o gesto. A fase3 cruza à esquerda somente após a janela ativa, sem dano/rastro atrás. Confirmar esta separação em captura real e nos dois lados.

## Evidência e limites

Previews: `art/attack_v5_preview.png` e `art/attack_v5_preview.gif`. O GIF usa tempos mais lentos para inspecionar poses e NÃO representa o timing final230ms. O preview nativo foi aprovado para integração pelo revisor; aprovação final depende da sequência da engine com tempos reais, troca2→3, ausência de dano/rastro na recuperação, alinhamento com hit e retorno ao idle sem arma.

## Aceite posterior em engine

O revisor independente concluiu `review/sword_v5/VISUAL_REVIEW.md` em2026-10-25 e aceitou o resultado para o pacote no escopo examinado. O P2 de estocada v4 foi encerrado: sequências reais410..423 à direita e432..445 à esquerda mostram preparação atrás, perspectiva, fase2 ativa à frente, fase3 cruzando torso com capa oposta, recolhimento e mãos livres. Não observou salto grosseiro entre o ativo reaproveitado e as novas poses, chicote/bronze, ponta cortada, membro extra ou trilha durante recuperação. A preferência final de sensação continua dependendo do jogador; esta nota registra revisão separada da engine, não um playtest humano ou simulação3D contínua.
