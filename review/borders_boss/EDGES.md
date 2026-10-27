# Bordas — revisão16

## Diagnóstico

As capturas da revisão15 mostram recortes sobretudo no solo: o polígono terminava em paredes verticais sem contorno, atravessando raízes grandes da textura. A tira de musgo encerrava em qualquer fase do UV nessas paredes. Nos degraus, isso expunha uma lateral reta de material. As plataformas suspensas já preservavam as pontas, mas a linha verde adicional era desenhada uma fileira nativa acima da maior parte do musgo, prolongando uma régua sobre os caps arredondados.

## Integração — tentativa1

- `soil_layer.gd`: perfil de falésia em degraus de4px, com recuo de4–12px dentro da área sólida abaixo do canto e contorno escuro. O interior mantém a mesma textura e UV global da revisão15; não há retângulo novo, pintura de bitmap ou alteração de colisão. Degraus entre pisos recebem o mesmo acabamento.
- `terrain.gd`: a tira superficial continua inteira na altura. Seus extremos recebem os caps reais da plataforma curta do mesmo atlas, substituindo o corte aleatório de UV. A linha funcional coincide com a primeira fileira sólida de musgo; tufos ficam4px acima como decoração e o destaque não ultrapassa os extremos arredondados.
- Os caps usam15texels nativos por lado, com limites internos0..15/35..50 da variante50px. A inspeção do alpha confirmou que esses limites passam entre as raízes pendentes; um recorte de8texels teria dividido a primeira raiz e foi descartado antes do aceite.
- Mantidos fontes antigas, florestaV5, geometria13032, todos os colliders, câmera, herói, chefe, moveset e saves.

## Verificação e limites

Godot4.7.2: importação e teste `art_presentation.gd`3/3 passaram. Uma primeira construção do polígono produziu triangulação inválida; foi corrigida removendo duplicatas e preservando trechos verticais antes/depois dos recuos. A nova execução não emitiu esse erro.

O coordenador produziu15capturas reais em `review/borders_boss/captures`, com importação/renderização sem erro. O integrador inspecionou01_old_new_connection,13_final_gap,02_gallery_descent e12_vestibule_crossroads: a linha superior encosta no musgo, caps preservam motivos completos, paredes/degraus têm perfil irregular contornado e o corpo mantém continuidade de UV. Esta é autorrevisão, não aceite independente.

Limitação enviada explicitamente ao revisor: as raízes interiores ainda podem encontrar a falésia, agora com recuo e contorno; não existem terminações autorais específicas para cada parede. É necessário julgar se o acabamento elimina a aparência de bitmap recortado, principalmente no bloco central de13. O teste automático confirma carregamento e preservação da textura das plataformas; não aprova as bordas nem prova que as junções dos caps estão invisíveis. Aguarda-se o parecer independente sobre as novas capturas.
