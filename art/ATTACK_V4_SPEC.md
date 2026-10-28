# Ataque v4 — lâmina rígida de madeira

## Arquivos e integração

`assets/attack_native_v4.png`:288 × 80, três colunas e duas linhas de células96 × 40, ordem0..5. Todas olham à direita. Pivô fixo(48,36), SCALE4, Sprite2D centralizado em(0,-64). Altura corporal28pixels, sem redimensionar cada pose. Manter física, dano e duração230ms existentes; a integração escolhe os instantes das seis poses.

`assets/attack_raw_v4.png`, `attack_raw_v4_corrected.png` e `attack_raw_v4_final.png` preservam as três saídas built-in image_gen. Prompts completos em `art/attack_v4_prompt.txt`, `attack_v4_reach_prompt.txt` e `attack_v4_active2_reach_prompt.txt`. Referência de identidade: `assets/attack_raw_v3.png`, inspecionada antes da geração. A geração desenhou seis anatomias; não são cópias do corpo9 com diferentes comprimentos de raiz.

`art/prepare_attack_v4.py` isola os sprites e reduz cada fonte pela mesma escala1/9, com nearest e alfa128. Âncoras de origem: [(325,339),(1048,339),(1728,339),(270,674),(1040,674),(1736,674)]. Elas seguem quadril e apoio dos pés, independentemente da largura da espada. Não há desenho vetorial, deformação ou alongamento do corpo.

## Gesto e material

0 antecipação: mão atacante puxada atrás do quadril, joelhos firmes e broto curto.1 formação: cotovelo cruza o torso com mão mais perto do peito; a lâmina já está formada antes do corte.2 corte inicial: ombro e antebraço avançam, madeira alta no peito.3 follow-through: torso e ombro carregam o corte com braço mais adiante e madeira um pixel mais baixa.4 retorno: cotovelo recolhe, torso assenta e madeira desaparece.5 recuperação: mãos vazias, corpo volta à postura pronta.

A madeira é uma lâmina sólida larga e reta, com dois lados contínuos e ponta completa. Perfil fosco cinza-marrom, veios em faixas simples, sem brilho bronze, galhos, cipó, nós salientes, curva, cabo ou guarda. A lâmina brota da mão e some no fim. Nenhum arco ou rastro foi pintado no raster.

## Mesma lâmina durante o corte

As edições de alcance não produziram exatamente a mesma arma nas fases2/3. Para garantir rigidez, a preparação usa a MESMA peça desenhada da fase3 em ambas. O retângulo nativo(65,18,23,7) da fase3 contém a lâmina completa, com transparência; é copiado sem escala para(62,17) na fase2. A espada curta rejeitada dessa fase é limpa a partir de x62. Nenhum corpo é copiado entre poses: as anatomias2 e3 continuam as respectivas poses geradas, com ombro, mão, capa e pernas diferentes.

Isso traduz a arma como objeto rígido, sem revelar comprimentos9/26/29 ou encurtar a ponta durante o corte. A diferença de alcance vem da mão e ombro, não de telescopar a arma.

## Medidas e regiões de inspeção

|Fase|Região exclusiva da madeira (x,y,w,h)|Último x visível|Borda externa à frente do pivô|
|---|---|---|---|
|0|broto atrás, aproximadamente(32,17,4,5)|não é fase ativa|não aplicar|
|1|(44,17,30,8), formada em perspectiva|73|104pixels|
|2|(62,17,23,7), mesma peça rígida da3|84|148pixels|
|3|(65,18,23,7), lâmina fonte|87|160pixels|
|4|(64,18,14,7), retração após corte|77|120pixels|
|5|nenhuma|mão/corpo apenas|não aplicar|

A fase2 termina no pixel84/borda85: (85-48)*4=148pixels. A fase3 termina no pixel87/borda88:160pixels; o centro do último pixel fica a156pixels. A fase2 não deve ser anunciada como160. O braço da fase2 está3pixels mais atrás, portanto a mesma lâmina chega12pixels menos longe. Ambas as pontas estão completas e dentro do limite160.

Faixa vertical da madeira2: y17..23, centro aproximado20.5 => centro de jogo cerca de-62. Madeira3: y18..24, centro21.5 => cerca de-58. Sugestão para trilha horizontal: acompanhar esses centros, sem arco vertical. A banda anterior centrada em-40 fica abaixo destas lâminas. O integrador pode ajustar só o efeito visual conforme essas medidas, mantendo física/dano.

Regiões corporais para comparar anatomia sem contar a lâmina: torso/ombro(43,17,19,12), antebraço/mão(53,18,12,8), pernas/apoio(34,28,29,8). Não usar hash de quadro completo para afirmar seis gestos. Nas fases2/3, a peça da espada deve ser idêntica após compensar a translação(-3,-1), enquanto o corpo deve continuar diferente. Há alteração real de poses em0/1/4/5 e um follow-through menor entre2/3.

## Evidência e limites

Previews `art/attack_v4_preview.png` e `art/attack_v4_preview.gif` foram inspecionados como raster. O artista libera a arte para captura na engine; isso não é aprovação da sensação do golpe. O revisor deve conferir ombro→antebraço→mão, leitura de corte lateral e da madeira rígida, alinhamento da trilha, alcance nos dois lados e retorno a mãos livres. A continuidade e os tempos dependem da integração e da revisão real. Nenhum script de runtime, teste, revisão, backup ou Godot do usuário foi modificado por este artista.

## Correção de RGB sob transparência

A revisão encontrou pontos ciano/vermelho/amarelo no preview. A inspeção mostrou que já tinham alfa0, mas preservavam RGB saturado da fonte: por exemplo fase2(69,17)=(0,255,255,0) e(81,22)=(255,0,0,0). Não eram pixels opacos ou componentes da anatomia. O preparo agora normaliza TODO pixel transparente para(0,0,0,0), evitando exibição incorreta/contaminação RGB. O raster visível, arma e alcance não mudaram. Cada fase opaca tem um único componente conectado; não foi necessário apagar partes da silhueta.
