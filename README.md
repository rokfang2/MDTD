# Mushrooms Deserve to Die (MDTD)

Projeto editável de um jogo de ação e exploração 2D, desenvolvido em **Godot 4.7.2**, com GDScript e renderização Compatibility.

A versão atual contém uma fase de 13.032 pixels com seis setores, rotas altas/baixas, quatro lótus de checkpoint, oito memórias e o primeiro chefe, Cordyceps. A derrota do chefe tem seis poses de colapso e restos persistentes. O estilo visual escolhido é A — Pixel Simples.

## Abrir e jogar

1. Instale o Godot 4.7.2 e importe o arquivo `project.godot` deste repositório.
2. Aguarde a importação automática dos recursos e pressione **F5**.
3. No menu, escolha **Nascer do lótus** ou **Continuar**, se houver progresso local.

No Windows, também é possível usar `Jogar.cmd`. O launcher procura Godot.exe na pasta do projeto ou a instalação 4.7.2 em Downloads. Para outra instalação, use `powershell -File .\Launch_Game.ps1 -GodotPath "C:\caminho\Godot.exe"`.

O repositório contém os recursos usados pelo projeto; a pasta `.godot/` é recriada pela engine. Não inclui executável exportado, saves pessoais, backups nem capturas/logs de desenvolvimento.

## Controles

| Tecla | Ação |
|---|---|
| A/D ou setas | Mover |
| Espaço/W/seta para cima | Pular; soltar reduz a altura |
| Shift/K | Dash |
| J/X/clique esquerdo | Golpe horizontal de madeira |
| S/seta para baixo | Agachar parado |
| S+Espaço | Descer de uma plataforma suspensa |
| E | Interagir; ajoelhar e orar para salvar no lótus |
| Tab | Mapa |
| Esc | Pausa |
| M | Áudio |
| F | Calêndula, após obtê-la |

A oração acontece na posição do personagem; dano a interrompe. Memórias entram no save na próxima oração. A recompensa do chefe também exige oração. **Nascer do lótus** começa uma nova jornada; uma gravação posterior substitui o progresso local anterior.

## Organização

- `scripts/`: lógica do jogo, combate, terreno e preparação dos sprites.
- `scenes/main.tscn`: cena inicial; mundo e interface são construídos em execução.
- `assets/`: imagens/áudios atualmente necessários e suas configurações de importação.
- `tests/`: testes de comportamento na engine.
- `tools/check_project.py`: revisão automatizada em cópia isolada.
- `art/`: referência A, especificações e prompts de arte; tentativas brutas ficam fora deste repositório.
- `review/`: critérios e resumos de revisão. Evidências pesadas permanecem no ambiente de desenvolvimento.

## Testes

Requer Python 3 e Godot 4.7.2, sem pacotes Python extras:

```powershell
python tools/check_project.py --godot "C:\caminho\Godot_v4.7.2-stable_win64_console.exe"
```

Ou defina `GODOT_BIN`/tenha `godot` no PATH. O runner copia o projeto para uma pasta QA temporária, confirma o namespace antes das suítes de save, importa os recursos e executa 20 suítes. Ele não usa o save pessoal. Os logs e o resumo ficam na pasta QA impressa no terminal.

Na revisão16 foram aprovadas **476 verificações**, além de revisão visual independente por capturas. Testes automatizados não substituem playtest humano de conforto, equilíbrio e dificuldade. Há um dos cinco confrontos previstos no GDD; os demais chefes e finais ainda não estão implementados.

## Histórico desta atualização

Esta atualização substitui o protótipo inicial do menu pela versão jogável atual. Os commits anteriores continuam no histórico Git. Arquivos de cache, arte descartada, backups e ZIPs não fazem parte da atualização.
