# Revisão do jogo

## Referência

Veja a **coluna esquerda A — PIXEL SIMPLES de art/style_a_reference.png** antes de avaliar as capturas. Escolha explícita mais recente do usuário, substituindo a direção da revisão6. A coluna B e art/style_reference.png são referências históricas. Cenário com blocos grandes, sombras roxas, verdes vivos, ciano e magenta. Atores em baixa resolução ampliados4x por nearest, sombras limitadas e contornos escuros. Conferir também a repetição do solo, a espada rígida de madeira e o lançador com fungos magenta. O pedido atual exige espadada horizontal com giro e follow-through; não restaurar crescente vertical, cipó que telescopa ou estocada como substituto do corte.

## Revisão de código e mecânicas

- Verificar direção fixa do dash durante a execução, fim da invulnerabilidade, recarga e colisão com paredes.
- Verificar que dano interrompe golpes pendentes e mantém o recuo por um período perceptível.
- Comparar saltos curtos e longos; testar comando antecipado de pulo ao aterrissar e tolerância após sair da borda.
- Verificar aceleração, parada e controle no ar por input, não apenas valores de constantes.
- Confirmar que alcance visual do golpe corresponde ao dano. Um golpe não deve atingir atrás do jogador.
- Exercitar os padrões naturais do chefe com seus avisos, não apenas chamar funções de ataque isoladas.
- Separar testes que precisam invulnerabilidade artificial dos que exercitam dano real.
- Pausa, morte, reinício e mudança de arena precisam interromper corretamente os comandos pendentes.

## Revisão visual

Renderizar menu, trilha, checkpoint, arena, ataque, dash, pausa e recompensa quando afetados. Inspecionar as imagens.

- A borda em que os pés encostam deve ser a mesma que bloqueia o corpo. Uma nova ilustração de cenário não garante preservar a geometria anterior.
- Conferir sprites legíveis, joelho apoiado/outro erguido e mãos na espada durante oração. Comparar espessura de contorno e tamanho aparente dos pixels entre protagonista, chefe, inimigos, chão e partículas.
- O cenário não pode esconder os ataques nem sugerir plataformas sólidas onde não há colisão.
- Texturas devem usar amostragem nearest. Desenhos por código devem usar grade e evitar brilho ou contornos lisos que destoem da referência.
- Animação de corrida deve acompanhar a distância percorrida; ao parar não pode continuar deslizando visualmente.
- Avaliar movimento com quadros em instantes distintos. Registrar poses reaproveitadas como limitação.
- Texto precisa ter contraste e caber em janela lógica 1280 × 720. A interface pode usar tipografia legível sem imitar pixels a qualquer custo.

## Execução

Execute `python tools/check_project.py --godot "C:\caminho\Godot_console.exe"`. O runner importa e testa uma cópia temporária com namespace de progresso isolado, registra logs e recusa erros da engine ou verificações com falha. Capturas de mudanças visuais precisam de renderer real e inspeção separada; a saída automática não certifica qualidade visual.

Nunca execute os testes de progresso no checkout pessoal. Use o runner isolado, que confirma o namespace antes das suítes de save. Capturas devem usar namespace auxiliar e persist_progress=false.

## Registro

Atualize LATEST_REVIEW.md com achado, alteração, evidência, resultado e limitação restante. Diferencie inspeção do código, input simulado, imagem renderizada e teste humano. Não declarar aprovação independente quando a mesma instância fez a implementação e a autorrevisão.


## Menu original preservado

Scenes/main_menu.tscn, Fonts e Textures são a referência explícita para o menu. Conservar a composição original e verificar rolagem20px/s, cobertura, repetição, painéis, Continue e descarte do CanvasLayer antes de gameplay/ajuda. A escolha A continua para gameplay; não substituir a imagem original do menu.
