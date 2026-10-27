# Ações v3 — contrato do artista

Built-in image_gen usado em três edições distintas de referências locais vistas antes de gerar. Fontes completas preservadas como assets/attack_raw_v3.png, actions_raw_v3.png e prayer_raw_v3.png. Nenhum backup foi alterado. Preparação reproduzível: art/prepare_actions_v3.py; apenas isolamento raster, nearest uniforme, threshold de alfa128 e composição de partes geradas. Nenhuma anatomia ou madeira desenhada por código.

Todos os quadros nativos medem96×40, olham à direita e usam pivô48,36/SCALE4. Não recentralizar pelos limites opacos. Pixel0..35 vertical, pé de apoio termina na linha35. Altura em pé27px; agachamento/dash têm altura menor desenhada de propósito. Identidade A: capuz de folhas, olho ciano, capa creme e membros verdes claro próximo/escuro distante.

## Attack

assets/attack_native_v3.png:288×80,3colunas×2linhas, ordem row-major.0windup com broto;1crescimento curto;2crescimento quase completo;3extensão completa;4retração;5recuperação mãos vazias. Corpo dos seis quadros preserva as poses aprovadas v2; fases1..4 usam a anatomia ativa e mudanças reais na extensão de casca. Não alegar seis anatomias redesenhadas. O broto e a extensão são partes da geração nova.

Extensão por fase:0broto na mão elevada,1fragmento9px,2fragmento26px,3fragmento29px,4fragmento14px,5zero. A raiz é revelada/retraída horizontalmente desde x60,y22. Corpo e mão aprovados chegam a x59. Quadro3 tem último pixel opaco x87: ponta156px e borda externa160px à direita do pivô; mão→borda externa aproximadamente116px. A caixa local de inspeção exclusiva da madeira ativa é(60,22,29,6). O último pixel da porção gerada pode ser transparente: a extensão nominal29 não significa29colunas opacas.

Timing de integração sugerido pelo integrador preserva230ms:0/1durante0..45ms,2/3ativos45..145ms,4/5recuperação145..230ms. A fase2 já oferece alcance quase completo no primeiro tick de dano. Evento de dano continua sendo responsabilidade da integração.

Casca gerada: marrom acinzentado escuro fosco, fibras/veios em clusters retangulares, pequenos nós e bifurcações finas. Sem guarda, cabo, lâmina, metal, brilho ou linha dourada. Preservar a cor da casca ou usar paleta neutra própria; a quantização global quente poderia reintroduzir bronze.

## Actions

assets/actions_native_v3.png:384×160,4×4.0dash start,1dash hold,2dash end;3jump takeoff/tuck,4rise,5apex;6fall start,7fall fast;8land impact,9rebound,10settle;11hurt flinch,12recover;13crouch lower,14hold;15ready recovery. Cada pose é um desenho novo na geração, sem arma. Escala uniforme1/6; âncoras anatômicas explícitas no script. Nenhum quadro foi esticado ou redimensionado individualmente para igualar sua altura.

O dash hold mantém pés acima da linha de contato(última linha32), coerente com impulso baixo. Jump3..5mantém posições dos pés elevadas sem forçar a sola à linha35; rever passagem da física nas capturas reais. Land8é comprimido,9sobe e10assenta. Hurt11inclina o torso para trás e12volta. Crouch14mais baixo que13.

## Prayer

assets/prayer_native_v3.png:384×40,4quadros numa linha. Quadro0 é a pose aprovada v2, preservada exatamente fora do retângulo de casca(56,25,3,10). Quadros1..3usam fragmentos da nova geração de respiração em regiões exclusivas do alto do capuz(42,11,16,7)e cauda da capa(34,21,14,11). A redução uniforme1/17 mantém diferenças pequenas de folhas/capa. Mãos, rosto, raiz plantada e toda faixa y>=32permanecem iguais em todos os quadros. A perna/joelho elevado x>=48também permanece igual. Não afirmar que o torso inteiro respira: a composição preserva o torso e mostra respiração suave na silhueta de capuz/capa. Loop sugerido350ms por quadro(1.4s completo). Fonte adicional preservada assets/prayer_loop_raw_v3.png e prompt art/prayer_loop_v3_prompt.txt. Pose material estática auxiliar art/prayer_material_native_v3.png.

Previews4×em art/attack_v3_preview.png, actions_v3_preview.png e prayer_v3_preview.png; GIFs de leitura disponíveis. Esta inspeção de raster não substitui revisão na engine ou aprovação humana de movimento.
