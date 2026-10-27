# Cadência da corrida v4

O ciclo de corrida conserva12 poses na mesma ordem, agora em `run_native_v4.png`, e completa184 pixels de deslocamento real em vez de112. A versão v4 também corrige o apoio0 e o joelho na passagem3, conforme RUN_V4_SPEC.md. Cada fase cobre aproximadamente15,33 pixels. A velocidade física continua310 pixels/s: são aproximadamente1,685 ciclos/s,20,22 trocas de pose/s e3,37 ciclos ao percorrer620 pixels em2 segundos. A versão anterior completava aproximadamente5,54 ciclos no mesmo intervalo.

Não há alterações em aceleração, frenagem, colisão, dash, salto, ataque, dano ou cooldown. A distância da animação continua derivada do deslocamento efetivo; a passada interrompe ao soltar direção e contra parede.

`tests/run_cadence.gd` usa input simulado no Godot em cena mínima com chão e parede, sem Main nem progresso. Mede velocidade, deslocamento, distância da animação, ciclos e trocas reais de textura durante120 ticks a60Hz; também exercita parada e colisão com parede. Execução destinada ao snapshot `output/mushrooms/sword_v4_sandbox`, com `custom_user_dir_name=MushroomsSwordV4QA`.

Esta nota descreve a alteração e a verificação automatizada. A cadência visual ainda depende de nova captura e revisão; não constitui aprovação visual ou teste humano.
