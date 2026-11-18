# Revisão visual independente — menu original integrado

Resultado: **aprovado para esta integração**, sem defeito visual bloqueante identificado nas 11 capturas reais examinadas.

Referência: `origin/main:Scenes/main_menu.tscn`, script original e `Textures/MainMenu_BG_Seamless.png`, lidos antes da revisão. A restauração do menu original é uma exceção explicitamente autorizada pelo usuário à direção A do gameplay; não se propõe redesenho do menu.

- **01/02:** floresta verde/roxa original, título GREEN NATURE marrom/verde, botões MedievalSharp, coluna esquerda e painéis translúcidos reconhecíveis. A comparação de dois instantes mostra fundo deslocado enquanto título e comandos permanecem ancorados. Não há faixa vazia, estiramento abrupto ou corte de cobertura visível em 1280×720.
- **03/09:** Continue entra na mesma coluna, com espaçamento e foco legíveis; retorno ao menu recompõe a composição sem HUD do gameplay sobreposto.
- **04/05:** Settings e Credits mantêm o fundo original e o painel direito escurecido. Títulos, slider, linhas de texto e botão X ficam dentro da janela, sem sobreposição entre linhas ou recorte. O título ornamentado escuro tem contraste discreto, como no original; isso não foi convertido em exigência de redesign.
- **06/07/08/10:** ajuda e pausa usam os painéis atuais legíveis; ao entrar no jogo, a floresta e os botões do menu original desaparecem. Gameplay continua com cenário A e HUD atuais. O quadro Continue mostra o personagem na região Galerias de Seiva, sem resíduos do menu. A posição numérica 8470 e a correção do save dependem da verificação funcional separada, não da imagem sozinha.
- **11:** em 960×540, fundo cobre todo o viewport e título, quatro comandos e ações inferiores permanecem dentro da composição. Não há corte de texto nem painel vazando para fora da janela.

Limites: revisão de PNGs renderizados, independente da implementação, sem interação com o jogo pessoal. Dois instantes confirmam deslocamento, mas não certificam suavidade temporal nem a emenda após um ciclo inteiro do parallax. O resize amostrado mantém proporção16:9; outras proporções, ultrawide e configurações de acessibilidade não foram verificadas visualmente. Funcionamento de clique, áudio, fullscreen, persistência e navegação por teclado pertence à suíte funcional separada; contagens de testes não fundamentam esta aprovação estética. Nenhum script, fonte ou asset foi alterado nesta revisão.
