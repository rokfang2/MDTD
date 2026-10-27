# Revisão16 — bordas, combate e derrota do Cordyceps

Entrega concluída em2026-10-27; implementação/capturas iniciadas em2026-10-26. Godot4.7.2.

## Resultado

Bordas antes encerravam UV do solo em laterais retas sem contorno; musgo terminava em fase aleatória e a linha superior se separava das pontas. terrain/soil agora usam perfil de falésia interno4–12px em grade4px, contorno escuro e caps reais15nativos que preservam raízes inteiras. Topos/colliders/Level13032/câmera intactos. FlorestaV5 e arte anterior preservadas. Limite: raízes interiores encontram a borda acabada; não foram pintadas terminações únicas para cada falésia.

Luta conserva quatro padrões, com avisos próprios(raízes/esporos/pulso/mandíbulas), alvo anunciado travado, fan simétrico saindo do lado correto, pulso evitável por salto/dash e janela de fase0.9s que cancela ameaças anteriores. Recovery fica exposto no local em vez de deslizar até990. Não aumenteiHP como substituto de melhorar o combate.

Morte separa segurança imediata de recompensa: death_started limpa projéteis/perigos e status; chefe deixa de atacar, seis poses físicas mostram o colapso por2.6s e defeated libera a recompensa depois. Restos permanecem visíveis e ancorados. Lótus/fragmento aparecem ao lado260px com fallback de parede, preservando corpo visível. Oração da recompensa mantém posição atual/orientação e só então salva.

Artista separado criou cordyceps_death_sheet_v1.png via imagegen integrado; recortes/escala uniforme/canvas112x96/pivô56,88 e prompts em art/boss_death_v1/. Integração em pixel_art/boss/world; novos rasters anteriores não foram sobrescritos. Texturas vivas anteriores permanecem idênticas.

## Evidência e revisão

Novo teste boss_encounter primeiro falhou no runtime anterior(9/21); implementação passou28/28 e recebeu mais um assert para recompensa ao lado do corpo:29/29. verify ganhou espera da derrota assíncrona e usa reward_position. Testador separado:427/427 em18suítes +27/27geometria +22/22counterplay =476/476. Raízes por movimento, pulso por salto+movimento, mandíbulas/esporosfaseII ambos lados por dash com input real, sem invulnerabilidade artificial ao fim; vulnerável junto ao colapso sem dano, oração ambos lados no local e cadáver persistente.

Triangulação usa cópia em memória do código real, sem mudar runtime: cinco chains da trilha+arena, arestas ortogonais não nulas,UV global, área dos triângulos exatamente igual e recuo<=12. Guardas de namespace antes de save; fonte/snapshot sem mudanças ou divergências.43texturas anteriores(41herói+2guardião) mantêm SHA/dimensões/pivôs da revisão15. Importação inicial da cópia encerrou0xC0000005 sem erro de script; repetição0, causa nativa não estabelecida, amboslogs preservados. Todas suítes/helpers subsequentes0. Launcher incremental aprovado.

Revisor separado inspecionou15cenas de terreno por amostras críticas e21quadros do chefe, mais2suplementos de esporos em voo. Bordas, seis poses, apoio, restos, recompensa posterior e emissão frontal espelhada aceitos semP1/P2 visual confirmado. Logs de captura/importação0; sequência CSV comstate/death_elapsed/reward. Parecer em borders_boss/VISUAL_REVIEW.md. Dispersão completa dos esporos e fluidez contínua ainda dependem de playtest humano, não comprovados por fotos espaçadas.

No checkout real, Launch_Game.ps1 -PrepareOnly retornou IMPORT_READY e resource_visibility.gd56/56exit0. Progresso pessoal não sobrescrito. Backup aprovado e pacotes anteriores preservados. Jogo aberto via launcher após conferir ausência de instância pessoal. Histórico revisão15 em REVIEW_V15_ART_COHESION.md.
