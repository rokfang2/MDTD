# Movimento v3 — corrida e repouso

Corrida: assets/motion_run_native_v3.png,384×120,4×3 células96×40. Pivô comum48,36, ampliação nearest4×. Fonte assets/motion_run_v3_final.png; seleção e alinhamento reproduzíveis em prepare_motion_run_v3.py. Doze desenhos selecionados da geração corrigida, sem interpolação digital de anatomia.

Os apoios opostos são0/6. Na fase0 a perna clara próxima está à frente e a mão clara atrás; na6 a perna escura distante está à frente e a mão clara avança. As pernas deixam de repetir sempre o mesmo membro à frente. As fases seguintes incluem retorno e passagem até reiniciar o ciclo. Capa e folhas acompanham a silhueta. Não há arma carregada.

O runtime avança pela distância realmente percorrida:112pixels por ciclo completo, divididos por12quadros. Portanto a cadência do corpo acompanha a velocidade; ampliar a contagem não torna o deslocamento mais lento. Ao parar, o ciclo não continua andando.

Repouso: assets/idle_native_v3.png,384×40,4células,220ms por quadro. Fonte idle_v3.png. Pivô e escala comuns aos demais movimentos; o repouso movimenta folhas/capa e postura.

Verificar o resultado real em review/full_motion_v3/movement_60fps.mp4, contatos e fases em run_contacts_engine.png e coverage em pose_coverage.json. Hashes distintos não demonstram a anatomia: tests/arm_swing.gd mede também a inversão das pernas e punhos nos apoios0/6.
